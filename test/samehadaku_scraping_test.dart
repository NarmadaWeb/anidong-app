import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:anidong/data/services/scraping_service.dart';
import 'package:anidong/data/models/show_model.dart';

void main() {
  group('Samehadaku Scraping Logic', () {
    final service = ScrapingService();

    test('parseSamehadakuShowDetailsFromDoc extracts metadata correctly', () {
      const html = '''
        <html>
          <body>
            <div class="infox">
              <img src="https://example.com/cover.jpg" />
              <div class="spe">
                <span><b>Studio</b> MAPPA </span>
                <span><b>Duration</b> 24 min </span>
                <span><b>Source</b> Manga </span>
              </div>
            </div>
            <div class="rating">
               <span>8.5</span>
            </div>
            <div class="genre-info">
               <a href="#">Action</a>
               <a href="#">Drama</a>
            </div>
            <div class="desc">
               <p>This is a great anime.</p>
            </div>
            <div class="lstepsiode">
               <ul>
                 <li>
                   <div class="epsright"><span class="eps"><a href="#">2</a></span></div>
                   <div class="epsleft"><span class="lchx"><a href="https://example.com/ep2">Episode 2</a></span></div>
                 </li>
                 <li>
                   <div class="epsright"><span class="eps"><a href="#">1</a></span></div>
                   <div class="epsleft"><span class="lchx"><a href="https://example.com/ep1">Episode 1</a></span></div>
                 </li>
               </ul>
            </div>
          </body>
        </html>
      ''';

      final document = parse(html);
      final show = Show(
        id: 1,
        title: 'Test Show',
        type: 'anime',
        status: 'ongoing',
        genres: [],
      );

      final result = service.parseSamehadakuShowDetailsFromDoc(document, show);

      expect(result.rating, 8.5);
      expect(result.studio, 'MAPPA');
      expect(result.duration, '24 min');
      expect(result.source, 'Manga');
      expect(result.synopsis, 'This is a great anime.');
      expect(result.coverImageUrl, 'https://example.com/cover.jpg');
      expect(result.genres?.length, 2);
      expect(result.genres?.first.name, 'Action');
      expect(result.episodes?.length, 2);
      expect(result.episodes?.first.episodeNumber, 1); // Sorted
    });

    test('findSamehadakuParentShowUrl extracts parent url', () {
      const html = '''
        <html>
          <body>
             <div class="spe">
               <span><a href="https://v1.samehadaku.how/anime/test-show/">Info</a></span>
             </div>
          </body>
        </html>
      ''';
      final document = parse(html);
      final url = service.findSamehadakuParentShowUrl(document);
      expect(url, 'https://v1.samehadaku.how/anime/test-show/');
    });

    test('findSamehadakuNavigationLinks extracts prev and next URLs', () {
      const html = '''
        <html>
          <body>
             <div class="naveps">
                <a href="/prev-ep/"><i class="fa-chevron-left"></i></a>
                <a href="/next-ep/"><i class="fa-chevron-right"></i></a>
             </div>
          </body>
        </html>
      ''';
      final document = parse(html);
      final links = service.findSamehadakuNavigationLinks(document);
      expect(links['prev'], 'https://v1.samehadaku.how/prev-ep/');
      expect(links['next'], 'https://v1.samehadaku.how/next-ep/');
    });
  });
}
