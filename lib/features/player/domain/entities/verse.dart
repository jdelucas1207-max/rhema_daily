import 'package:equatable/equatable.dart';

/// Core business entity for a Bible verse in Rhema Daily.
class Verse extends Equatable {
  final String id;
  final String book;
  final int chapter;
  final int verse;
  final String translation;
  final String verseText;
  final String? audioPath;
  final int? durationInSeconds;
  final DateTime createdAt;

  const Verse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.translation,
    required this.verseText,
    required this.audioPath,
    required this.durationInSeconds,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        book,
        chapter,
        verse,
        translation,
        verseText,
        audioPath,
        durationInSeconds,
        createdAt,
      ];
}
