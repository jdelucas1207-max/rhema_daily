import '../models/verse_model.dart';

/// Initial verse records inserted when the local database is empty.
///
/// WEB and KJV records are stored separately so the same Bible reference
/// can exist in multiple translations.
class VerseSeedData {
  VerseSeedData._();

  static final DateTime _seedCreatedAt = DateTime.utc(2026, 1, 1);

  static final List<VerseModel> verses = [
    VerseModel(
      id: 'web_john_3_16',
      book: 'John',
      chapter: 3,
      verse: 16,
      translation: 'WEB',
      verseText:
          'For God so loved the world, that he gave his one and only Son, '
          'that whoever believes in him should not perish, but have eternal life.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'kjv_john_3_16',
      book: 'John',
      chapter: 3,
      verse: 16,
      translation: 'KJV',
      verseText:
          'For God so loved the world, that he gave his only begotten Son, '
          'that whosoever believeth in him should not perish, '
          'but have everlasting life.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'web_john_3_17',
      book: 'John',
      chapter: 3,
      verse: 17,
      translation: 'WEB',
      verseText:
          'For God didn’t send his Son into the world to judge the world, '
          'but that the world should be saved through him.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'kjv_john_3_17',
      book: 'John',
      chapter: 3,
      verse: 17,
      translation: 'KJV',
      verseText:
          'For God sent not his Son into the world to condemn the world; '
          'but that the world through him might be saved.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'web_philippians_4_6',
      book: 'Philippians',
      chapter: 4,
      verse: 6,
      translation: 'WEB',
      verseText:
          'In nothing be anxious, but in everything, by prayer and petition '
          'with thanksgiving, let your requests be made known to God.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'kjv_philippians_4_6',
      book: 'Philippians',
      chapter: 4,
      verse: 6,
      translation: 'KJV',
      verseText:
          'Be careful for nothing; but in every thing by prayer and supplication '
          'with thanksgiving let your requests be made known unto God.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'web_philippians_4_7',
      book: 'Philippians',
      chapter: 4,
      verse: 7,
      translation: 'WEB',
      verseText:
          'And the peace of God, which surpasses all understanding, '
          'will guard your hearts and your thoughts in Christ Jesus.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'kjv_philippians_4_7',
      book: 'Philippians',
      chapter: 4,
      verse: 7,
      translation: 'KJV',
      verseText:
          'And the peace of God, which passeth all understanding, '
          'shall keep your hearts and minds through Christ Jesus.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'web_psalms_23_1',
      book: 'Psalms',
      chapter: 23,
      verse: 1,
      translation: 'WEB',
      verseText: 'Yahweh is my shepherd; I shall lack nothing.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'kjv_psalms_23_1',
      book: 'Psalms',
      chapter: 23,
      verse: 1,
      translation: 'KJV',
      verseText: 'The Lord is my shepherd; I shall not want.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'web_psalms_46_1',
      book: 'Psalms',
      chapter: 46,
      verse: 1,
      translation: 'WEB',
      verseText:
          'God is our refuge and strength, a very present help in trouble.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'kjv_psalms_46_1',
      book: 'Psalms',
      chapter: 46,
      verse: 1,
      translation: 'KJV',
      verseText:
          'God is our refuge and strength, a very present help in trouble.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'web_isaiah_41_10',
      book: 'Isaiah',
      chapter: 41,
      verse: 10,
      translation: 'WEB',
      verseText:
          'Don’t you be afraid, for I am with you. Don’t be dismayed, '
          'for I am your God. I will strengthen you. Yes, I will help you. '
          'Yes, I will uphold you with the right hand of my righteousness.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'kjv_isaiah_41_10',
      book: 'Isaiah',
      chapter: 41,
      verse: 10,
      translation: 'KJV',
      verseText:
          'Fear thou not; for I am with thee: be not dismayed; '
          'for I am thy God: I will strengthen thee; yea, I will help thee; '
          'yea, I will uphold thee with the right hand of my righteousness.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'web_matthew_11_28',
      book: 'Matthew',
      chapter: 11,
      verse: 28,
      translation: 'WEB',
      verseText:
          'Come to me, all you who labor and are heavily burdened, '
          'and I will give you rest.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
    VerseModel(
      id: 'kjv_matthew_11_28',
      book: 'Matthew',
      chapter: 11,
      verse: 28,
      translation: 'KJV',
      verseText:
          'Come unto me, all ye that labour and are heavy laden, '
          'and I will give you rest.',
      audioPath: '',
      durationInSeconds: 0,
      createdAt: _seedCreatedAt,
    ),
  ];
}