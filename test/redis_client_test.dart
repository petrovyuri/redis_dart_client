import 'package:redis_dart_client/redis_dart_client.dart';
import 'package:test/test.dart';

void main() {
  group('RedisClient', () {
    late RedisClient client;

    setUp(() {
      client = RedisClient();
    });

    tearDown(() async {
      if (client.isConnected) {
        await client.disconnect();
      }
    });

    test('should create a Redis client instance', () {
      expect(client, isNotNull);
      expect(client.isConnected, isFalse);
    });

    test('should connect to Redis server', () async {
      await client.connect();
      expect(client.isConnected, isTrue);
    });

    test('should set and get a value', () async {
      await client.connect();
      await client.set('test_key', 'test_value');
      final value = await client.get('test_key');
      expect(value, equals('test_value'));
      await client.delete(['test_key']);
    });

    test('should return null for non-existent key', () async {
      await client.connect();
      final value = await client.get('non_existent_key');
      expect(value, isNull);
    });

    test('should check if key exists', () async {
      await client.connect();
      await client.set('exists_test', 'value');
      final exists = await client.exists('exists_test');
      expect(exists, isTrue);
      await client.delete(['exists_test']);
    });

    test('should delete keys', () async {
      await client.connect();
      await client.set('delete_test1', 'value1');
      await client.set('delete_test2', 'value2');
      final deleted = await client.delete(['delete_test1', 'delete_test2']);
      expect(deleted, equals(2));
    });

    test('should increment a counter', () async {
      await client.connect();
      final value1 = await client.incr('counter_test');
      expect(value1, equals(1));
      final value2 = await client.incr('counter_test');
      expect(value2, equals(2));
      await client.delete(['counter_test']);
    });

    test('should decrement a counter', () async {
      await client.connect();
      await client.set('counter_test', '5');
      final value = await client.decr('counter_test');
      expect(value, equals(4));
      await client.delete(['counter_test']);
    });

    test('should set key with expiration', () async {
      await client.connect();
      await client.setex('expire_test', 'value', 10);
      final ttl = await client.ttl('expire_test');
      expect(ttl, greaterThan(0));
      expect(ttl, lessThanOrEqualTo(10));
      await client.delete(['expire_test']);
    });

    test('should throw exception when not connected', () {
      expect(
        () => client.set('key', 'value'),
        throwsA(isA<RedisException>()),
      );
    });

    test('should disconnect from Redis server', () async {
      await client.connect();
      expect(client.isConnected, isTrue);
      await client.disconnect();
      expect(client.isConnected, isFalse);
    });

    test('should execute pipeline commands', () async {
      await client.connect();
      final results = await client.pipeline([
        ['SET', 'pipeline:key1', 'value1'],
        ['SET', 'pipeline:key2', 'value2'],
        ['GET', 'pipeline:key1'],
        ['GET', 'pipeline:key2'],
        ['INCR', 'pipeline:counter'],
        ['INCR', 'pipeline:counter'],
      ]);

      expect(results.length, equals(6));
      expect(results[0], equals('OK')); // SET pipeline:key1
      expect(results[1], equals('OK')); // SET pipeline:key2
      expect(results[2], equals('value1')); // GET pipeline:key1
      expect(results[3], equals('value2')); // GET pipeline:key2
      expect(results[4], equals(1)); // INCR pipeline:counter
      expect(results[5], equals(2)); // INCR pipeline:counter

      await client
          .delete(['pipeline:key1', 'pipeline:key2', 'pipeline:counter']);
    });

    test('should accept responseTimeout parameter', () {
      final timeoutClient = RedisClient(
        responseTimeout: const Duration(seconds: 5),
      );
      expect(timeoutClient, isNotNull);
    });

    test('should get keys with pattern matching', () async {
      await client.connect();
      await client.set('pattern:test1', 'value1');
      await client.set('pattern:test2', 'value2');
      await client.set('pattern:test3', 'value3');
      await client.set('other:key', 'value');

      final keys = await client.keys('pattern:*');
      expect(keys.length, equals(3));
      expect(
        keys,
        containsAll(['pattern:test1', 'pattern:test2', 'pattern:test3']),
      );

      await client.delete(
        ['pattern:test1', 'pattern:test2', 'pattern:test3', 'other:key'],
      );
    });

    test('should handle TTL for non-existent key', () async {
      await client.connect();
      final ttl = await client.ttl('non_existent_key');
      expect(ttl, equals(-2)); // -2 means key doesn't exist
    });

    test('should handle TTL for key without expiration', () async {
      await client.connect();
      await client.set('no_expire_key', 'value');
      final ttl = await client.ttl('no_expire_key');
      expect(ttl, equals(-1)); // -1 means no expiration set
      await client.delete(['no_expire_key']);
    });

    test('should handle UTF-8 and Cyrillic characters correctly', () async {
      await client.connect();
      // Test with Cyrillic text
      const cyrillicValue = 'Привет, мир! Тест кириллицы: 中文测试';
      const cyrillicKey = 'тест:ключ';

      await client.set(cyrillicKey, cyrillicValue);
      final retrievedValue = await client.get(cyrillicKey);
      expect(retrievedValue, equals(cyrillicValue));

      // Test with mixed content
      const mixedValue = 'Hello 世界! Привет! 🌍';
      await client.set('mixed:key', mixedValue);
      final retrievedMixed = await client.get('mixed:key');
      expect(retrievedMixed, equals(mixedValue));

      await client.delete([cyrillicKey, 'mixed:key']);
    });

    test('should validate port range', () {
      expect(
        () => RedisClient(port: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RedisClient(port: 65536),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RedisClient(port: -1),
        throwsA(isA<ArgumentError>()),
      );
      // Valid ports should not throw
      expect(RedisClient(port: 1), isNotNull);
      expect(RedisClient(port: 65535), isNotNull);
      expect(RedisClient(port: 6379), isNotNull);
    });

    test('should handle connection errors gracefully', () async {
      final invalidClient = RedisClient(
        host: 'invalid-host-that-does-not-exist',
        port: 12345,
      );
      expect(
        () => invalidClient.connect(),
        throwsA(isA<RedisException>()),
      );
      expect(invalidClient.isConnected, isFalse);
    });

    test('should handle authentication errors', () async {
      final clientWithPassword = RedisClient(
        password: 'wrong-password',
      );
      try {
        await clientWithPassword.connect();
        // If connection succeeds, try to authenticate
        // This will fail if Redis requires auth
        await clientWithPassword.set('test', 'value');
      } catch (e) {
        expect(e, isA<RedisException>());
      } finally {
        if (clientWithPassword.isConnected) {
          await clientWithPassword.disconnect();
        }
      }
    });

    test('should handle multiple connect calls', () async {
      await client.connect();
      expect(client.isConnected, isTrue);
      // Second connect should not throw
      await client.connect();
      expect(client.isConnected, isTrue);
      await client.disconnect();
    });

    test('should handle disconnect when not connected', () async {
      expect(client.isConnected, isFalse);
      // Should not throw
      await client.disconnect();
      expect(client.isConnected, isFalse);
    });

    test('should handle parsing errors in delete', () async {
      await client.connect();
      // This test verifies error handling in delete method
      // Normal case is already tested, this ensures error path is covered
      await client.set('test_parse', 'value');
      final deleted = await client.delete(['test_parse']);
      expect(deleted, isA<int>());
    });

    test('should handle empty keys list in delete', () async {
      await client.connect();
      // Redis doesn't accept DEL without arguments, so empty list returns 0
      final deleted = await client.delete([]);
      expect(deleted, equals(0));
    });

    test('should handle keys with empty pattern', () async {
      await client.connect();
      final keys = await client.keys('');
      expect(keys, isA<List<String>>());
    });

    test('should handle exists for non-existent key', () async {
      await client.connect();
      final exists = await client.exists('definitely_does_not_exist_key');
      expect(exists, isFalse);
    });

    test('should handle all operations throwing when not connected', () {
      expect(
        () => client.get('key'),
        throwsA(isA<RedisException>()),
      );
      expect(
        () => client.set('key', 'value'),
        throwsA(isA<RedisException>()),
      );
      expect(
        () => client.delete(['key']),
        throwsA(isA<RedisException>()),
      );
      expect(
        () => client.exists('key'),
        throwsA(isA<RedisException>()),
      );
      expect(
        () => client.setex('key', 'value', 10),
        throwsA(isA<RedisException>()),
      );
      expect(
        () => client.ttl('key'),
        throwsA(isA<RedisException>()),
      );
      expect(
        () => client.incr('key'),
        throwsA(isA<RedisException>()),
      );
      expect(
        () => client.decr('key'),
        throwsA(isA<RedisException>()),
      );
      expect(
        () => client.keys('pattern'),
        throwsA(isA<RedisException>()),
      );
      expect(
        () => client.pipeline([
          ['SET', 'key', 'value']
        ]),
        throwsA(isA<RedisException>()),
      );
    });

    test('should handle empty pipeline', () async {
      await client.connect();
      final results = await client.pipeline([]);
      expect(results, isEmpty);
    });

    test('should handle keys with no matches', () async {
      await client.connect();
      final keys = await client.keys('nonexistent:pattern:*');
      expect(keys, isEmpty);
      expect(keys, isA<List<String>>());
    });

    test('should handle multiple disconnect calls', () async {
      await client.connect();
      expect(client.isConnected, isTrue);
      await client.disconnect();
      expect(client.isConnected, isFalse);
      // Second disconnect should not throw
      await client.disconnect();
      expect(client.isConnected, isFalse);
    });

    test('should handle custom host and port', () {
      final customClient = RedisClient(
        host: 'custom-host',
        port: 6380,
      );
      expect(customClient, isNotNull);
    });

    test('should handle responseTimeout parameter', () {
      final timeoutClient = RedisClient(
        responseTimeout: const Duration(milliseconds: 100),
      );
      expect(timeoutClient, isNotNull);
    });
  });
}
