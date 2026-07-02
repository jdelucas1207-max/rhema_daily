import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_providers.dart';

/// Phase 1 entry page for the Rhema Daily player feature.
///
/// This is intentionally simple. It proves the architecture is wired up
/// without introducing fake data or premature feature behavior.
class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(playerStateNotifierProvider.notifier).loadVerses(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rhema Daily'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(
          builder: (context) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.errorMessage != null) {
              return Center(
                child: Text(state.errorMessage!),
              );
            }

            if (state.verses.isEmpty) {
              return const Center(
                child: Text(
                  'Rhema Daily foundation is ready.\nNo verses are stored locally yet.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.builder(
              itemCount: state.verses.length,
              itemBuilder: (context, index) {
                final verse = state.verses[index];

                return ListTile(
                  title: Text('${verse.book} ${verse.chapter}:${verse.verse}'),
                  subtitle: Text(verse.translation),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
