import 'package:equatable/equatable.dart';

import '../../domain/entities/verse.dart';

enum VersePlaybackStatus {
  idle,
  preparing,
  ready,
  playing,
  paused,
  stopped,
  completed,
  error,
}

/// Presentation state for verse loading, queue navigation, and audio playback.
class PlayerState extends Equatable {
  final List<Verse> verses;
  final List<Verse> queue;
  final Verse? selectedVerse;
  final int? currentQueueIndex;
  final bool isLoading;
  final String? errorMessage;
  final VersePlaybackStatus playbackStatus;
  final String? playbackError;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;

  const PlayerState({
    required this.verses,
    required this.queue,
    required this.selectedVerse,
    required this.currentQueueIndex,
    required this.isLoading,
    required this.errorMessage,
    required this.playbackStatus,
    required this.playbackError,
    required this.position,
    required this.duration,
    required this.bufferedPosition,
  });

  const PlayerState.initial()
      : verses = const [],
        queue = const [],
        selectedVerse = null,
        currentQueueIndex = null,
        isLoading = false,
        errorMessage = null,
        playbackStatus = VersePlaybackStatus.idle,
        playbackError = null,
        position = Duration.zero,
        duration = Duration.zero,
        bufferedPosition = Duration.zero;

  bool get isCompleted => playbackStatus == VersePlaybackStatus.completed;

  bool get hasSeekableDuration => duration > Duration.zero;

  bool get hasPrevious {
    final index = currentQueueIndex;
    return index != null && index > 0 && index < queue.length;
  }

  bool get hasNext {
    final index = currentQueueIndex;

    return index != null &&
        index >= 0 &&
        index < queue.length - 1;
  }

  Verse? get currentQueueItem {
    final index = currentQueueIndex;

    if (index == null || index < 0 || index >= queue.length) {
      return null;
    }

    return queue[index];
  }

  PlayerState copyWith({
    List<Verse>? verses,
    List<Verse>? queue,
    Verse? selectedVerse,
    int? currentQueueIndex,
    bool? isLoading,
    String? errorMessage,
    VersePlaybackStatus? playbackStatus,
    String? playbackError,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    bool clearSelectedVerse = false,
    bool clearCurrentQueueIndex = false,
    bool clearErrorMessage = false,
    bool clearPlaybackError = false,
  }) {
    return PlayerState(
      verses: verses ?? this.verses,
      queue: queue ?? this.queue,
      selectedVerse:
          clearSelectedVerse ? null : selectedVerse ?? this.selectedVerse,
      currentQueueIndex: clearCurrentQueueIndex
          ? null
          : currentQueueIndex ?? this.currentQueueIndex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      playbackStatus: playbackStatus ?? this.playbackStatus,
      playbackError:
          clearPlaybackError ? null : playbackError ?? this.playbackError,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
    );
  }

  @override
  List<Object?> get props => [
        verses,
        queue,
        selectedVerse,
        currentQueueIndex,
        isLoading,
        errorMessage,
        playbackStatus,
        playbackError,
        position,
        duration,
        bufferedPosition,
      ];
}