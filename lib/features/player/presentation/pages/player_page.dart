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
                                style: Theme.of(context).textTheme.labelLarge,
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
                onPlay: notifier.play,
                onPause: notifier.pause,
                onStop: notifier.stop,
                onSeek: notifier.seek,
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
  final Future<void> Function(Duration position) onSeek;

  const _PlaybackControls({
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final selectedVerse = state.selectedVerse;
    final hasAudioPath = selectedVerse?.audioPath?.trim().isNotEmpty ?? false;

    final isPreparing = state.playbackStatus == VersePlaybackStatus.preparing;
    final isPlaying = state.playbackStatus == VersePlaybackStatus.playing;

    final canPlay = selectedVerse != null &&
        hasAudioPath &&
        !isPreparing &&
        !isPlaying &&
        state.playbackError == null;

    final canPause = isPlaying;

    final canStop = selectedVerse != null &&
        (isPreparing ||
            isPlaying ||
            state.playbackStatus == VersePlaybackStatus.paused ||
            state.playbackStatus == VersePlaybackStatus.ready ||
            state.playbackStatus == VersePlaybackStatus.completed);

    final canSeek =
        selectedVerse != null && hasAudioPath && state.duration > Duration.zero;

    final maximumMilliseconds = state.duration.inMilliseconds.toDouble();

    final sliderValue = canSeek
        ? state.position.inMilliseconds
            .clamp(0, state.duration.inMilliseconds)
            .toDouble()
        : 0.0;

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
              Slider(
                value: sliderValue,
                min: 0,
                max: canSeek ? maximumMilliseconds : 1,
                onChanged: canSeek
                    ? (value) {
                        onSeek(
                          Duration(milliseconds: value.round()),
                        );
                      }
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(state.position)),
                    Text(_formatDuration(state.duration)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: state.isCompleted ? 'Replay' : 'Play',
                    onPressed: canPlay ? onPlay : null,
                    icon: Icon(
                      state.isCompleted ? Icons.replay : Icons.play_arrow,
                    ),
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

  static String _formatDuration(Duration duration) {
    final safeDuration = duration < Duration.zero ? Duration.zero : duration;

    final hours = safeDuration.inHours;
    final minutes = safeDuration.inMinutes.remainder(60);
    final seconds = safeDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${safeDuration.inMinutes}:'
        '${seconds.toString().padLeft(2, '0')}';
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
      case VersePlaybackStatus.completed:
        return 'Playback completed.';
      case VersePlaybackStatus.error:
        return 'Playback unavailable.';
    }
  }
}
