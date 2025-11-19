/// Exception thrown when Redis operation fails
class RedisException implements Exception {
  /// Creates a new RedisException instance
  ///
  /// [message] - The error message
  RedisException(this.message);
  // Error message
  final String message;

  // Returns a string representation of the exception
  @override
  String toString() => 'RedisException: $message';
}
