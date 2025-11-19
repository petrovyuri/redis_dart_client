import 'package:redis_dart_client/redis_dart_client.dart';
import 'package:test/test.dart';

void main() {
  group('RedisException', () {
    test('should create exception with message', () {
      const message = 'Test error message';
      final exception = RedisException(message);
      expect(exception.message, equals(message));
    });

    test('should return correct string representation', () {
      const message = 'Connection failed';
      final exception = RedisException(message);
      expect(exception.toString(), equals('RedisException: $message'));
    });

    test('should be throwable', () {
      expect(
        () => throw RedisException('Test'),
        throwsA(isA<RedisException>()),
      );
    });

    test('should handle empty message', () {
      final exception = RedisException('');
      expect(exception.message, isEmpty);
      expect(exception.toString(), equals('RedisException: '));
    });

    test('should handle long error messages', () {
      final longMessage = 'A' * 1000;
      final exception = RedisException(longMessage);
      expect(exception.message, equals(longMessage));
      expect(exception.toString(), contains('RedisException:'));
      expect(exception.toString(), contains(longMessage));
    });
  });
}
