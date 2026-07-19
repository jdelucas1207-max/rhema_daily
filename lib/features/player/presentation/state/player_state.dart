import 'package:equatable/equatable.dart';

import '../../domain/entities/verse.dart';

enum VersePlaybackStatus {
  idle,
  preparing,
  ready,
  playing,
  paused,
  stopped,
  error,
}

/// Presentation state for verse loading and basic audio playback.
class PlayerState extends Equatable {
  final List<Verse> verses;
  final Verse? selectedVerse;
  final bool isLoading;
  final String? errorMessage;
  final VersePlaybackStatus playbackStatus;
  final String? playbackError;

  const PlayerState({
    required this.verses,
    required this.selectedVerse,
    required this.isLoading,
    required this.errorMessage,
    required this.playbackStatus,
    required this.playbackError,
  });

  const PlayerState.initial()
      : verses = const [],
        selectedVerse = null,
        isLoading = false,
        errorMessage = null,
        playbackStatus = VersePlaybackStatus.idle,
        playbackError = null;

  PlayerState copyWith({
    List<Verse>? verses,
    Verse? selectedVerse,
    bool? isLoading,
    String? errorMessage,
    VersePlaybackStatus? playbackStatus,
    String? playbackError,
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
      ];
}