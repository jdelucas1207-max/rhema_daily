import 'package:equatable/equatable.dart';

import '../../../player/domain/entities/verse.dart';
import 'playlist.dart';

class PlaylistWithVerses extends Equatable {
  final Playlist playlist;
  final List<Verse> verses;

  PlaylistWithVerses({
    required this.playlist,
    required List<Verse> verses,
  }) : verses = List<Verse>.unmodifiable(verses);

  @override
  List<Object?> get props => [
        playlist,
        verses,
      ];
}