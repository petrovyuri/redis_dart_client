import 'dart:async';
import 'dart:io';

import 'package:redis_dart_client/src/redis_exception.dart';
import 'package:redis_dart_client/src/redis_protocol.dart';

/// Simple Redis client implementation
class RedisClient {
  /// Creates a new Redis client instance
  ///
  /// [host] - Redis server hostname (default: 'localhost')
  /// [port] - Redis server port (default: 6379)
  /// [password] - Optional password for authentication
  /// [responseTimeout] - Optional timeout for Redis operations
  RedisClient({
    String host = 'localhost',
    int port = 6379,
    String? password,
    Duration? responseTimeout,
  })  : _host = host,
        _port = port,
        _password = password,
        _responseTimeout = responseTimeout;

  Socket? _socket;
  // Removed separate subscription; RedisProtocol internally listens to the socket.
  RedisProtocol? _protocol;
  final String _host;
  final int _port;
  final String? _password;
  bool _isConnected = false;
  final Duration? _responseTimeout;

  /// Connects to the Redis server
  Future<void> connect() async {
    if (_isConnected) {
      return;
    }

    try {
      _socket = await Socket.connect(_host, _port);
      _isConnected = true;

      // Setup protocol handler (it attaches a listener to the socket)
      _protocol = RedisProtocol(_socket!, responseTimeout: _responseTimeout);

      // Authenticate if password is provided
      if (_password != null) {
        await _protocol!.sendCommand(['AUTH', _password!]);
        await _protocol!.readResponse();
      }
    } catch (e) {
      _isConnected = false;
      throw RedisException('Failed to connect to Redis: $e');
    }
  }

  /// Disconnects from the Redis server
  Future<void> disconnect() async {
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
      _isConnected = false;
    }
    _protocol?.clearBuffer();
    _protocol = null;
  }

  /// Checks if the client is connected
  bool get isConnected => _isConnected && _socket != null;

  /// Sets a key-value pair in Redis
  ///
  /// [key] - The key to set
  /// [value] - The value to set
  /// Returns 'OK' on success
  Future<String> set(String key, String value) async {
    _ensureConnected();
    await _protocol!.sendCommand(['SET', key, value]);
    final response = await _protocol!.readResponse();
    return response.toString();
  }

  /// Gets a value by key from Redis
  ///
  /// [key] - The key to get
  /// Returns the value or null if key doesn't exist
  Future<String?> get(String key) async {
    _ensureConnected();
    await _protocol!.sendCommand(['GET', key]);
    final response = await _protocol!.readResponse();
    if (response == null) {
      return null;
    }
    return response.toString();
  }

  /// Deletes one or more keys from Redis
  ///
  /// [keys] - List of keys to delete
  /// Returns the number of keys deleted
  Future<int> delete(List<String> keys) async {
    _ensureConnected();
    await _protocol!.sendCommand(['DEL', ...keys]);
    final response = await _protocol!.readResponse();
    return int.parse(response.toString());
  }

  /// Checks if a key exists in Redis
  ///
  /// [key] - The key to check
  /// Returns true if key exists, false otherwise
  Future<bool> exists(String key) async {
    _ensureConnected();
    await _protocol!.sendCommand(['EXISTS', key]);
    final response = await _protocol!.readResponse();
    return int.parse(response.toString()) == 1;
  }

  /// Sets a key with expiration time
  ///
  /// [key] - The key to set
  /// [value] - The value to set
  /// [seconds] - Expiration time in seconds
  /// Returns 'OK' on success
  Future<String> setex(String key, String value, int seconds) async {
    _ensureConnected();
    await _protocol!.sendCommand(['SETEX', key, seconds.toString(), value]);
    final response = await _protocol!.readResponse();
    return response.toString();
  }

  /// Gets the time to live of a key in seconds
  ///
  /// [key] - The key to check
  /// Returns TTL in seconds, -1 if key exists but has no expiration, -2 if key doesn't exist
  Future<int> ttl(String key) async {
    _ensureConnected();
    await _protocol!.sendCommand(['TTL', key]);
    final response = await _protocol!.readResponse();
    return int.parse(response.toString());
  }

  /// Increments the integer value of a key by 1
  ///
  /// [key] - The key to increment
  /// Returns the new value after increment
  Future<int> incr(String key) async {
    _ensureConnected();
    await _protocol!.sendCommand(['INCR', key]);
    final response = await _protocol!.readResponse();
    return int.parse(response.toString());
  }

  /// Decrements the integer value of a key by 1
  ///
  /// [key] - The key to decrement
  /// Returns the new value after decrement
  Future<int> decr(String key) async {
    _ensureConnected();
    await _protocol!.sendCommand(['DECR', key]);
    final response = await _protocol!.readResponse();
    return int.parse(response.toString());
  }

  /// Gets all keys matching a pattern
  ///
  /// [pattern] - The pattern to match (e.g., 'user:*')
  /// Returns list of matching keys
  Future<List<String>> keys(String pattern) async {
    _ensureConnected();
    await _protocol!.sendCommand(['KEYS', pattern]);
    final response = await _protocol!.readResponse();
    if (response is List) {
      return response.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Ensures the client is connected before performing operations
  void _ensureConnected() {
    if (!isConnected) {
      throw RedisException('Not connected to Redis. Call connect() first.');
    }
  }

  /// Sends multiple commands in a pipeline and returns list of responses.
  /// Each inner list represents a command parts: ['SET', 'key', 'value'].
  Future<List<dynamic>> pipeline(List<List<String>> commands) async {
    _ensureConnected();
    for (final cmd in commands) {
      await _protocol!.sendCommand(cmd);
    }
    final results = <dynamic>[];
    for (int i = 0; i < commands.length; i++) {
      results.add(await _protocol!.readResponse());
    }
    return results;
  }
}
