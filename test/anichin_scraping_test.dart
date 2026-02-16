
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';

void main() {
  test('Anichin Selector Logic: Finds list with .epx when header is missing', () {
    const html = '''
<html>
<body>
  <div class="section">
    <h3>Popular</h3>
    <div class="listupd" id="popular-list">
        <div class="bs">
            <div class="tt"><h2>Popular Show</h2></div>
            <!-- No epx here -->
        </div>
    </div>
  </div>

  <div class="section">
    <!-- No Header here -->
    <div class="listupd" id="recent-list">
        <div class="bs">
            <div class="epx">Ep 10</div>
            <div class="tt"><h2>Recent Show</h2></div>
        </div>
    </div>
  </div>
</body>
</html>
''';

    final document = parse(html);

    // The exact logic implemented in ScrapingService
    var latestSection = document.querySelectorAll('.listupd').firstWhere(
          (e) {
            final headerText = e.previousElementSibling?.text.toLowerCase() ?? '';
            return headerText.contains('rilisan terbaru') ||
                   headerText.contains('latest') ||
                   headerText.contains('update');
          },
          orElse: () {
             try {
                return document.querySelectorAll('.listupd').firstWhere((section) {
                   return section.querySelectorAll('.bs .epx').isNotEmpty;
                });
             } catch (_) {
                final lists = document.querySelectorAll('.listupd');
                if (lists.length > 1) return lists[1];
                if (lists.isNotEmpty) return lists[0];
                throw Exception('No listupd found');
             }
          }
      );

    expect(latestSection.attributes['id'], 'recent-list');
  });

  test('Anichin Selector Logic: Finds list by header "Rilisan Terbaru"', () {
    const html = '''
<html>
<body>
  <div class="section">
    <h3>Rilisan Terbaru</h3>
    <div class="listupd" id="target-list">
        <div class="bs">
            <div class="epx">Ep 10</div>
        </div>
    </div>
  </div>
</body>
</html>
''';

    final document = parse(html);

    var latestSection = document.querySelectorAll('.listupd').firstWhere(
          (e) {
            final headerText = e.previousElementSibling?.text.toLowerCase() ?? '';
            return headerText.contains('rilisan terbaru') ||
                   headerText.contains('latest') ||
                   headerText.contains('update');
          },
          orElse: () => document.body! // Dummy fallback
      );

    expect(latestSection.attributes['id'], 'target-list');
  });
}
