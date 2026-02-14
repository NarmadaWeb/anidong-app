// test/samehadaku_scraping_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock HTML Responses
const String mockHomeHtml = '''
<!DOCTYPE html>
<html>
<body>
  <div class="post-show">
    <ul>
      <li>
        <div class="thumb">
          <a href="https://v1.samehadaku.how/anime-1-episode-12/"><img src="https://v1.samehadaku.how/wp-content/uploads/2024/01/anime1.jpg" data-src="https://v1.samehadaku.how/wp-content/uploads/2024/01/anime1.jpg?quality=80"></a>
        </div>
        <div class="dtla">
          <span class="author"><author>Episode 12</author></span>
          <h2 class="entry-title"><a href="https://v1.samehadaku.how/anime-1-episode-12/">Anime Title 1 Episode 12</a></h2>
        </div>
      </li>
      <li>
        <div class="thumb">
          <a href="https://v1.samehadaku.how/anime-2-episode-5/"><img src="https://v1.samehadaku.how/wp-content/uploads/2024/01/anime2.jpg"></a>
        </div>
        <div class="dtla">
          <span class="author"><author>Ep 5</author></span>
          <h2 class="entry-title"><a href="https://v1.samehadaku.how/anime-2-episode-5/">Anime Title 2 Episode 5</a></h2>
        </div>
      </li>
    </ul>
  </div>
</body>
</html>
''';

const String mockMoviesHtml = '''
<!DOCTYPE html>
<html>
<body>
  <div class="animpost">
    <div class="animposx">
      <a href="https://v1.samehadaku.how/anime/movie-1/" title="Movie Title 1">
        <div class="content-thumb">
          <img src="https://v1.samehadaku.how/movie1.jpg" data-lazy-src="https://v1.samehadaku.how/movie1.jpg">
          <div class="score">8.5</div>
        </div>
        <div class="data">
          <div class="title"><h4>Movie Title 1</h4></div>
          <div class="type">Movie</div>
        </div>
      </a>
    </div>
  </div>
  <div class="animpost">
     <div class="animposx">
      <a href="https://v1.samehadaku.how/anime/anime-series/" title="Anime Series">
        <div class="content-thumb"><img src="https://v1.samehadaku.how/series.jpg"></div>
        <div class="data">
          <div class="title"><h4>Anime Series</h4></div>
          <div class="type">TV</div>
        </div>
      </a>
    </div>
  </div>
</body>
</html>
''';

const String mockSearchHtml = '''
<!DOCTYPE html>
<html>
<body>
  <div class="animpost">
    <div class="animposx">
      <a href="https://v1.samehadaku.how/anime/search-result-1/" title="Search Result 1">
        <img src="https://v1.samehadaku.how/result1.jpg">
        <div class="title"><h4>Search Result 1</h4></div>
        <div class="type">TV</div>
        <div class="score">7.9</div>
      </a>
    </div>
  </div>
</body>
</html>
''';

const String mockShowDetailsHtml = '''
<!DOCTYPE html>
<html>
<body>
  <div class="infoanime">
    <div class="thumb"><img src="https://v1.samehadaku.how/cover.jpg"></div>
    <div class="infox">
      <h1 class="entry-title">Anime Full Title</h1>
      <div class="desc">Synopsis of the anime.</div>
      <div class="genre-info"><a href="#">Action</a><a href="#">Adventure</a></div>
    </div>
  </div>
  <div class="lstepsiode listeps">
    <ul>
      <li>
        <div class="epsleft">
          <span class="lchx"><a href="https://v1.samehadaku.how/anime-full-episode-1/">Title Episode 1</a></span>
          <span class="date">January 1, 2024</span>
        </div>
        <div class="epsright">
          <span class="eps"><a href="https://v1.samehadaku.how/anime-full-episode-1/">Episode 1</a></span>
        </div>
      </li>
       <li>
        <div class="epsleft">
          <span class="lchx"><a href="https://v1.samehadaku.how/anime-full-episode-2/">Title Episode 2</a></span>
          <span class="date">January 8, 2024</span>
        </div>
        <div class="epsright">
          <span class="eps"><a href="https://v1.samehadaku.how/anime-full-episode-2/">Episode 2</a></span>
        </div>
      </li>
    </ul>
  </div>
</body>
</html>
''';

const String mockEpisodeDetailsHtml = '''
<!DOCTYPE html>
<html>
<body>
  <div class="player-embed">
    <iframe src="https://video.com/embed/123" scrolling="no" frameborder="0" allowfullscreen="true"></iframe>
  </div>
  <div class="download-eps">
    <ul>
      <li>
        <strong>360p</strong>
        <a href="https://dl.com/360">Zippyshare</a>
      </li>
      <li>
        <strong>720p</strong>
        <a href="https://dl.com/720">GDrive</a>
      </li>
    </ul>
  </div>
  <div class="naveps">
    <a href="https://v1.samehadaku.how/anime-full-episode-1/" rel="prev">Previous</a>
    <a href="https://v1.samehadaku.how/anime-full-episode-3/" rel="next">Next</a>
  </div>
  <div class="breadcrumbs">
     <a href="https://v1.samehadaku.how/">Home</a>
     <a href="https://v1.samehadaku.how/anime/anime-full-title/">Anime Full Title</a>
     <a href="#">Episode 2</a>
  </div>
</body>
</html>
''';

// --- Mocks without Mockito ---

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest(url);
  }

  // Also needed for some http client implementations
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
     return MockHttpClientRequest(url);
  }

  @override
  bool get autoUncompress => true;
  @override
  set autoUncompress(bool value) {}
}

class MockHttpClientRequest implements HttpClientRequest {
  final Uri url;

  MockHttpClientRequest(this.url);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #addStream) {
      return Future.value();
    }
    return null;
  }

  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  int contentLength = -1;
  @override
  bool persistentConnection = true;

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(url);
  }
}

class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class MockHttpClientResponse implements HttpClientResponse {
  final Uri url;

  MockHttpClientResponse(this.url);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  int get statusCode => 200;

  @override
  int get contentLength => -1;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  String get reasonPhrase => 'OK';

  @override
  List<RedirectInfo> get redirects => [];

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  // This is the crucial method used by http package (via utf8.decoder.bind)
  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
     return Stream.value(utf8.encode(_getBody())).cast<List<int>>().transform(streamTransformer);
  }

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(utf8.encode(_getBody())).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  String _getBody() {
    final u = url.toString();
    if (u.contains('anime-movie')) {
      return mockMoviesHtml;
    } else if (u.contains('?s=')) {
      return mockSearchHtml;
    } else if (u.contains('/anime/')) {
      return mockShowDetailsHtml;
    } else if (u.contains('episode-2') || u.contains('embed')) { // Assuming we navigate to episode 2 in mock or recursive call uses embed link?
      // Recursive call for details checks if targetUrl != url.
      return mockEpisodeDetailsHtml;
    } else if (u.contains('episode-1')) {
       // Episode 1 details
       return mockEpisodeDetailsHtml.replaceAll('Episode 2', 'Episode 1').replaceAll('episode-3', 'episode-2').replaceAll('prev', 'next');
    } else {
      return mockHomeHtml; // Default to home
    }
  }
}

void main() {
  HttpOverrides.global = MockHttpOverrides();
  final service = ScrapingService();

  group('Samehadaku Scraping Tests', () {
    test('getSamehadakuLatestEpisodes parses correctly', () async {
      final episodes = await service.getSamehadakuLatestEpisodes();
      expect(episodes.length, 2);
      expect(episodes[0].title, 'Anime Title 1 Episode 12');
      expect(episodes[0].episodeNumber, 12);
      expect(episodes[0].thumbnailUrl, 'https://v1.samehadaku.how/wp-content/uploads/2024/01/anime1.jpg');

      expect(episodes[1].title, 'Anime Title 2 Episode 5');
      expect(episodes[1].episodeNumber, 5);
    });

    test('getSamehadakuMovies parses correctly', () async {
      final movies = await service.getSamehadakuMovies();
      // Mock returns 2 items but one is TV, so we expect filter to work?
      // Wait, my implementation filters: if (!type.contains('movie') && !url.contains('movie'))
      // The mock item 2 has type "TV" and url "anime-series".
      // So it should be filtered out if logic is correct.
      expect(movies.length, 1);
      expect(movies[0].title, 'Movie Title 1');
      expect(movies[0].type, 'movie');
    });

    test('searchSamehadaku parses correctly', () async {
      final shows = await service.searchSamehadaku('query');
      expect(shows.length, 1);
      expect(shows[0].title, 'Search Result 1');
      expect(shows[0].rating, 7.9);
      // Logic defaults to 'anime' if not movie
      expect(shows[0].type, 'anime');
    });

    test('getSamehadakuEpisodeDetails parses Show Page correctly', () async {
      final episode = Episode(
        id: 1,
        showId: 1,
        episodeNumber: 1,
        title: 'Unknown',
        videoUrl: '',
        originalUrl: 'https://v1.samehadaku.how/anime/anime-full-title/',
      );

      // This should parse the show page, find the episode list, find episode 1,
      // AND recursively call getSamehadakuEpisodeDetails for episode 1 (which is an Episode URL)
      // My mock returns Episode Page HTML for "episode" URLs.

      final result = await service.getSamehadakuEpisodeDetails(episode);

      expect(result.show?.title, 'Anime Full Title');
      expect(result.show?.episodes?.length, 2);
      // If mock works, it should have fetched the iframe URL via recursion
      expect(result.iframeUrl, 'https://video.com/embed/123');
    });
  });
}
