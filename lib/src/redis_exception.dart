/// Exception thrown when Redis operation fails
class RedisException implements Exception {
  RedisException(this.message);
  final String message;

  @override
  String toString() => 'RedisException: $message';
}
