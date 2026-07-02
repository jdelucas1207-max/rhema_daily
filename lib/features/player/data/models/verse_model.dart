import '../../../../core/constants/db_constants.dart';
import '../../domain/entities/verse.dart';

/// SQLite/data-layer model for a verse.
class VerseModel extends Verse {
  const VerseModel({
    required super.id,
    required super.book,
    required super.chapter,
    required super.verse,
    required super.translation,
    required super.verseText,
    required super.audioPath,
    required super.durationInSeconds,
    required super.createdAt,
  });

  factory VerseModel.fromMap(Map<String, dynamic> map) {
    return VerseModel(
      id: map[DbConstants.columnId] as String,
      book: map[DbConstants.columnBook] as String,
      chapter: map[DbConstants.columnChapter] as int,
      verse: map[DbConstants.columnVerse] as int,
      translation: map[DbConstants.columnTranslation] as String,
      verseText: map[DbConstants.columnVerseText] as String,
      audioPath: map[DbConstants.columnAudioPath] as String?,
      durationInSeconds: map[DbConstants.columnDurationInSeconds] as int?,
      createdAt: DateTime.parse(map[DbConstants.columnCreatedAt] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.columnId: id,
      DbConstants.columnBook: book,
      DbConstants.columnChapter: chapter,
      DbConstants.columnVerse: verse,
      DbConstants.columnTranslation: translation,
      DbConstants.columnVerseText: verseText,
      DbConstants.columnAudioPath: audioPath,
      DbConstants.columnDurationInSeconds: durationInSeconds,
      DbConstants.columnCreatedAt: createdAt.toIso8601String(),
    };
  }
}
