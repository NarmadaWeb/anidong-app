import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';

class DelegateHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final Stream<List<int>> _stream;
  final int _statusCode;

  DelegateHttpClientResponse(List<int> bytes, this._statusCode)
      : _stream = Stream.value(bytes);

  @override
  int get statusCode => _statusCode;

  @override
  int get contentLength => -1;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Future<Socket> detachSocket() async => throw UnimplementedError();

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) async => this;

  @override
  List<RedirectInfo> get redirects => [];

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => [];
}

class MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  List<String>? operator [](String name) => [];
  @override
  String? value(String name) => null;
  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  final String html;
  final bool matches;

  MockHttpClientRequest(this.html, this.matches);

  @override
  Future<HttpClientResponse> close() async {
    return DelegateHttpClientResponse(
      matches ? utf8.encode(html) : [],
      matches ? 200 : 404
    );
  }

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  void add(List<int> data) {}

  @override
  void write(Object? object) {}

  @override
  set followRedirects(bool value) {}

  @override
  set maxRedirects(int value) {}

  @override
  set persistentConnection(bool value) {}

  @override
  set contentLength(int value) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
}

class MockHttpClient extends Fake implements HttpClient {
  final String html;
  final String urlToMatch;

  MockHttpClient(this.html, this.urlToMatch);

  @override
  bool get autoUncompress => true;

  @override
  set autoUncompress(bool value) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest(html, url.toString() == urlToMatch);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
     return MockHttpClientRequest(html, url.toString() == urlToMatch);
  }

  @override
  void close({bool force = false}) {}
}

class MockHttpOverrides extends HttpOverrides {
  final String html;
  final String urlToMatch;

  MockHttpOverrides(this.html, this.urlToMatch);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient(html, urlToMatch);
  }
}

void main() {
  group('Anichin Recursion Bug', () {
    test('Prevents infinite recursion when target episode URL matches current URL', () async {
      const url = 'https://anichin.asia/episode-123/';
      const html = '''
      <html>
        <head><title>Episode 123</title></head>
        <body>
          <div class="eplister">
            <ul>
              <li>
                <a href="$url">
                  <div class="epl-num">123</div>
                  <div class="epl-title">Episode 123</div>
                </a>
              </li>
            </ul>
          </div>
        </body>
      </html>
      ''';

      HttpOverrides.global = MockHttpOverrides(html, url);

      final service = ScrapingService();
      final episode = Episode(
        id: 1,
        showId: 100,
        episodeNumber: 123,
        title: 'Episode 123',
        videoUrl: '',
        originalUrl: url,
        show: Show(id: 100, title: 'Show 1', type: 'donghua', status: 'ongoing', genres: []),
      );

      try {
        await service.getAnichinEpisodeDetails(episode).timeout(
          const Duration(seconds: 2),
          onTimeout: () {
             throw TimeoutException('Timed out - Infinite recursion detected!');
          }
        );
      } on TimeoutException catch (e) {
        fail(e.message!);
      } catch (e) {
        // Ok
      }
    });
  });
}
