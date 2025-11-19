# Redis Dart Client

[![Pub](https://img.shields.io/pub/v/redis_dart_client.svg)](https://pub.dev/packages/redis_dart_client) [![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT) [![Coverage](https://img.shields.io/badge/coverage-80%25-brightgreen.svg)](https://github.com/petrovyuri/redis_dart_client) [![GitHub stars](https://img.shields.io/github/stars/petrovyuri/redis_dart_client?style=social)](https://github.com/petrovyuri/redis_dart_client)

A simple and lightweight Redis client for Dart that provides basic Redis operations.

## Features

- ✅ Simple and easy to use API
- ✅ Support for common Redis commands (GET, SET, DELETE, EXISTS, etc.)
- ✅ Connection management with authentication support
- ✅ Type-safe operations
- ✅ No external dependencies (uses Dart's built-in `dart:io`)
- ✅ Optional response timeout
- ✅ Simple pipeline batching
- ✅ Full UTF-8 support (including Cyrillic, Chinese, emoji, and other Unicode characters)

## Getting Started

### Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  redis_dart_client: <version>
```

Then run:

```bash
dart pub get
```

### Basic Usage

```dart
import 'package:redis_dart_client/redis_dart_client.dart';

void main() async {
  // Create a Redis client
  final client = RedisClient(
    host: 'localhost',
    port: 6379,
    responseTimeout: const Duration(seconds: 2), // optional timeout
    // password: 'your_password', // Optional
  );

  try {
    // Connect to Redis
    await client.connect();

    // Set a key-value pair
    await client.set('name', 'Redis Client');

    // Get a value
    final value = await client.get('name');
    print(value); // Output: Redis Client

    // Check if key exists
    final exists = await client.exists('name');
    print(exists); // Output: true

    // Delete a key
    await client.delete(['name']);

    // Disconnect
    await client.disconnect();
  } catch (e) {
    print('Error: $e');
  }
}
```

## Available Operations

### Connection Management

- `connect()` - Connects to the Redis server
- `disconnect()` - Disconnects from the Redis server
- `isConnected` - Checks if the client is connected

### Basic Operations

- `set(String key, String value)` - Sets a key-value pair
- `get(String key)` - Gets a value by key (returns `null` if key doesn't exist)
- `delete(List<String> keys)` - Deletes one or more keys
- `exists(String key)` - Checks if a key exists

### Advanced Operations

- `setex(String key, String value, int seconds)` - Sets a key with expiration time
- `ttl(String key)` - Gets the time to live of a key in seconds
- `incr(String key)` - Increments the integer value of a key by 1
- `decr(String key)` - Decrements the integer value of a key by 1
- `keys(String pattern)` - Gets all keys matching a pattern (e.g., `'user:*'`)
- `pipeline(List<List<String>> commands)` - Sends multiple commands without awaiting between them and then collects all responses

## Examples

### Pipeline Example

Pipeline allows you to send multiple commands efficiently without waiting for each response:

```dart
import 'package:redis_dart_client/redis_dart_client.dart';

void main() async {
  final client = RedisClient();
  await client.connect();

  try {
    // Execute multiple commands in a pipeline
    final results = await client.pipeline([
      ['SET', 'user:1', 'Alice'],
      ['SET', 'user:2', 'Bob'],
      ['GET', 'user:1'],
      ['GET', 'user:2'],
      ['INCR', 'visitor_count'],
      ['INCR', 'visitor_count'],
    ]);

    print('Results: $results');
    // Output: ['OK', 'OK', 'Alice', 'Bob', 1, 2]

    // Clean up
    await client.delete(['user:1', 'user:2', 'visitor_count']);
  } finally {
    await client.disconnect();
  }
}
```

### Flutter Example

This package works great with Flutter apps on mobile and desktop:

```dart
import 'package:flutter/material.dart';
import 'package:redis_dart_client/redis_dart_client.dart';

class RedisCacheService {
  late RedisClient _client;
  bool _isConnected = false;

  Future<void> initialize() async {
    _client = RedisClient(
      host: 'your-redis-server.com',
      port: 6379,
      password: 'your-password', // Optional
      responseTimeout: const Duration(seconds: 5),
    );

    try {
      await _client.connect();
      _isConnected = true;
    } on RedisException catch (e) {
      debugPrint('Failed to connect to Redis: $e');
      _isConnected = false;
    }
  }

  Future<String?> getCachedData(String key) async {
    if (!_isConnected) return null;
    
    try {
      return await _client.get(key);
    } on RedisException catch (e) {
      debugPrint('Error getting cache: $e');
      return null;
    }
  }

  Future<void> setCachedData(String key, String value, {int? ttl}) async {
    if (!_isConnected) return;
    
    try {
      if (ttl != null) {
        await _client.setex(key, value, ttl);
      } else {
        await _client.set(key, value);
      }
    } on RedisException catch (e) {
      debugPrint('Error setting cache: $e');
    }
  }

  Future<void> disconnect() async {
    if (_isConnected) {
      await _client.disconnect();
      _isConnected = false;
    }
  }
}

// Usage in a Flutter widget
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _cacheService = RedisCacheService();
  String? _cachedValue;

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    _cachedValue = await _cacheService.getCachedData('my_key');
    setState(() {});
  }

  @override
  void dispose() {
    _cacheService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Redis Cache Example')),
        body: Center(
          child: Text(_cachedValue ?? 'No cached value'),
        ),
      ),
    );
  }
}
```

See the [example](https://github.com/petrovyuri/redis_dart_client/blob/main/example/lib/redis_dart_client_example.dart) directory for a complete example demonstrating all available operations.

### Running the Example

To run the example, you need a Redis server running. The easiest way is to use Docker:

1. **Install Docker** (if not already installed):
   - Download from [docker.com](https://www.docker.com/get-started)

2. **Start a Redis container**:
   ```bash
   docker run --rm -d -p 6379:6379 --name redis-test redis:alpine
   ```

3. **Run the example**:
   ```bash
   cd example
   dart run lib/redis_dart_client_example.dart
   ```

4. **Stop the Redis container** (when done):
   ```bash
   docker stop redis-test
   ```

The example demonstrates all available operations including SET, GET, DELETE, EXISTS, SETEX, TTL, INCR, DECR, KEYS, and pipeline operations.

## Error Handling

All operations can throw a `RedisException` if something goes wrong. Here are examples of proper error handling:

### Basic Error Handling

```dart
try {
  await client.set('key', 'value');
} on RedisException catch (e) {
  print('Redis error: $e');
}
```

### Comprehensive Error Handling

```dart
import 'package:redis_dart_client/redis_dart_client.dart';

void main() async {
  final client = RedisClient(
    host: 'localhost',
    port: 6379,
    responseTimeout: const Duration(seconds: 5),
  );

  try {
    await client.connect();
    
    // Perform operations
    await client.set('user:1', 'Alice');
    final value = await client.get('user:1');
    print('Value: $value');
    
  } on RedisException catch (e) {
    // Handle Redis-specific errors
    print('Redis operation failed: ${e.message}');
    
    // Check connection status
    if (!client.isConnected) {
      print('Connection lost. Attempting to reconnect...');
      try {
        await client.connect();
        print('Reconnected successfully');
      } catch (reconnectError) {
        print('Reconnection failed: $reconnectError');
      }
    }
  } catch (e) {
    // Handle other errors
    print('Unexpected error: $e');
  } finally {
    // Always disconnect
    if (client.isConnected) {
      await client.disconnect();
    }
  }
}
```

## Requirements

- Dart SDK >= 3.1.0
- Redis server running and accessible
- (Optional) Docker to quickly start a local Redis instance

## Supported Platforms

This package uses `dart:io` for socket communication, which means it supports:

- ✅ **Dart (Server)** - Command-line applications and server-side Dart
- ✅ **Flutter** - Mobile and desktop applications
  - ✅ Android
  - ✅ iOS
  - ✅ Linux
  - ✅ macOS
  - ✅ Windows
- ❌ **Flutter Web** - Not supported (browsers don't support `dart:io`)

**Note:** This package works perfectly with Flutter apps on mobile and desktop platforms. For Flutter web applications, consider using a Redis proxy or WebSocket-based solution.

## Test Coverage

The project has comprehensive test coverage with **44 tests** covering all major functionality:

| File | Coverage |
|------|----------|
| `redis_client.dart` | **>90%** - All public methods and edge cases |
| `redis_protocol.dart` | **>75%** - All RESP protocol types and error handling |
| `redis_exception.dart` | **~100%** - Full coverage of exception handling |
| **Total** | **>80%** - Comprehensive test suite |

### Test Categories

- ✅ **Core Operations**: SET, GET, DELETE, EXISTS
- ✅ **Advanced Operations**: SETEX, TTL, INCR, DECR, KEYS
- ✅ **Connection Management**: Connect, disconnect, reconnection
- ✅ **Error Handling**: Connection errors, authentication, timeouts
- ✅ **Edge Cases**: Empty lists, null responses, invalid inputs
- ✅ **Protocol Testing**: All RESP response types (simple strings, bulk strings, integers, arrays)
- ✅ **UTF-8 Support**: Cyrillic, Chinese, emoji characters
- ✅ **Validation**: Port range validation, parameter validation

Run tests with coverage:

```bash
dart test --coverage=coverage
dart pub global activate coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib
```

## Troubleshooting

### Hanging on first command (e.g. SET)
Ensure you are using the latest version of the client (RESP formatted with `\r\n`) and that Redis is reachable at the configured `host:port`.

### Timeout errors
If `responseTimeout` is set, reading a response will throw a `RedisException` when the timeout is exceeded.

### Quick Redis start with Docker

```bash
docker run --rm -d -p 6379:6379 --name redis-test redis:alpine
```


## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
