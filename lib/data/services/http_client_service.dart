import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_proxy/http_proxy.dart';
import 'package:flutter/foundation.dart';

class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();

  factory HttpClientService() {
    return _instance;
  }

  HttpClientService._internal();

  http.Client? _client;

  Future<http.Client> get client async {
    if (_client != null) return _client!;

    if (kIsWeb) {
      _client = http.Client();
      return _client!;
    }

    // Check if we're running in a test environment with mocked HttpClient
    // If HttpOverrides.current is set, it means tests are mocking the client
    if (HttpOverrides.current != null) {
      _client = IOClient(HttpClient());
      return _client!;
    }

    // We create a custom IOClient with a configured HttpClient
    HttpClient httpClient = HttpClient();

    try {
      // Using http_proxy to automatically detect system proxy
      HttpProxy httpProxy = await HttpProxy.createHttpProxy();

      // Check if proxy was found
      if (httpProxy.host != null && httpProxy.port != null) {
        httpClient.findProxy = (uri) {
          return "PROXY ${httpProxy.host}:${httpProxy.port}";
        };
      } else {
        // Use Dart's built-in environment proxy discovery
        httpClient.findProxy = HttpClient.findProxyFromEnvironment;
      }
    } catch (e) {
      // Fallback for when plugin is missing or throws error
      debugPrint('Error getting proxy: $e');
      httpClient.findProxy = HttpClient.findProxyFromEnvironment;
    }

    _client = IOClient(httpClient);
    return _client!;
  }

  @visibleForTesting
  void resetClient() {
    _client = null;
  }
}
