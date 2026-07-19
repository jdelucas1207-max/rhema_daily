import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// App-owned audio service for verse playback.
///
/// Presentation code must not communicate with [AudioPlayer] directly.
class RhemaAudioHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Prepares an audio source for playback.
  ///
  /// HTTP and HTTPS values are treated as remote URLs. All other values are
  /// treated as local file paths.
  Future<void> prepare(String audioPath) async {
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
      return;
    }

    if (scheme == 'file' && uri != null) {
      await _audioPlayer.setFilePath(uri.toFilePath());
      return;
    }

    await _audioPlayer.setFilePath(normalizedPath);
  }

  /// Starts or resumes the prepared audio source.
  ///
  /// The returned playback future is intentionally not awaited because
  /// just_audio keeps it active until playback pauses, stops, or completes.
  void play() {
    unawaited(_audioPlayer.play());
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}