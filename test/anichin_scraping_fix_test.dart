
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';

void main() {
  group('Anichin Scraping Fix', () {
    test('Finds Rilisan Terbaru when separated by an ad or other element', () {
      const html = '''
      <html>
      <body>
        <div class="hpage">
           <h3>Rilisan Terbaru</h3>
        </div>
        <div class="ad-banner">Buy our stuff</div>
        <div class="listupd">
           <article class="bs">
              <div class="tt">
                 <h2>Show 1 Episode 1</h2>
              </div>
              <a href="link1">Link 1</a>
           </article>
        </div>
      </body>
      </html>
      ''';

      final document = parse(html);

      // Proposed Logic
      Element? latestSection;

      // Find header with "Rilisan Terbaru"
      var headers = document.querySelectorAll('h3, h2, div');

      for (var h in headers) {
         if (h.text.trim().toLowerCase().contains('rilisan terbaru')) {
             // Search siblings
             var sibling = h.nextElementSibling;
             while (sibling != null) {
                if (sibling.classes.contains('listupd')) {
                   latestSection = sibling;
                   break;
                }
                sibling = sibling.nextElementSibling;
             }

             // Search parent's siblings if not found
             if (latestSection == null && h.parent != null) {
                 var parentSibling = h.parent!.nextElementSibling;
                 while (parentSibling != null) {
                    if (parentSibling.classes.contains('listupd')) {
                       latestSection = parentSibling;
                       break;
                    }
                    parentSibling = parentSibling.nextElementSibling;
                 }
             }
         }
         if (latestSection != null) break;
      }

      expect(latestSection, isNotNull);
      expect(latestSection?.querySelectorAll('.bs').length, 1);
    });
  });
}
