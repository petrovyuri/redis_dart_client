import 'package:redis_dart_client/redis_dart_client.dart';

/// Example usage of the Redis client
Future<void> main() async {
  // Create a Redis client instance
  final client = RedisClient(
      // host: "127.0.0.1",
      // port: 6379,
      // password: "redispassword",
      );

  try {
    // Connect to Redis server
    print('Connecting to Redis...');
    await client.connect();
    print('Connected successfully!\n');

    // SET operation - set a key-value pair
    print('Setting key "name" to "Redis Client"');
    await client.set('name', 'Redis Client');
    print('✓ Key set successfully\n');

    // GET operation - get a value by key
    print('Getting value for key "name"');
    final name = await client.get('name');
    print('✓ Value: $name\n');

    // EXISTS operation - check if key exists
    print('Checking if key "name" exists');
    final exists = await client.exists('name');
    print('✓ Key exists: $exists\n');

    // SETEX operation - set a key with expiration
    print('Setting key "temp" with 10 seconds expiration');
    await client.setex('temp', 'This will expire', 10);
    print('✓ Key set with expiration\n');

    // TTL operation - get time to live
    print('Getting TTL for key "temp"');
    final ttl = await client.ttl('temp');
    print('✓ TTL: $ttl seconds\n');

    // INCR operation - increment a counter
    print('Incrementing counter "counter"');
    final counter1 = await client.incr('counter');
    print('✓ Counter value: $counter1');
    final counter2 = await client.incr('counter');
    print('✓ Counter value: $counter2');
    final counter3 = await client.incr('counter');
    print('✓ Counter value: $counter3\n');

    // DECR operation - decrement a counter
    print('Decrementing counter "counter"');
    final counter4 = await client.decr('counter');
    print('✓ Counter value: $counter4\n');

    // SET multiple values for KEYS example
    print('Setting multiple keys for pattern matching');
    await client.set('user:1', 'Alice');
    await client.set('user:2', 'Bob');
    await client.set('user:3', 'Charlie');
    await client.set('product:1', 'Laptop');
    print('✓ Keys set\n');

    // KEYS operation - get all keys matching a pattern
    print('Getting all keys matching pattern "user:*"');
    final userKeys = await client.keys('user:*');
    print('✓ Found ${userKeys.length} keys:');
    for (final key in userKeys) {
      final value = await client.get(key);
      print('  - $key: $value');
    }
    print('');

    // DELETE operation - delete keys
    print('Deleting keys "user:1" and "user:2"');
    final deleted = await client.delete(['user:1', 'user:2']);
    print('✓ Deleted $deleted key(s)\n');

    // Verify deletion
    print('Checking if "user:1" still exists');
    final user1Exists = await client.exists('user:1');
    print('✓ Key exists: $user1Exists\n');

    // Clean up - delete remaining test keys
    print('Cleaning up test keys...');
    await client.delete(['name', 'temp', 'counter', 'user:3', 'product:1']);
    print('✓ Cleanup complete\n');

    print('All operations completed successfully!');
  } on Object catch (e) {
    print('Error: $e');
  } finally {
    // Always disconnect when done
    print('\nDisconnecting from Redis...');
    await client.disconnect();
    print('Disconnected.');
  }
}
