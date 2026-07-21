import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';

import 'features/player/data/datasources/verse_local_datasource.dart';
import 'features/player/data/repositories/verse_repository_impl.dart';
import 'features/player/domain/repositories/verse_repository.dart';
import 'features/player/domain/usecases/get_all_verses.dart';
import 'features/player/domain/usecases/get_verse_by_id.dart';
import 'services/audio/rhema_audio_handler.dart';
import 'services/database/database_service.dart';

final GetIt sl = GetIt.instance;

/// Registers infrastructure and feature dependencies for Rhema Daily.
Future<void> init() async {
  final databaseService = DatabaseService();
  await databaseService.init();

  final audioHandler = await AudioService.init<RhemaAudioHandler>(
    builder: RhemaAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'com.example.rhema_daily.channel.audio',
      androidNotificationChannelName: 'Rhema Daily playback',
      androidNotificationChannelDescription:
          'Background playback controls for Rhema Daily verses.',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
    ),
  );

  sl.registerLazySingleton<DatabaseService>(() => databaseService);
  sl.registerLazySingleton<RhemaAudioHandler>(() => audioHandler);

  sl.registerLazySingleton<VerseLocalDataSource>(
    () => VerseLocalDataSourceImpl(
      databaseService: sl<DatabaseService>(),
    ),
  );

  sl.registerLazySingleton<VerseRepository>(
    () => VerseRepositoryImpl(
      localDataSource: sl<VerseLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<GetAllVerses>(
    () => GetAllVerses(sl<VerseRepository>()),
  );

  sl.registerLazySingleton<GetVerseById>(
    () => GetVerseById(sl<VerseRepository>()),
  );
}