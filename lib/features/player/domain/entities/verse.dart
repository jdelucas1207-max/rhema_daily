import 'package:equatable/equatable.dart';

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

  Verse copyWith({
    String? id,
    String? book,
    int? chapter,
    int? verse,
    String? translation,
    String? verseText,
    String? audioPath,
    int? durationInSeconds,
    DateTime? createdAt,
  }) {
    return Verse(
      id: id ?? this.id,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      translation: translation ?? this.translation,
      verseText: verseText ?? this.verseText,
      audioPath: audioPath ?? this.audioPath,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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