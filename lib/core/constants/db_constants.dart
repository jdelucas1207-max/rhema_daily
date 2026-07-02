/// Central database constants for Rhema Daily.
///
/// Keeping schema names here avoids scattering table and column strings
/// across the project.
class DbConstants {
  DbConstants._();

  static const String databaseName = 'rhema_daily.db';
  static const int databaseVersion = 1;

  static const String versesTable = 'verses';

  static const String columnId = 'id';
  static const String columnBook = 'book';
  static const String columnChapter = 'chapter';
  static const String columnVerse = 'verse';
  static const String columnTranslation = 'translation';
  static const String columnVerseText = 'verse_text';
  static const String columnAudioPath = 'audio_path';
  static const String columnDurationInSeconds = 'duration_in_seconds';
  static const String columnCreatedAt = 'created_at';
}
