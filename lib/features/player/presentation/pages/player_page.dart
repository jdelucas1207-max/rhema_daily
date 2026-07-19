import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_providers.dart';
import '../state/player_state.dart';

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
    final notifier = ref.read(playerStateNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rhema Daily'),
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state.verses.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No verses are stored locally yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.verses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final verse = state.verses[index];
                    final isSelected = state.selectedVerse?.id == verse.id;

                    return Card(
                      child: InkWell(
                        onTap: () async {
                          await notifier.selectVerse(verse);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      verse.book,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_outline,
                                      semanticLabel: 'Selected verse',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${verse.chapter}:${verse.verse} · '
                                '${verse.translation}',
                                style:
                                    Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                verse.verseText,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _PlaybackControls(
                state: state,
                onPlay: () async {
                  await notifier.play();
                },
                onPause: () async {
                  await notifier.pause();
                },
                onStop: () async {
                  await notifier.stop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  final PlayerState state;
  final Future<void> Function() onPlay;
  final Future<void> Function() onPause;
  final Future<void> Function() onStop;

  const _PlaybackControls({
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final selectedVerse = state.selectedVerse;
    final isPreparing =
        state.playbackStatus == VersePlaybackStatus.preparing;
    final isPlaying = state.playbackStatus == VersePlaybackStatus.playing;

    final canPlay = selectedVerse != null &&
        !isPreparing &&
        !isPlaying &&
        state.playbackError == null;

    final canPause = isPlaying;

    final canStop = selectedVerse != null &&
        (isPreparing ||
            isPlaying ||
            state.playbackStatus == VersePlaybackStatus.paused ||
            state.playbackStatus == VersePlaybackStatus.ready);

    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedVerse == null)
                const Text(
                  'Select a verse to prepare it for playback.',
                  textAlign: TextAlign.center,
                )
              else ...[
                Text(
                  '${selectedVerse.book} '
                  '${selectedVerse.chapter}:${selectedVerse.verse}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  selectedVerse.translation,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                if (isPreparing)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Preparing audio…'),
                    ],
                  )
                else if (state.playbackError != null)
                  Text(
                    state.playbackError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                else
                  Text(
                    _statusLabel(state.playbackStatus),
                    textAlign: TextAlign.center,
                  ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Play',
                    onPressed: canPlay ? onPlay : null,
                    icon: const Icon(Icons.play_arrow),
                  ),
                  IconButton(
                    tooltip: 'Pause',
                    onPressed: canPause ? onPause : null,
                    icon: const Icon(Icons.pause),
                  ),
                  IconButton(
                    tooltip: 'Stop',
                    onPressed: canStop ? onStop : null,
                    icon: const Icon(Icons.stop),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(VersePlaybackStatus status) {
    switch (status) {
      case VersePlaybackStatus.idle:
        return 'Ready to select a verse.';
      case VersePlaybackStatus.preparing:
        return 'Preparing audio…';
      case VersePlaybackStatus.ready:
        return 'Ready to play.';
      case VersePlaybackStatus.playing:
        return 'Playing.';
      case VersePlaybackStatus.paused:
        return 'Paused.';
      case VersePlaybackStatus.stopped:
        return 'Stopped.';
      case VersePlaybackStatus.error:
        return 'Playback unavailable.';
    }
  }
}