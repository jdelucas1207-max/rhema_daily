class DatabaseException implements Exception {
  final String message;

  const DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException(message: $message)';
}

class VerseNotFoundException implements Exception {
  final String message;

  const VerseNotFoundException(this.message);

  @override
  String toString() => 'VerseNotFoundException(message: $message)';
}
