import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Mocks
class MockHttpOverrides extends HttpOverrides {
  final String? showPageHtml;
  final String? episodePageHtml;

  MockHttpOverrides({this.showPageHtml, this.episodePageHtml});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient(showPageHtml: showPageHtml, episodePageHtml: episodePageHtml);
  }
}

class MockHttpClient extends Fake implements HttpClient {
  final String? showPageHtml;
  final String? episodePageHtml;

  MockHttpClient({this.showPageHtml, this.episodePageHtml});

  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest(url, showPageHtml, episodePageHtml);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
     return MockHttpClientRequest(url, showPageHtml, episodePageHtml);
  }

  @override
  void close({bool force = false}) {}
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  final Uri url;
  final String? showPageHtml;
  final String? episodePageHtml;

  MockHttpClientRequest(this.url, this.showPageHtml, this.episodePageHtml);

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(url, showPageHtml, episodePageHtml);
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
  Future<HttpClientResponse> get done => Future.value(MockHttpClientResponse(url, showPageHtml, episodePageHtml));

  @override
  Future<void> flush() async {}

  // Implement missing members that http package might touch
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
  final String? showPageHtml;
  final String? episodePageHtml;

  MockHttpClientResponse(this.url, this.showPageHtml, this.episodePageHtml);

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
  bool get persistentConnection => true; // Implemented this

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
    if (url.toString().contains('hikuidori')) {
      return showPageHtml ?? '';
    } else if (url.toString().contains('hell-mode')) {
      return episodePageHtml ?? '';
    }
    return '';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Anoboy Scraping Tests', () {
    late ScrapingService service;

    const showPageHtml = '''
      <html>
        <body>
          <div class="entry-content">
             <h3>Episode List</h3>
             <a href="https://ww1.anoboy.boo/2026/02/hikuidori-ushuu-boro-tobi-gumi-episode-4/">Hikuidori: Ushuu Boro Tobi-gumi Episode 4</a>
             <a href="https://ww1.anoboy.boo/2026/01/hikuidori-ushuu-boro-tobi-gumi-episode-3/">Hikuidori: Ushuu Boro Tobi-gumi Episode 3</a>
          </div>
        </body>
      </html>
    ''';

    const episodePageHtml = '''
      <html>
        <head>
           <title>Hell Mode: Yarikomizuki no Gamer Episode 6 Subtitle Indonesia</title>
        </head>
        <body>
           <div class="anime">
              <span>Home</span> > <span>Anime</span> > <span>Hell Mode</span> > <span>Episode 6</span>
           </div>
           <div class="entry-content">
              <iframe src="https://video.com/embed"></iframe>
              <div class="naveps">
                 <a href="https://ww1.anoboy.boo/2026/02/hell-mode-yarikomizuki-no-gamer-episode-5/">Hell Mode: Yarikomizuki no Gamer Episode 5</a>
                 <!-- No next link -->
              </div>
           </div>
        </body>
      </html>
    ''';

    setUp(() {
      HttpOverrides.global = MockHttpOverrides(
        showPageHtml: showPageHtml,
        episodePageHtml: episodePageHtml,
      );
      service = ScrapingService();
    });

    tearDown(() {
      HttpOverrides.global = null;
    });

    test('getAnoboyEpisodeDetails should extract episodes from Show Page', () async {
      final episode = Episode(
        id: 1,
        showId: 100,
        episodeNumber: 1,
        title: 'Test Show',
        videoUrl: '',
        originalUrl: 'https://ww1.anoboy.boo/2026/01/hikuidori-ushuu-boro-tobi-gumi/',
      );

      final result = await service.getAnoboyEpisodeDetails(episode);

      // Verify episodes were parsed
      expect(result.show, isNotNull);
      expect(result.show!.episodes, isNotNull);
      // The logic sorts episodes.
      expect(result.show!.episodes!.length, 2);
      expect(result.show!.episodes!.map((e) => e.episodeNumber).toList(), containsAll([3, 4]));
    });

    test('getAnoboyEpisodeDetails should extract episode number from Title if input is 0', () async {
      // Input episode has 0
      final episode = Episode(
        id: 2,
        showId: 200,
        episodeNumber: 0,
        title: 'Hell Mode',
        videoUrl: '',
        originalUrl: 'https://ww1.anoboy.boo/2026/02/hell-mode-yarikomizuki-no-gamer-episode-6/',
      );

      final result = await service.getAnoboyEpisodeDetails(episode);

      // Verify extracted number
      expect(result.episodeNumber, 6);

      // Verify Prev link
      expect(result.prevEpisodeUrl, 'https://ww1.anoboy.boo/2026/02/hell-mode-yarikomizuki-no-gamer-episode-5/');
    });
  });
}
