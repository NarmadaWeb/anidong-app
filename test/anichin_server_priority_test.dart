import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';
import 'package:anidong/data/services/scraping_service.dart';

void main() {
  group('Anichin Server Priority', () {
    test('Prioritizes Dailymotion, Rumble, OK.ru, GDrive, VIP', () {
      const html = '''
      <html>
        <body>
          <iframe src="https://anichin.stream/v/default"></iframe>
          <div class="mirror">
            <select>
              <option value="https://vip1.com">VIP 1</option>
              <option value="https://rumble.com/v123">Rumble</option>
              <option value="https://dailymotion.com/video/x123">Dailymotion</option>
              <option value="https://ok.ru/video/123">OK.ru</option>
              <option value="https://gdrive1.com/file">Gdrive 1</option>
              <option value="https://other.com">Other Server</option>
            </select>
          </div>
        </body>
      </html>
      ''';
      final document = parse(html);
      final service = ScrapingService();

      final servers = service.extractAnichinServers(document);

      expect(servers.length, greaterThanOrEqualTo(6));
      expect(servers[0]['name'], contains('Dailymotion'));
      expect(servers[1]['name'], contains('Rumble'));
      expect(servers[2]['name'], contains('OK.ru'));
      expect(servers[3]['name'], contains('Gdrive 1'));
      expect(servers[4]['name'], contains('VIP 1'));
    });

    test('Falls back to default iframe if no mirrors', () {
      const html = '''
      <html>
        <body>
          <iframe src="https://anichin.stream/v/default"></iframe>
        </body>
      </html>
      ''';
      final document = parse(html);
      final service = ScrapingService();

      final servers = service.extractAnichinServers(document);

      expect(servers.length, 1);
      expect(servers[0]['name'], 'Primary Server');
      expect(servers[0]['url'], 'https://anichin.stream/v/default');
    });
  });
}
