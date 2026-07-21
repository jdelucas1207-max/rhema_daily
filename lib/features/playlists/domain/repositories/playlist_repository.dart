import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/playlist.dart';
import '../entities/playlist_with_verses.dart';

abstract class PlaylistRepository {
  Future<Either<Failure, Playlist>> createPlaylist(
    Playlist playlist,
  );

  Future<Either<Failure, Playlist>> renamePlaylist({
    required String playlistId,
    required String name,
    required DateTime updatedAt,
  });

  Future<Either<Failure, void>> deletePlaylist(
    String playlistId,
  );

  Future<Either<Failure, List<Playlist>>> getAllPlaylists();

  Future<Either<Failure, PlaylistWithVerses>> getPlaylistContents(
    String playlistId,
  );

  Future<Either<Failure, void>> addVerseToPlaylist({
    required String playlistId,
    required String verseId,
  });

  Future<Either<Failure, void>> removeVerseFromPlaylist({
    required String playlistId,
    required String verseId,
  });

  Future<Either<Failure, void>> reorderPlaylistVerses({
    required String playlistId,
    required List<String> orderedVerseIds,
  });
}