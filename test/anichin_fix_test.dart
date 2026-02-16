import 'package:flutter_test/flutter_test.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:html/parser.dart' show parse;

void main() {
  group('Anichin Scraping Logic', () {
    final service = ScrapingService();

    test('findAnichinShowUrl extracts URL from breadcrumbs', () {
      final html = '''
        <div class="breadcrumb">
          <a href="https://anichin.asia/">Home</a>
          <a href="https://anichin.asia/donghua/soul-land/">Soul Land</a>
          <span>Episode 1</span>
        </div>
      ''';
      final doc = parse(html);
      expect(service.findAnichinShowUrl(doc), 'https://anichin.asia/donghua/soul-land/');
    });

    test('findAnichinShowUrl extracts URL from "Semua Episode" link', () {
      final html = '''
        <div>
          <a href="https://anichin.asia/donghua/battle-through-the-heavens/">Semua Episode</a>
        </div>
      ''';
      final doc = parse(html);
      expect(service.findAnichinShowUrl(doc), 'https://anichin.asia/donghua/battle-through-the-heavens/');
    });

    test('parseAnichinShowDetailsFromDoc extracts thumbnails from eplister', () {
      final html = '''
        <html>
        <body>
          <div class="eplister">
            <ul>
              <li>
                <a href="https://anichin.asia/soul-land-episode-1/">
                  <div class="epl-num">Ep 1</div>
                  <div class="epl-title">Episode 1</div>
                  <div class="epl-img"><img src="https://anichin.asia/wp-content/uploads/2023/01/sl-ep-1.jpg" /></div>
                </a>
              </li>
            </ul>
          </div>
        </body>
        </html>
      ''';
      final doc = parse(html);
      final show = Show(id: 1, title: 'Test', type: 'donghua', status: 'ongoing', genres: []);
      final result = service.parseAnichinShowDetailsFromDoc(doc, show);

      expect(result.episodes, isNotNull);
      expect(result.episodes!.length, 1);
      expect(result.episodes!.first.thumbnailUrl, 'https://anichin.asia/wp-content/uploads/2023/01/sl-ep-1.jpg');
    });

    test('parseAnichinShowDetailsFromDoc extracts thumbnails from lstep', () {
      final html = '''
        <html>
        <body>
          <div class="lstep">
            <ul>
              <li>
                <a href="https://anichin.asia/btth-episode-1/">
                  <div class="epl-num">Ep 1</div>
                  <div class="epl-title">Episode 1</div>
                  <div class="epl-img"><img src="https://anichin.asia/wp-content/uploads/2023/01/btth-ep-1.jpg" /></div>
                </a>
              </li>
            </ul>
          </div>
        </body>
        </html>
      ''';
      final doc = parse(html);
      final show = Show(id: 2, title: 'Test 2', type: 'donghua', status: 'ongoing', genres: []);
      final result = service.parseAnichinShowDetailsFromDoc(doc, show);

      expect(result.episodes, isNotNull);
      expect(result.episodes!.length, 1);
      expect(result.episodes!.first.thumbnailUrl, 'https://anichin.asia/wp-content/uploads/2023/01/btth-ep-1.jpg');
    });
  });
}
