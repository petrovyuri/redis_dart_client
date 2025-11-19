# Redis Dart Client

[![Pub](https://img.shields.io/pub/v/redis_dart_client.svg)](https://pub.dev/packages/redis_dart_client) [![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT) [![GitHub stars](https://img.shields.io/github/stars/petrovyuri/redis_dart_client?style=social)](https://github.com/petrovyuri/redis_dart_client)

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

All operations can throw a `RedisException` if something goes wrong:

```dart
try {
  await client.set('key', 'value');
} on RedisException catch (e) {
  print('Redis error: $e');
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

The project has comprehensive test coverage:

| File | Coverage |
|------|----------|
| `redis_client.dart` | **93.4%** (71/76 lines) |
| `redis_protocol.dart` | **65.3%** (62/95 lines) |
| `redis_exception.dart` | **33.3%** (1/3 lines) |
| **Total** | **77.0%** (134/174 lines) |

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

### Pipeline example

```dart
final results = await client.pipeline([
  ['SET', 'pipeline:key', '123'],
  ['GET', 'pipeline:key'],
  ['INCR', 'counter'],
]);
print(results); // ['OK', '123', 1]
```

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
