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

/// Presentation state for verse loading and audio playback.
class PlayerState extends Equatable {
  final List<Verse> verses;
  final Verse? selectedVerse;
  final bool isLoading;
  final String? errorMessage;
  final VersePlaybackStatus playbackStatus;
  final String? playbackError;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;

  const PlayerState({
    required this.verses,
    required this.selectedVerse,
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
        selectedVerse = null,
        isLoading = false,
        errorMessage = null,
        playbackStatus = VersePlaybackStatus.idle,
        playbackError = null,
        position = Duration.zero,
        duration = Duration.zero,
        bufferedPosition = Duration.zero;

  bool get isCompleted => playbackStatus == VersePlaybackStatus.completed;

  bool get hasSeekableDuration => duration > Duration.zero;

  PlayerState copyWith({
    List<Verse>? verses,
    Verse? selectedVerse,
    bool? isLoading,
    String? errorMessage,
    VersePlaybackStatus? playbackStatus,
    String? playbackError,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    bool clearErrorMessage = false,
    bool clearPlaybackError = false,
  }) {
    return PlayerState(
      verses: verses ?? this.verses,
      selectedVerse: selectedVerse ?? this.selectedVerse,
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
        selectedVerse,
        isLoading,
        errorMessage,
        playbackStatus,
        playbackError,
        position,
        duration,
        bufferedPosition,
      ];
}
