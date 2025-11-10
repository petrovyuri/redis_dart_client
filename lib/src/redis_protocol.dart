import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:redis_dart_client/src/redis_exception.dart';

/// Handles Redis protocol (RESP) communication
class RedisProtocol {
  /// Creates a new RedisProtocol instance
  ///
  /// [_socket] - The socket to use for communication
  /// [responseTimeout] - Optional timeout for reading responses
  RedisProtocol(this._socket, {this.responseTimeout}) {
    _setupStreamListener();
  }

  final Socket _socket;
  final List<int> _readBuffer = [];
  Completer<void>? _dataAvailableCompleter;
  final Duration? responseTimeout;

  /// Sets up stream listener to buffer incoming data
  void _setupStreamListener() {
    _socket.listen(
      (data) {
        _readBuffer.addAll(data);
        // Notify waiting operations that data is available
        _dataAvailableCompleter?.complete();
        _dataAvailableCompleter = null;
      },
      onError: (error) {
        _dataAvailableCompleter?.completeError(error);
        _dataAvailableCompleter = null;
      },
      onDone: () {
        _dataAvailableCompleter?.completeError(
          RedisException('Connection closed'),
        );
        _dataAvailableCompleter = null;
      },
    );
  }

  /// Sends a command to Redis server.
  /// Builds and sends a RESP array command.
  /// Format: `*<N>\r\n$<len(arg1)>\r\narg1\r\n...$<len(argN)>\r\nargN\r\n`
  Future<void> sendCommand(List<String> command) async {
    final sb = StringBuffer()..write('*${command.length}\r\n');
    for (final arg in command) {
      final bytes = utf8.encode(arg);
      sb
        ..write('\$${bytes.length}\r\n')
        ..write(arg)
        ..write('\r\n');
    }
    _socket.add(utf8.encode(sb.toString()));
    await _socket.flush();
  }

  /// Reads a response from Redis server
  Future<dynamic> readResponse() async {
    final line = await _readLine();
    if (line.isEmpty) {
      throw RedisException('Empty response from Redis');
    }

    final firstChar = line[0];
    switch (firstChar) {
      case '+': // Simple string
        return line.substring(1).trim();
      case '-': // Error
        throw RedisException(line.substring(1).trim());
      case ':': // Integer
        return int.parse(line.substring(1).trim());
      case '\$': // Bulk string
        final length = int.parse(line.substring(1).trim());
        if (length == -1) {
          return null; // Null bulk string
        }
        final data = await _readBytes(length);
        await _readLine(); // Read trailing CRLF
        return utf8.decode(data);
      case '*': // Array
        final count = int.parse(line.substring(1).trim());
        if (count == -1) {
          return null; // Null array
        }
        final List<dynamic> result = [];
        for (int i = 0; i < count; i++) {
          result.add(await readResponse());
        }
        return result;
      default:
        throw RedisException('Unknown response type: $firstChar');
    }
  }

  /// Reads a line from the socket (until CRLF)
  Future<String> _readLine() async {
    // Wait for data if buffer is empty
    while (_readBuffer.isEmpty) {
      _dataAvailableCompleter = Completer<void>();
      final future = _dataAvailableCompleter!.future;
      if (responseTimeout != null) {
        try {
          await future.timeout(
            responseTimeout!,
            onTimeout: () {
              if (!_dataAvailableCompleter!.isCompleted) {
                _dataAvailableCompleter!.completeError(
                  RedisException(
                      'Response timeout (${responseTimeout!.inMilliseconds} ms)'),
                );
              }
            },
          );
        } catch (e) {
          if (e is RedisException) rethrow;
          throw RedisException('Timeout waiting for data: $e');
        }
      } else {
        await future;
      }
    }

    int crIndex = -1;

    // Find CR in buffer
    for (int i = 0; i < _readBuffer.length; i++) {
      if (_readBuffer[i] == 13) {
        // CR found
        crIndex = i;
        break;
      }
    }

    // If CR not found, wait for more data
    while (crIndex == -1) {
      _dataAvailableCompleter = Completer<void>();
      final future = _dataAvailableCompleter!.future;
      if (responseTimeout != null) {
        try {
          await future.timeout(
            responseTimeout!,
            onTimeout: () {
              if (!_dataAvailableCompleter!.isCompleted) {
                _dataAvailableCompleter!.completeError(
                  RedisException(
                      'Response timeout (${responseTimeout!.inMilliseconds} ms)'),
                );
              }
            },
          );
        } catch (e) {
          if (e is RedisException) rethrow;
          throw RedisException('Timeout waiting for line: $e');
        }
      } else {
        await future;
      }
      // Check again after data arrived
      for (int i = 0; i < _readBuffer.length; i++) {
        if (_readBuffer[i] == 13) {
          crIndex = i;
          break;
        }
      }
    }

    // Extract line (before CR)
    final buffer = _readBuffer.sublist(0, crIndex);
    _readBuffer.removeRange(0, crIndex + 1);

    // Remove LF if present
    if (_readBuffer.isNotEmpty && _readBuffer[0] == 10) {
      _readBuffer.removeAt(0);
    }

    return utf8.decode(buffer);
  }

  /// Reads specified number of bytes from the socket
  Future<List<int>> _readBytes(int length) async {
    // Wait for enough data
    while (_readBuffer.length < length) {
      _dataAvailableCompleter = Completer<void>();
      final future = _dataAvailableCompleter!.future;
      if (responseTimeout != null) {
        try {
          await future.timeout(
            responseTimeout!,
            onTimeout: () {
              if (!_dataAvailableCompleter!.isCompleted) {
                _dataAvailableCompleter!.completeError(
                  RedisException(
                      'Response timeout (${responseTimeout!.inMilliseconds} ms)'),
                );
              }
            },
          );
        } catch (e) {
          if (e is RedisException) rethrow;
          throw RedisException('Timeout reading bulk data: $e');
        }
      } else {
        await future;
      }
    }

    // Extract bytes
    final result = _readBuffer.sublist(0, length);
    _readBuffer.removeRange(0, length);
    return result;
  }

  /// Clears the read buffer
  void clearBuffer() {
    _readBuffer.clear();
  }
}
