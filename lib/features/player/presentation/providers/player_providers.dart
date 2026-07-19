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

  String? _preparedVerseId;

  PlayerStateNotifier({
    required this.getAllVerses,
    required this.audioHandler,
  }) : super(const PlayerState.initial());

  Future<void> loadVerses() async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
    );

    final result = await getAllVerses(const NoParams());

    state = result.fold(
      (failure) => state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (verses) => state.copyWith(
        verses: verses,
        isLoading: false,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> selectVerse(Verse verse) async {
    try {
      await audioHandler.stop();
    } catch (_) {
      // Selection must remain safe even when no audio is loaded.
    }

    _preparedVerseId = null;

    state = state.copyWith(
      selectedVerse: verse,
      playbackStatus: VersePlaybackStatus.stopped,
      clearPlaybackError: true,
    );

    if (!_hasAudioPath(verse)) {
      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.error,
        playbackError: 'No audio is available for this verse yet.',
      );
      return;
    }

    await _prepareSelectedVerse();
  }

  Future<void> play() async {
    final selectedVerse = state.selectedVerse;

    if (selectedVerse == null) {
      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.error,
        playbackError: 'Select a verse before starting playback.',
      );
      return;
    }

    if (!_hasAudioPath(selectedVerse)) {
      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.error,
        playbackError: 'No audio is available for this verse yet.',
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
      audioHandler.play();

      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.playing,
        clearPlaybackError: true,
      );
    } catch (error) {
      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.error,
        playbackError: 'Unable to play this verse: $error',
      );
    }
  }

  Future<void> pause() async {
    if (state.playbackStatus != VersePlaybackStatus.playing) {
      return;
    }

    try {
      await audioHandler.pause();

      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.paused,
        clearPlaybackError: true,
      );
    } catch (error) {
      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.error,
        playbackError: 'Unable to pause playback: $error',
      );
    }
  }

  Future<void> stop() async {
    try {
      await audioHandler.stop();
      _preparedVerseId = null;

      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.stopped,
        clearPlaybackError: true,
      );
    } catch (error) {
      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.error,
        playbackError: 'Unable to stop playback: $error',
      );
    }
  }

  Future<bool> _prepareSelectedVerse() async {
    final selectedVerse = state.selectedVerse;
    final audioPath = selectedVerse?.audioPath?.trim();

    if (selectedVerse == null || audioPath == null || audioPath.isEmpty) {
      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.error,
        playbackError: 'No audio is available for this verse yet.',
      );
      return false;
    }

    state = state.copyWith(
      playbackStatus: VersePlaybackStatus.preparing,
      clearPlaybackError: true,
    );

    try {
      await audioHandler.prepare(audioPath);
      _preparedVerseId = selectedVerse.id;

      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.ready,
        clearPlaybackError: true,
      );

      return true;
    } catch (error) {
      _preparedVerseId = null;

      state = state.copyWith(
        playbackStatus: VersePlaybackStatus.error,
        playbackError: 'Unable to prepare this verse for playback: $error',
      );

      return false;
    }
  }

  bool _hasAudioPath(Verse verse) {
    return verse.audioPath?.trim().isNotEmpty ?? false;
  }
}