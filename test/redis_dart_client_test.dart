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
      expect(keys,
          containsAll(['pattern:test1', 'pattern:test2', 'pattern:test3']));

      await client.delete(
          ['pattern:test1', 'pattern:test2', 'pattern:test3', 'other:key']);
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
  });
}
