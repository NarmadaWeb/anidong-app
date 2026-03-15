
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';
import 'package:anidong/data/services/scraping_service.dart';

void main() {
  test('Anichin Selector Logic: Finds list by header "Rilisan Terbaru" in old structure', () {
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
    final scraper = ScrapingService();
    final latestSection = scraper.findAnichinListupd(document, ['rilisan terbaru', 'latest release']);
    expect(latestSection?.attributes['id'], 'target-list');
  });

  test('Anichin Selector Logic: Finds list by header "Latest Release" in new bixbox structure', () {
    const html = '''
<html>
<body>
  <div class="bixbox">
    <h3>Popular Today</h3>
    <div class="listupd" id="popular-list">
    </div>
  </div>
  <div class="bixbox">
    <h3>Latest Release</h3>
    <div class="listupd" id="recent-list">
    </div>
  </div>
</body>
</html>
''';

    final document = parse(html);
    final scraper = ScrapingService();
    final latestSection = scraper.findAnichinListupd(document, ['rilisan terbaru', 'latest release']);
    expect(latestSection?.attributes['id'], 'recent-list');
  });
}
