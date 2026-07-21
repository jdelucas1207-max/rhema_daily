import 'package:equatable/equatable.dart';

import '../../../../core/constants/db_constants.dart';

/// SQLite/data-layer model for a playlist-to-verse relationship.
class PlaylistVerseModel extends Equatable {
  final String playlistId;
  final String verseId;
  final int sortOrder;

  const PlaylistVerseModel({
    required this.playlistId,
    required this.verseId,
    required this.sortOrder,
  });

  factory PlaylistVerseModel.fromMap(Map<String, dynamic> map) {
    return PlaylistVerseModel(
      playlistId: map[DbConstants.columnPlaylistId] as String,
      verseId: map[DbConstants.columnVerseId] as String,
      sortOrder: map[DbConstants.columnSortOrder] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.columnPlaylistId: playlistId,
      DbConstants.columnVerseId: verseId,
      DbConstants.columnSortOrder: sortOrder,
    };
  }

  @override
  List<Object?> get props => [
        playlistId,
        verseId,
        sortOrder,
      ];
}