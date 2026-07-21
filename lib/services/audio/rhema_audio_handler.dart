import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// App-owned audio service for verse playback.
///
/// This handler is the single owner of [AudioPlayer]. Presentation code must
/// communicate with this class rather than with [AudioPlayer] directly.
///
/// Riverpod owns the application queue index. This handler mirrors that index
/// for the operating system media session and forwards system queue-navigation
/// requests back to the presentation layer.
class RhemaAudioHandler extends BaseAudioHandler {
  final AudioPlayer _audioPlayer = AudioPlayer(
    handleInterruptions: false,
  );

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  final StreamController<int> _queueNavigationController =
      StreamController<int>.broadcast();

  late final Future<void> _audioSessionInitialization;

  int? _currentQueueIndex;

  bool _resumeAfterInterruption = false;
  bool _isDucked = false;
  bool _disposed = false;

  RhemaAudioHandler() {
    _audioSessionInitialization = _initializeAudioSession();
    _initializePlayerSubscriptions();
    _broadcastPlaybackState();
  }

  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  Stream<Duration> get bufferedPositionStream =>
      _audioPlayer.bufferedPositionStream;

  Stream<bool> get completionStream => _audioPlayer.playerStateStream
      .map(
        (playerState) =>
            playerState.processingState == ProcessingState.completed,
      )
      .distinct();

  /// Queue-item indices requested by operating-system media controls.
  ///
  /// The presentation notifier owns navigation and source preparation.
  Stream<int> get queueNavigationRequests =>
      _queueNavigationController.stream;

  Duration get position => _audioPlayer.position;

  Duration? get duration => _audioPlayer.duration;

  Duration get bufferedPosition => _audioPlayer.bufferedPosition;

  int? get currentQueueIndex => _currentQueueIndex;

  bool get hasPreviousQueueItem {
    final index = _currentQueueIndex;
    return index != null && index > 0;
  }

  bool get hasNextQueueItem {
    final index = _currentQueueIndex;
    final items = queue.value;

    return index != null &&
        index >= 0 &&
        index < items.length - 1;
  }

  /// Publishes the full verse queue to the operating-system media session.
  ///
  /// This does not select or prepare an item unless [initialIndex] is supplied.
  Future<void> publishQueue(
    List<MediaItem> items, {
    int? initialIndex,
  }) async {
    final immutableItems = List<MediaItem>.unmodifiable(items);

    queue.add(immutableItems);

    if (immutableItems.isEmpty) {
      _currentQueueIndex = null;
      mediaItem.add(null);
      _broadcastPlaybackState();
      return;
    }

    if (initialIndex != null) {
      await setActiveQueueIndex(initialIndex);
      return;
    }

    final currentIndex = _currentQueueIndex;

    if (currentIndex != null &&
        currentIndex >= 0 &&
        currentIndex < immutableItems.length) {
      mediaItem.add(immutableItems[currentIndex]);
    } else {
      _currentQueueIndex = null;
      mediaItem.add(null);
    }

    _broadcastPlaybackState();
  }

  /// Sets the active media-session queue item without preparing or playing it.
  Future<void> setActiveQueueIndex(int index) async {
    final items = queue.value;

    if (index < 0 || index >= items.length) {
      throw RangeError.index(
        index,
        items,
        'index',
        'Queue index is outside the published queue.',
        items.length,
      );
    }

    _currentQueueIndex = index;
    mediaItem.add(items[index]);

    _broadcastPlaybackState();
  }

  /// Publishes standalone verse metadata.
  ///
  /// This API is retained for compatibility. When the verse exists in the
  /// published queue, that queue item is activated.
  Future<void> publishVerse({
    required String verseId,
    required String reference,
    required String translation,
  }) async {
    final normalizedId = verseId.trim();
    final normalizedReference = reference.trim();
    final normalizedTranslation = translation.trim();

    if (normalizedId.isEmpty || normalizedReference.isEmpty) {
      throw const FormatException(
        'The selected verse does not contain valid media metadata.',
      );
    }

    final items = queue.value;
    final queueIndex = items.indexWhere(
      (item) => item.id == normalizedId,
    );

    if (queueIndex >= 0) {
      await setActiveQueueIndex(queueIndex);
      return;
    }

    _currentQueueIndex = null;

    mediaItem.add(
      MediaItem(
        id: normalizedId,
        title: normalizedReference,
        album: normalizedTranslation,
        extras: <String, dynamic>{
          'translation': normalizedTranslation,
        },
      ),
    );

    _broadcastPlaybackState();
  }

  /// Prepares an audio source for playback.
  ///
  /// HTTP and HTTPS values are treated as remote URLs. All other values are
  /// treated as local file paths.
  Future<void> prepareSource(String audioPath) async {
    await _audioSessionInitialization;

    final normalizedPath = audioPath.trim();

    if (normalizedPath.isEmpty) {
      throw const FormatException(
        'No audio is available for this verse yet.',
      );
    }

    await _audioPlayer.stop();

    final uri = Uri.tryParse(normalizedPath);
    final scheme = uri?.scheme.toLowerCase();

    if (scheme == 'http' || scheme == 'https') {
      await _audioPlayer.setUrl(normalizedPath);
    } else if (scheme == 'file' && uri != null) {
      await _audioPlayer.setFilePath(uri.toFilePath());
    } else {
      await _audioPlayer.setFilePath(normalizedPath);
    }

    _updatePublishedDuration();
    _broadcastPlaybackState();
  }

  /// Handles play commands from both the app UI and the system media session.
  @override
  Future<void> play() async {
    await _audioSessionInitialization;

    if (_audioPlayer.processingState == ProcessingState.completed) {
      await _audioPlayer.seek(Duration.zero);
    }

    unawaited(_audioPlayer.play());
  }

  /// Handles pause commands from both the app UI and system media controls.
  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Handles stop commands from both the app UI and system media controls.
  @override
  Future<void> stop() async {
    _resumeAfterInterruption = false;

    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero);

    _broadcastPlaybackState();
  }

  /// Handles seek commands from both the app UI and system media controls.
  @override
  Future<void> seek(Duration requestedPosition) async {
    final loadedDuration = _audioPlayer.duration;

    if (loadedDuration == null || loadedDuration <= Duration.zero) {
      return;
    }

    var targetPosition = requestedPosition;

    if (targetPosition < Duration.zero) {
      targetPosition = Duration.zero;
    } else if (targetPosition > loadedDuration) {
      targetPosition = loadedDuration;
    }

    await _audioPlayer.seek(targetPosition);
    _broadcastPlaybackState();
  }

  /// Requests navigation to the next queue item.
  ///
  /// Riverpod receives the request and performs selection and preparation.
  @override
  Future<void> skipToNext() async {
    final index = _currentQueueIndex;

    if (index == null || !hasNextQueueItem) {
      return;
    }

    _emitQueueNavigationRequest(index + 1);
  }

  /// Requests navigation to the previous queue item.
  ///
  /// Queue navigation never wraps.
  @override
  Future<void> skipToPrevious() async {
    final index = _currentQueueIndex;

    if (index == null || !hasPreviousQueueItem) {
      return;
    }

    _emitQueueNavigationRequest(index - 1);
  }

  /// Requests navigation to a specific published queue item.
  @override
  Future<void> skipToQueueItem(int index) async {
    final items = queue.value;

    if (index < 0 || index >= items.length) {
      return;
    }

    if (index == _currentQueueIndex) {
      return;
    }

    _emitQueueNavigationRequest(index);
  }

  void _emitQueueNavigationRequest(int index) {
    if (_disposed || _queueNavigationController.isClosed) {
      return;
    }

    _queueNavigationController.add(index);
  }

  Future<void> _initializeAudioSession() async {
    final session = await AudioSession.instance;

    await session.configure(
      AudioSessionConfiguration.speech(),
    );

    _subscriptions.add(
      session.interruptionEventStream.listen(
        _handleInterruption,
      ),
    );

    _subscriptions.add(
      session.becomingNoisyEventStream.listen(
        (_) => _handleBecomingNoisy(),
      ),
    );
  }

  void _initializePlayerSubscriptions() {
    _subscriptions.add(
      _audioPlayer.playerStateStream.listen(
        (_) => _broadcastPlaybackState(),
      ),
    );

    _subscriptions.add(
      _audioPlayer.bufferedPositionStream.listen(
        (_) => _broadcastPlaybackState(),
      ),
    );

    _subscriptions.add(
      _audioPlayer.durationStream.listen(
        (_) {
          _updatePublishedDuration();
          _broadcastPlaybackState();
        },
      ),
    );
  }

  Future<void> _handleInterruption(
    AudioInterruptionEvent event,
  ) async {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          if (_audioPlayer.playing) {
            _isDucked = true;
            await _audioPlayer.setVolume(0.5);
          }

        case AudioInterruptionType.pause:
          _resumeAfterInterruption = _audioPlayer.playing;

          if (_audioPlayer.playing) {
            await pause();
          }

        case AudioInterruptionType.unknown:
          _resumeAfterInterruption = false;

          if (_audioPlayer.playing) {
            await pause();
          }
      }

      return;
    }

    switch (event.type) {
      case AudioInterruptionType.duck:
        if (_isDucked) {
          _isDucked = false;
          await _audioPlayer.setVolume(1.0);
        }

      case AudioInterruptionType.pause:
        final shouldResume = _resumeAfterInterruption;
        _resumeAfterInterruption = false;

        if (shouldResume) {
          await play();
        }

      case AudioInterruptionType.unknown:
        _resumeAfterInterruption = false;
    }
  }

  Future<void> _handleBecomingNoisy() async {
    _resumeAfterInterruption = false;

    if (_audioPlayer.playing) {
      await pause();
    }
  }

  void _updatePublishedDuration() {
    final currentItem = mediaItem.value;

    if (currentItem == null) {
      return;
    }

    final loadedDuration = _audioPlayer.duration;

    if (currentItem.duration == loadedDuration) {
      return;
    }

    final updatedItem = currentItem.copyWith(
      duration: loadedDuration,
    );

    mediaItem.add(updatedItem);

    final index = _currentQueueIndex;
    final items = queue.value;

    if (index == null || index < 0 || index >= items.length) {
      return;
    }

    final updatedQueue = List<MediaItem>.of(items);
    updatedQueue[index] = updatedItem;

    queue.add(List<MediaItem>.unmodifiable(updatedQueue));
  }

  void _broadcastPlaybackState() {
    if (_disposed) {
      return;
    }

    final isPlaying = _audioPlayer.playing;
    final controls = <MediaControl>[];

    if (hasPreviousQueueItem) {
      controls.add(MediaControl.skipToPrevious);
    }

    controls.add(
      isPlaying ? MediaControl.pause : MediaControl.play,
    );

    if (hasNextQueueItem) {
      controls.add(MediaControl.skipToNext);
    }

    controls.add(MediaControl.stop);

    final playPauseIndex = controls.indexWhere(
      (control) =>
          control == MediaControl.play ||
          control == MediaControl.pause,
    );

    final compactActionIndices = <int>[
      if (hasPreviousQueueItem)
        controls.indexOf(MediaControl.skipToPrevious),
      if (playPauseIndex >= 0) playPauseIndex,
      if (hasNextQueueItem)
        controls.indexOf(MediaControl.skipToNext),
    ];

    final nextState = PlaybackState(
      controls: controls,
      systemActions: const <MediaAction>{
        MediaAction.seek,
        MediaAction.skipToQueueItem,
      },
      androidCompactActionIndices: compactActionIndices,
      processingState: _mapProcessingState(
        _audioPlayer.processingState,
      ),
      playing: isPlaying,
      updatePosition: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
      queueIndex: _currentQueueIndex,
    );

    final currentState = playbackState.value;

    if (_playbackStatesMatch(currentState, nextState)) {
      return;
    }

    playbackState.add(nextState);
  }

  AudioProcessingState _mapProcessingState(
    ProcessingState processingState,
  ) {
    switch (processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  bool _playbackStatesMatch(
    PlaybackState current,
    PlaybackState next,
  ) {
    return current.playing == next.playing &&
        current.processingState == next.processingState &&
        current.updatePosition == next.updatePosition &&
        current.bufferedPosition == next.bufferedPosition &&
        current.speed == next.speed &&
        current.queueIndex == next.queueIndex &&
        _listEquals(current.controls, next.controls) &&
        _listEquals(
          current.androidCompactActionIndices,
          next.androidCompactActionIndices,
        ) &&
        _setEquals(current.systemActions, next.systemActions);
  }

  bool _listEquals<T>(List<T>? first, List<T>? second) {
    if (identical(first, second)) {
      return true;
    }

    if (first == null || second == null) {
      return false;
    }

    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }

  bool _setEquals<T>(Set<T> first, Set<T> second) {
    return first.length == second.length && first.containsAll(second);
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();

    await _queueNavigationController.close();
    await _audioPlayer.dispose();
  }
}