import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;

void main() {
  group('Anoboy & Anichin Fixes', () {
    late ScrapingService service;

    setUp(() {
      service = ScrapingService();
    });

    test('parseAnoboyShowDetailsFromDoc handles relative episode URLs', () {
      const html = '''
        <div class="entry-content">
          <a href="/2023/10/ep-1.html" title="Episode 1">Episode 1</a>
          <a href="https://other.com/ep-2" title="Episode 2">Episode 2</a>
          <a href="/anime/ep-3" title="Episode 3">Episode 3</a>
        </div>
      ''';
      final document = parse(html);
      final show = Show(
        id: 1,
        title: 'Test Anime',
        type: 'anime',
        status: 'ongoing',
        genres: [],
        originalUrl: 'https://ww1.anoboy.boo/anime/test-anime/',
      );

      final result = service.parseAnoboyShowDetailsFromDoc(document, show);

      expect(result.episodes, isNotNull);
      expect(result.episodes!.length, 2); // Should match Ep 1 and Ep 3 (relative)

      final ep1 = result.episodes!.firstWhere((e) => e.episodeNumber == 1);
      expect(ep1.originalUrl, 'https://ww1.anoboy.boo/2023/10/ep-1.html');

      final ep3 = result.episodes!.firstWhere((e) => e.episodeNumber == 3);
      expect(ep3.originalUrl, 'https://ww1.anoboy.boo/anime/ep-3');
    });

    test('parseAnichinShowDetailsFromDoc extracts cover image, synopsis and episodes', () {
      const html = '''
        <html>
        <body>
          <div class="thumb">
            <img src="https://anichin.asia/wp-content/uploads/2023/09/Renegade-Immortal.png?resize=195,350" class="ts-post-image wp-post-image" />
          </div>
          <div class="bixbox synp">
            <div class="entry-content" itemprop="description">
              <p>Renegade Immortal (Xian Ni) Bercerita tentang anak muda...</p>
            </div>
          </div>
          <div class="eplister">
            <ul>
              <li>
                <a href="https://anichin.asia/renegade-immortal-episode-128/">
                  <div class="epl-num">128</div>
                  <div class="epl-title">Episode 128</div>
                </a>
              </li>
              <li>
                <a href="https://anichin.asia/renegade-immortal-episode-127/">
                  <div class="epl-num">127</div>
                  <div class="epl-title">Episode 127</div>
                </a>
              </li>
            </ul>
          </div>
        </body>
        </html>
      ''';
      final document = parse(html);
      final show = Show(
        id: 2,
        title: 'Renegade Immortal',
        type: 'donghua',
        status: 'ongoing',
        genres: [],
        originalUrl: 'https://anichin.asia/renegade-immortal/',
      );

      final result = service.parseAnichinShowDetailsFromDoc(document, show);

      expect(result.coverImageUrl, 'https://anichin.asia/wp-content/uploads/2023/09/Renegade-Immortal.png?resize=195,350');
      expect(result.synopsis, contains('Renegade Immortal (Xian Ni) Bercerita tentang'));
      expect(result.episodes, isNotNull);
      expect(result.episodes!.length, 2);
      expect(result.episodes!.first.episodeNumber, 128);
    });
  });
}
