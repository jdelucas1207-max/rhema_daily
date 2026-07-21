import '../../../../core/constants/db_constants.dart';
import '../../domain/entities/playlist.dart';

/// SQLite/data-layer model for a playlist.
class PlaylistModel extends Playlist {
  const PlaylistModel({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map[DbConstants.columnId] as String,
      name: map[DbConstants.columnName] as String,
      createdAt: DateTime.parse(
        map[DbConstants.columnCreatedAt] as String,
      ),
      updatedAt: DateTime.parse(
        map[DbConstants.columnUpdatedAt] as String,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.columnId: id,
      DbConstants.columnName: name,
      DbConstants.columnCreatedAt: createdAt.toIso8601String(),
      DbConstants.columnUpdatedAt: updatedAt.toIso8601String(),
    };
  }
}