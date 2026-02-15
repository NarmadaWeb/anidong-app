import 'package:flutter_test/flutter_test.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:html/parser.dart' show parse;

void main() {
  group('Anoboy Navigation Scraping', () {
    final service = ScrapingService();

    test('should identify valid next/prev buttons in navigation area', () {
      const html = '''
        <html>
        <body>
          <div class="naveps">
            <a href="/prev-ep">Episode Sebelumnya</a>
            <a href="/next-ep">Episode Selanjutnya</a>
          </div>
        </body>
        </html>
      ''';

      final document = parse(html);
      final result = service.findAnoboyNavigationLinks(document, 5, 'My Anime');

      expect(result['prev'], contains('/prev-ep'));
      expect(result['next'], contains('/next-ep'));
    });

    test('should ignore sidebar links for next episode of DIFFERENT anime', () {
      // Scenario: Watching "My Anime Episode 6".
      // Sidebar has "Other Anime Episode 7".
      // Current logic falls back to all links if .naveps is missing, or scans all links anyway.
      // Wait, if .naveps is missing, it falls back.
      // If .naveps IS present but doesn't have "Next", does it scan others?
      // The code loops through `navLinks`. If `navLinks` was populated from `.naveps`, it only checks those.
      // But if `.naveps` is missing, it checks ALL links.

      const html = '''
        <html>
        <body>
          <div class="sidebar">
            <h3>Latest Updates</h3>
            <a href="/other-anime-ep-7">Other Anime Episode 7</a>
          </div>
          <div class="content">
             <h1>My Anime Episode 6</h1>
             <!-- No Next Button here -->
          </div>
        </body>
        </html>
      ''';

      final document = parse(html);
      // The current code will fall back to document.querySelectorAll('a') because .naveps is missing.
      // And it will find "Other Anime Episode 7" matching "Episode 7" (6+1).

      final result = service.findAnoboyNavigationLinks(document, 6, 'My Anime');

      // We Expect NULL because it's a different anime.
      expect(result['next'], isNull, reason: 'Should not pick up Other Anime link');
    });

    test('should accept "Episode X" button if it is the correct anime', () {
       // Here .content matches .entry-content logic if we assume standard WP classes,
       // but my test uses generic divs. The service looks for .naveps, .entry-content.
       // Let's use .entry-content to ensure it doesn't fallback to all links,
       // ensuring the logic works when filtering IS applied.

       const html2 = '''
        <html>
        <body>
          <div class="entry-content">
             <a href="/my-anime-ep-7">Episode 7</a>
          </div>
        </body>
        </html>
      ''';

      final document = parse(html2);
      final result = service.findAnoboyNavigationLinks(document, 6, 'My Anime');

      expect(result['next'], contains('/my-anime-ep-7'));
    });
  });
}
