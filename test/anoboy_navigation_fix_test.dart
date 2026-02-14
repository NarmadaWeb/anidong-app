import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Mocks
class MockHttpOverrides extends HttpOverrides {
  final String? episodePageHtml;

  MockHttpOverrides({this.episodePageHtml});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient(episodePageHtml: episodePageHtml);
  }
}

class MockHttpClient extends Fake implements HttpClient {
  final String? episodePageHtml;

  MockHttpClient({this.episodePageHtml});

  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest(url, episodePageHtml);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
     return MockHttpClientRequest(url, episodePageHtml);
  }

  @override
  void close({bool force = false}) {}
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  final Uri url;
  final String? episodePageHtml;

  MockHttpClientRequest(this.url, this.episodePageHtml);

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(url, episodePageHtml);
  }

  @override
  void add(List<int> data) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  void write(Object? object) {}

  @override
  void writeAll(Iterable objects, [String separator = ""]) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = ""]) {}

  @override
  Future<HttpClientResponse> get done => Future.value(MockHttpClientResponse(url, episodePageHtml));

  @override
  Future<void> flush() async {}

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  Encoding encoding = utf8;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

class MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void removeAll(String name) {}

  @override
  List<String>? operator [](String name) => [];

  @override
  String? value(String name) => null;

  @override
  ContentType? contentType;

  @override
  DateTime? date;

  @override
  DateTime? expires;

  @override
  String? host;

  @override
  int? port;

  @override
  DateTime? ifModifiedSince;

  @override
  bool chunkedTransferEncoding = false;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class MockHttpClientResponse extends Fake implements HttpClientResponse {
  final Uri url;
  final String? episodePageHtml;

  MockHttpClientResponse(this.url, this.episodePageHtml);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => -1;

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => [];

  @override
  bool get persistentConnection => true;

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    return Stream.value(utf8.encode(_getBody()) as List<int>).transform(streamTransformer);
  }

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(utf8.encode(_getBody()) as List<int>).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  String _getBody() {
    return episodePageHtml ?? '';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Anoboy Navigation Fix Tests', () {
    late ScrapingService service;

    const episodePageHtml = '''
      <html>
        <head>
           <title>One Piece Episode 1000 Subtitle Indonesia</title>
        </head>
        <body>
           <div class="anime">
              <span>Home</span> > <span>Anime</span> > <span>One Piece</span> > <span>Episode 1000</span>
           </div>
           <div class="entry-content">
              <iframe src="https://video.com/embed"></iframe>
              <div class="naveps">
                 <a href="https://ww1.anoboy.boo/one-piece-episode-999/">Episode Sebelumnya</a>
                 <!-- This deceptive next link simulates a broken or placeholder link found by scraper -->
                 <a href="https://ww1.anoboy.boo/one-piece-episode-1001-preview/">Next Episode</a>
              </div>

              <!-- Episode List showing 1000 is the latest/last -->
              <div class="episodelist">
                 <ul>
                    <li><a href="https://ww1.anoboy.boo/one-piece-episode-998/" title="One Piece Episode 998">Episode 998</a></li>
                    <li><a href="https://ww1.anoboy.boo/one-piece-episode-999/" title="One Piece Episode 999">Episode 999</a></li>
                    <li><a href="https://ww1.anoboy.boo/one-piece-episode-1000/" title="One Piece Episode 1000">Episode 1000</a></li>
                 </ul>
              </div>
           </div>
        </body>
      </html>
    ''';

    setUp(() {
      HttpOverrides.global = MockHttpOverrides(
        episodePageHtml: episodePageHtml,
      );
      service = ScrapingService();
    });

    tearDown(() {
      HttpOverrides.global = null;
    });

    test('getAnoboyEpisodeDetails should set nextEpisodeUrl to NULL for the latest episode even if scraper finds a next link', () async {
      final episode = Episode(
        id: 1000,
        showId: 9999,
        episodeNumber: 1000,
        title: 'One Piece Episode 1000',
        videoUrl: '',
        originalUrl: 'https://ww1.anoboy.boo/one-piece-episode-1000/',
      );

      final result = await service.getAnoboyEpisodeDetails(episode);

      expect(result.episodeNumber, 1000);

      // We expect the list logic to override the scraped "Next Episode" link because 1000 is the last one in the list.
      // Currently, this fails because the scraper picks up "Next Episode" link.
      expect(result.nextEpisodeUrl, isNull, reason: 'Next episode URL should be null for the latest episode');
    });
  });
}
