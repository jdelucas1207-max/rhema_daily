import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_all_verses.dart';
import '../state/player_state.dart';

final playerStateNotifierProvider =
    StateNotifierProvider<PlayerStateNotifier, PlayerState>(
  (ref) => PlayerStateNotifier(
    getAllVerses: sl<GetAllVerses>(),
  ),
);

class PlayerStateNotifier extends StateNotifier<PlayerState> {
  final GetAllVerses getAllVerses;

  PlayerStateNotifier({
    required this.getAllVerses,
  }) : super(const PlayerState.initial());

  Future<void> loadVerses() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
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
        errorMessage: null,
      ),
    );
  }
}
