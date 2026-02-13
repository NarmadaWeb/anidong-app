import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';

void main() {
  group('Anichin Scraping Logic', () {
    test('extracts clean title when h2 exists (Home/Search scenario)', () {
      const html = '''
      <article class="bs">
        <div class="tt">
          Renegade Immortals
          <h2 itemprop="headline">Renegade Immortals Episode 123</h2>
        </div>
      </article>
      ''';
      final document = parse(html);
      final titleElement = document.querySelector('.tt');

      // Logic from ScrapingService
      final h2 = titleElement?.querySelector('h2');
      final rawTitle = h2 != null ? h2.text.trim() : titleElement?.text.trim() ?? '';

      expect(rawTitle, 'Renegade Immortals Episode 123');

      final showTitle = rawTitle.split(' Episode')[0].split(' Ep ')[0];
      expect(showTitle, 'Renegade Immortals');
    });

    test('falls back to text when h2 is missing (Schedule/Other scenario)', () {
      const html = '''
      <div class="tt">
        Renegade Immortals
      </div>
      ''';
      final document = parse(html);
      final titleElement = document.querySelector('.tt');

      // Logic from ScrapingService
      final h2 = titleElement?.querySelector('h2');
      final rawTitle = h2 != null ? h2.text.trim() : titleElement?.text.trim() ?? '';

      expect(rawTitle, 'Renegade Immortals');
    });

    test('Search scenario: Show result (no Episode text)', () {
       const html = '''
        <div class="tt">
          Perfect World
          <h2 itemprop="headline">Perfect World</h2>
        </div>
       ''';
       final document = parse(html);
       final titleElement = document.querySelector('.tt');

       final h2 = titleElement?.querySelector('h2');
       final title = h2 != null ? h2.text.trim() : titleElement?.text.trim() ?? '';

       expect(title, 'Perfect World');

       final cleanTitle = title.split(' Episode')[0].split(' Ep ')[0];
       expect(cleanTitle, 'Perfect World');
    });
  });
}
