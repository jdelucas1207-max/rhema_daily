import 'package:just_audio/just_audio.dart';

/// App-owned audio service.
///
/// Playback behavior is intentionally not implemented in Phase 1.
/// The player instance lives here so future UI code will not talk
/// directly to the audio plugin.
class RhemaAudioHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
