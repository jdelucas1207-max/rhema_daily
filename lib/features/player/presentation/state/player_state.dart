import 'package:equatable/equatable.dart';

import '../../domain/entities/verse.dart';

/// Presentation state for the player feature.
///
/// This stays intentionally minimal in Phase 1 because
/// playback behavior is not implemented yet.
class PlayerState extends Equatable {
  final List<Verse> verses;
  final Verse? currentVerse;
  final bool isLoading;
  final String? errorMessage;

  const PlayerState({
    required this.verses,
    required this.currentVerse,
    required this.isLoading,
    required this.errorMessage,
  });

  const PlayerState.initial()
      : verses = const [],
        currentVerse = null,
        isLoading = false,
        errorMessage = null;

  PlayerState copyWith({
    List<Verse>? verses,
    Verse? currentVerse,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PlayerState(
      verses: verses ?? this.verses,
      currentVerse: currentVerse ?? this.currentVerse,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        verses,
        currentVerse,
        isLoading,
        errorMessage,
      ];
}
