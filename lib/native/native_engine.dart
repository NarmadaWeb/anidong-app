import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Simple CancellationToken to allow cancelling pending operations
class CancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

/// A simplified Dart interface for the Go Native Engine.
class NativeEngine {
  static const MethodChannel _channel = MethodChannel('com.anidong.app/native_engine');

  static final NativeEngine _instance = NativeEngine._internal();
  factory NativeEngine() => _instance;
  NativeEngine._internal();

  /// Initialize the native engine with a path for the persistent cache.
  Future<void> initialize(String dbPath) async {
    try {
      await _channel.invokeMethod('initialize', {'dbPath': dbPath});
    } on PlatformException catch (e) {
      debugPrint("Failed to initialize NativeEngine: ${e.message}");
    }
  }

  /// GetOrCompute handles heavy tasks with multi-layer caching.
  Future<Uint8List> getOrCompute({
    required String key,
    required int ttlSeconds,
    required String taskType,
    required Uint8List input,
    CancellationToken? token,
  }) async {
    if (token?.isCancelled ?? false) {
      throw Exception("Operation cancelled before starting");
    }

    try {
      final result = await _channel.invokeMethod('getOrCompute', {
        'key': key,
        'ttlSeconds': ttlSeconds,
        'taskType': taskType,
        'input': input,
      });

      if (token?.isCancelled ?? false) {
        throw Exception("Operation cancelled after completion");
      }

      return result as Uint8List;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? "Unknown error");
    }
  }

  /// Specialized method for JSON processing
  Future<Uint8List> processJson(String key, Uint8List jsonInput, {CancellationToken? token}) {
    return getOrCompute(
      key: key,
      ttlSeconds: 3600,
      taskType: 'json',
      input: jsonInput,
      token: token,
    );
  }

  /// Specialized method for data compression
  Future<Uint8List> compress(String key, Uint8List data, {CancellationToken? token}) {
    return getOrCompute(
      key: key,
      ttlSeconds: 86400,
      taskType: 'compress',
      input: data,
      token: token,
    );
  }

  /// Flush the cache
  Future<void> flushCache() async {
    await _channel.invokeMethod('flushCache');
  }

  /// Get cache statistics
  Future<String> getStats() async {
    final String? stats = await _channel.invokeMethod('getStats');
    return stats ?? "No stats available";
  }

  /// Close the engine
  Future<void> dispose() async {
    await _channel.invokeMethod('dispose');
  }
}
