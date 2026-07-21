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
  final GetAllVerses getAllVerses;
  final RhemaAudioHandler audioHandler;

  final List<StreamSubscription<dynamic>> _playbackSubscriptions = [];

  String? _preparedVerseId;
  bool _subscriptionsInitialized = false;

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

    _setState(
      result.fold(
        (failure) => state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
        (verses) => state.copyWith(
          verses: verses,
          isLoading: false,
          clearErrorMessage: true,
        ),
      ),
    );
  }

  Future<void> selectVerse(Verse verse) async {
    try {
      await audioHandler.stop();
    } catch (_) {
      // Selection remains safe even if no audio source is currently loaded.
    }

    _preparedVerseId = null;

    _setState(
      state.copyWith(
        selectedVerse: verse,
        playbackStatus: VersePlaybackStatus.stopped,
        position: Duration.zero,
        duration: Duration.zero,
        bufferedPosition: Duration.zero,
        clearPlaybackError: true,
      ),
    );

    try {
      await audioHandler.publishVerse(
        verseId: verse.id,
        reference: _verseReference(verse),
        translation: verse.translation,
      );
    } catch (error) {
      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError: 'Unable to publish verse metadata: $error',
        ),
      );
      return;
    }

    if (!_hasAudioPath(verse)) {
      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError: 'No audio is available for this verse yet.',
        ),
      );
      return;
    }

    await _prepareSelectedVerse();
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
          playbackError: 'No audio is available for this verse yet.',
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

  Future<bool> _prepareSelectedVerse() async {
    final selectedVerse = state.selectedVerse;
    final audioPath = selectedVerse?.audioPath?.trim();

    if (selectedVerse == null || audioPath == null || audioPath.isEmpty) {
      _setState(
        state.copyWith(
          playbackStatus: VersePlaybackStatus.error,
          playbackError: 'No audio is available for this verse yet.',
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
  }

  void _handlePlaybackStateChanged(PlaybackState playbackState) {
    if (!mounted) {
      return;
    }

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