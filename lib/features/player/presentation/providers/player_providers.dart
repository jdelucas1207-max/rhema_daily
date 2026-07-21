import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../../../services/audio/rhema_audio_handler.dart';
import '../../domain/entities/verse.dart';
import '../../domain/usecases/get_all_verses.dart';
import '../state/player_state.dart';

final playerStateNotifierProvider =
    StateNotifierProvider<PlayerStateNotifier, PlayerState>(
  (ref) => PlayerStateNotifier(
    getAllVerses: sl<GetAllVerses>(),
    audioHandler: sl<RhemaAudioHandler>(),
  ),
);

class PlayerStateNotifier extends StateNotifier<PlayerState> {
  static const String _missingAudioMessage =
      'No audio is available for this verse yet.';

  final GetAllVerses getAllVerses;
  final RhemaAudioHandler audioHandler;

  final List<StreamSubscription<dynamic>> _playbackSubscriptions = [];

  String? _preparedVerseId;
  String? _completionHandledVerseId;

  bool _subscriptionsInitialized = false;
  bool _queueNavigationInProgress = false;

  PlayerStateNotifier({
    required this.getAllVerses,
    required this.audioHandler,
  }) : super(const PlayerState.initial()) {
    _initializePlaybackSubscriptions();
  }

  Future<void> loadVerses() async {
    _setState(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );

    final result = await getAllVerses(const NoParams());

    await result.fold(
      (failure) async {
        try {
          await audioHandler.publishQueue(const <MediaItem>[]);
        } catch (_) {
          // Preserve the original verse-loading failure as the primary error.
        }

        _preparedVerseId = null;
        _completionHandledVerseId = null;

        _setState(
          state.copyWith(
            verses: const <Verse>[],
            queue: const <Verse>[],
            isLoading: false,
            errorMessage: failure.message,
            playbackStatus: VersePlaybackStatus.idle,
            position: Duration.zero,
            duration: Duration.zero,
            bufferedPosition: Duration.zero,
            clearSelectedVerse: true,
            clearCurrentQueueIndex: true,
          ),
        );
      },
      (verses) async {
        final queueItems = verses.map(_mediaItemFromVerse).toList(
              growable: false,
            );

        try {
          await audioHandler.publishQueue(queueItems);
        } catch (error) {
          _setState(
            state.copyWith(
              verses: verses,
              queue: verses,
              isLoading: false,
              errorMessage:
                  'Unable to publish the playback queue: $error',
              clearSelectedVerse: true,
              clearCurrentQueueIndex: true,
            ),
          );
          return;
        }

        _preparedVerseId = null;
        _completionHandledVerseId = null;

        _setState(
          state.copyWith(
            verses: verses,
            queue: verses,
            isLoading: false,
            playbackStatus: VersePlaybackStatus.idle,
            position: Duration.zero,
            duration: Duration.zero,
            bufferedPosition: Duration.zero,
            clearSelectedVerse: true,
            clearCurrentQueueIndex: true,
            clearErrorMessage: true,
            clearPlaybackError: true,
          ),
        );
      },
    );
  }

  Future<void> selectVerse(Verse verse) async {
    final queueIndex = state.queue.indexWhere(
      (queueVerse) => queueVerse.id == verse.id,
    );

    if (queueIndex < 0) {
      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError:
              'The selected verse is not available in the playback queue.',
        ),
      );
      return;
    }

    await _navigateToQueueIndex(
      queueIndex,
      autoplay: false,
    );
  }

  Future<void> next() async {
    final currentIndex = state.currentQueueIndex;

    if (currentIndex == null || !state.hasNext) {
      return;
    }

    await _navigateToQueueIndex(
      currentIndex + 1,
      autoplay: false,
    );
  }

  Future<void> previous() async {
    final currentIndex = state.currentQueueIndex;

    if (currentIndex == null || !state.hasPrevious) {
      return;
    }

    await _navigateToQueueIndex(
      currentIndex - 1,
      autoplay: false,
    );
  }

  Future<void> play() async {
    final selectedVerse = state.selectedVerse;

    if (selectedVerse == null) {
      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError: 'Select a verse before starting playback.',
        ),
      );
      return;
    }

    if (!_hasAudioPath(selectedVerse)) {
      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError: _missingAudioMessage,
        ),
      );
      return;
    }

    if (_preparedVerseId != selectedVerse.id) {
      final prepared = await _prepareSelectedVerse();

      if (!prepared) {
        return;
      }
    }

    try {
      if (state.isCompleted ||
          (state.duration > Duration.zero &&
              state.position >= state.duration)) {
        await audioHandler.seek(Duration.zero);
      }

      _completionHandledVerseId = null;
      unawaited(audioHandler.play());
    } catch (error) {
      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError: 'Unable to play this verse: $error',
        ),
      );
    }
  }

  Future<void> pause() async {
    if (state.playbackStatus != VersePlaybackStatus.playing) {
      return;
    }

    try {
      await audioHandler.pause();
    } catch (error) {
      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError: 'Unable to pause playback: $error',
        ),
      );
    }
  }

  Future<void> stop() async {
    try {
      await audioHandler.stop();

      _preparedVerseId = null;
      _completionHandledVerseId = null;

      _setState(
        state.copyWith(
          playbackStatus: state.selectedVerse == null
              ? VersePlaybackStatus.idle
              : VersePlaybackStatus.stopped,
          position: Duration.zero,
          duration: Duration.zero,
          bufferedPosition: Duration.zero,
          clearPlaybackError: true,
        ),
      );
    } catch (error) {
      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError: 'Unable to stop playback: $error',
        ),
      );
    }
  }

  Future<void> seek(Duration requestedPosition) async {
    final selectedVerse = state.selectedVerse;

    if (selectedVerse == null ||
        !_hasAudioPath(selectedVerse) ||
        state.duration <= Duration.zero ||
        _preparedVerseId != selectedVerse.id) {
      return;
    }

    final targetPosition = _clampDuration(
      requestedPosition,
      Duration.zero,
      state.duration,
    );

    try {
      await audioHandler.seek(targetPosition);
    } catch (error) {
      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError: 'Unable to seek within this verse: $error',
        ),
      );
    }
  }

  Future<void> _navigateToQueueIndex(
    int queueIndex, {
    required bool autoplay,
  }) async {
    if (_queueNavigationInProgress) {
      return;
    }

    if (queueIndex < 0 || queueIndex >= state.queue.length) {
      return;
    }

    _queueNavigationInProgress = true;

    try {
      final verse = state.queue[queueIndex];

      try {
        await audioHandler.stop();
      } catch (_) {
        // Navigation remains safe if no audio source is loaded.
      }

      _preparedVerseId = null;
      _completionHandledVerseId = null;

      try {
        await audioHandler.setActiveQueueIndex(queueIndex);
      } catch (error) {
        _setState(
          state.copyWith(
            playbackStatus: VersePlaybackStatus.error,
            playbackError:
                'Unable to activate the selected queue item: $error',
          ),
        );
        return;
      }

      _setState(
        state.copyWith(
          selectedVerse: verse,
          currentQueueIndex: queueIndex,
          playbackStatus: VersePlaybackStatus.stopped,
          position: Duration.zero,
          duration: Duration.zero,
          bufferedPosition: Duration.zero,
          clearPlaybackError: true,
        ),
      );

      if (!_hasAudioPath(verse)) {
        _setState(
          state.copyWith(
            playbackStatus: VersePlaybackStatus.error,
            playbackError: _missingAudioMessage,
            position: Duration.zero,
            duration: Duration.zero,
            bufferedPosition: Duration.zero,
          ),
        );
        return;
      }

      final prepared = await _prepareSelectedVerse();

      if (!prepared || !autoplay) {
        return;
      }

      _completionHandledVerseId = null;
      unawaited(audioHandler.play());
    } finally {
      _queueNavigationInProgress = false;
    }
  }

  Future<bool> _prepareSelectedVerse() async {
    final selectedVerse = state.selectedVerse;
    final audioPath = selectedVerse?.audioPath?.trim();

    if (selectedVerse == null || audioPath == null || audioPath.isEmpty) {
      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError: _missingAudioMessage,
          position: Duration.zero,
          duration: Duration.zero,
          bufferedPosition: Duration.zero,
        ),
      );
      return false;
    }

    _setState(
      state.copyWith(
        playbackStatus: VersePlaybackStatus.preparing,
        position: Duration.zero,
        duration: Duration.zero,
        bufferedPosition: Duration.zero,
        clearPlaybackError: true,
      ),
    );

    try {
      await audioHandler.prepareSource(audioPath);
      _preparedVerseId = selectedVerse.id;

      final loadedDuration = audioHandler.duration ?? Duration.zero;

      _setState(
        state.copyWith(
          playbackStatus: _statusFromPlaybackState(
            audioHandler.playbackState.value,
          ),
          position: _clampDuration(
            audioHandler.position,
            Duration.zero,
            loadedDuration,
          ),
          duration: loadedDuration,
          bufferedPosition: _clampDuration(
            audioHandler.bufferedPosition,
            Duration.zero,
            loadedDuration,
          ),
          clearPlaybackError: true,
        ),
      );

      return true;
    } catch (error) {
      _preparedVerseId = null;

      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError: 'Unable to prepare this verse for playback: $error',
          position: Duration.zero,
          duration: Duration.zero,
          bufferedPosition: Duration.zero,
        ),
      );

      return false;
    }
  }

  void _initializePlaybackSubscriptions() {
    if (_subscriptionsInitialized) {
      return;
    }

    _subscriptionsInitialized = true;

    _playbackSubscriptions.add(
      audioHandler.playbackState.listen(
        _handlePlaybackStateChanged,
        onError: _handlePlaybackStreamError,
      ),
    );

    _playbackSubscriptions.add(
      audioHandler.positionStream.listen(
        _handlePositionChanged,
        onError: _handlePlaybackStreamError,
      ),
    );

    _playbackSubscriptions.add(
      audioHandler.durationStream.listen(
        _handleDurationChanged,
        onError: _handlePlaybackStreamError,
      ),
    );

    _playbackSubscriptions.add(
      audioHandler.bufferedPositionStream.listen(
        _handleBufferedPositionChanged,
        onError: _handlePlaybackStreamError,
      ),
    );

    _playbackSubscriptions.add(
      audioHandler.queueNavigationRequests.listen(
        _handleSystemQueueNavigationRequest,
        onError: _handlePlaybackStreamError,
      ),
    );
  }

  void _handlePlaybackStateChanged(PlaybackState playbackState) {
    if (!mounted) {
      return;
    }

    final previousStatus = state.playbackStatus;
    final status = _statusFromPlaybackState(playbackState);

    final shouldResetProgress =
        playbackState.processingState == AudioProcessingState.idle &&
            state.selectedVerse != null;

    final completed =
        playbackState.processingState == AudioProcessingState.completed;

    _setState(
      state.copyWith(
        playbackStatus: status,
        position: shouldResetProgress
            ? Duration.zero
            : completed && state.duration > Duration.zero
                ? state.duration
                : state.position,
        duration: shouldResetProgress ? Duration.zero : state.duration,
        bufferedPosition:
            shouldResetProgress ? Duration.zero : state.bufferedPosition,
        clearPlaybackError:
            status != VersePlaybackStatus.error,
      ),
    );

    if (completed &&
        previousStatus != VersePlaybackStatus.completed) {
      unawaited(_handleCompletionDrivenAdvance());
    }
  }

  Future<void> _handleCompletionDrivenAdvance() async {
    if (!mounted || _queueNavigationInProgress) {
      return;
    }

    final selectedVerse = state.selectedVerse;
    final currentIndex = state.currentQueueIndex;

    if (selectedVerse == null || currentIndex == null) {
      return;
    }

    if (_completionHandledVerseId == selectedVerse.id) {
      return;
    }

    _completionHandledVerseId = selectedVerse.id;

    if (!state.hasNext) {
      return;
    }

    await _navigateToQueueIndex(
      currentIndex + 1,
      autoplay: true,
    );
  }

  Future<void> _handleSystemQueueNavigationRequest(
    int queueIndex,
  ) async {
    if (!mounted) {
      return;
    }

    await _navigateToQueueIndex(
      queueIndex,
      autoplay: false,
    );
  }

  VersePlaybackStatus _statusFromPlaybackState(
    PlaybackState playbackState,
  ) {
    switch (playbackState.processingState) {
      case AudioProcessingState.idle:
        return state.selectedVerse == null
            ? VersePlaybackStatus.idle
            : VersePlaybackStatus.stopped;

      case AudioProcessingState.loading:
      case AudioProcessingState.buffering:
        return VersePlaybackStatus.preparing;

      case AudioProcessingState.ready:
        if (playbackState.playing) {
          return VersePlaybackStatus.playing;
        }

        if (playbackState.updatePosition > Duration.zero) {
          return VersePlaybackStatus.paused;
        }

        return VersePlaybackStatus.ready;

      case AudioProcessingState.completed:
        return VersePlaybackStatus.completed;

      case AudioProcessingState.error:
        return VersePlaybackStatus.error;
    }
  }

  void _handlePositionChanged(Duration position) {
    if (!mounted) {
      return;
    }

    final duration = state.duration;

    _setState(
      state.copyWith(
        position: duration > Duration.zero
            ? _clampDuration(position, Duration.zero, duration)
            : _nonNegativeDuration(position),
      ),
    );
  }

  void _handleDurationChanged(Duration? duration) {
    if (!mounted) {
      return;
    }

    final safeDuration = duration ?? Duration.zero;

    _setState(
      state.copyWith(
        duration: safeDuration,
        position: safeDuration > Duration.zero
            ? _clampDuration(
                state.position,
                Duration.zero,
                safeDuration,
              )
            : Duration.zero,
        bufferedPosition: safeDuration > Duration.zero
            ? _clampDuration(
                state.bufferedPosition,
                Duration.zero,
                safeDuration,
              )
            : Duration.zero,
      ),
    );
  }

  void _handleBufferedPositionChanged(Duration bufferedPosition) {
    if (!mounted) {
      return;
    }

    final duration = state.duration;

    _setState(
      state.copyWith(
        bufferedPosition: duration > Duration.zero
            ? _clampDuration(
                bufferedPosition,
                Duration.zero,
                duration,
              )
            : _nonNegativeDuration(bufferedPosition),
      ),
    );
  }

  void _handlePlaybackStreamError(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (!mounted) {
      return;
    }

    _setState(
      state.copyWith(
        playbackStatus: VersePlaybackStatus.error,
        playbackError: 'A playback update failed: $error',
      ),
    );
  }

  void _setState(PlayerState nextState) {
    if (!mounted || nextState == state) {
      return;
    }

    state = nextState;
  }

  MediaItem _mediaItemFromVerse(Verse verse) {
    return MediaItem(
      id: verse.id,
      title: _verseReference(verse),
      album: verse.translation,
      extras: <String, dynamic>{
        'translation': verse.translation,
        'audioPath': verse.audioPath ?? '',
      },
    );
  }

  String _verseReference(Verse verse) {
    return '${verse.book} ${verse.chapter}:${verse.verse}';
  }

  bool _hasAudioPath(Verse verse) {
    return verse.audioPath?.trim().isNotEmpty ?? false;
  }

  Duration _nonNegativeDuration(Duration value) {
    return value < Duration.zero ? Duration.zero : value;
  }

  Duration _clampDuration(
    Duration value,
    Duration minimum,
    Duration maximum,
  ) {
    if (maximum <= minimum) {
      return minimum;
    }

    if (value < minimum) {
      return minimum;
    }

    if (value > maximum) {
      return maximum;
    }

    return value;
  }

  @override
  void dispose() {
    for (final subscription in _playbackSubscriptions) {
      unawaited(subscription.cancel());
    }

    _playbackSubscriptions.clear();
    super.dispose();
  }
}