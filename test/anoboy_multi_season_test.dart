
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';

void main() {
  const anoboyHtml = '''
<html>
<body>
<div class="entry-content">
  <table>
    <tbody>
      <tr>
        <th scope="row">Semua Episode</th>
        <td><a href="/2023/04/jigokuraku-season-1-2/">Jigokuraku Season 2</a><br></td>
      </tr>
      <tr><th scope="row">Studio</th><td>MAPPA</td></tr>
    </tbody>
  </table>

  <div class="singlelink">
    <ul class="lcp_catlist" id="lcp_instance_0">
      <li><a href="https://ww1.anoboy.boo/2026/02/jigokuraku-season-2-episode-6/">Jigokuraku Season 2 Episode 6</a></li>
      <li><a href="https://ww1.anoboy.boo/2026/02/jigokuraku-season-2-episode-5/">Jigokuraku Season 2 Episode 5</a></li>
      <li><a href="https://ww1.anoboy.boo/2026/02/jigokuraku-season-2-episode-1/">Jigokuraku Season 2 Episode 1</a></li>
    </ul>
  </div>

  <div class="singlelink">
    <ul class="lcp_catlist" id="lcp_instance_1">
      <li><a href="https://ww1.anoboy.boo/2023/07/jigokuraku-episode-13-tamat/">Jigokuraku Episode 13 Tamat</a></li>
      <li><a href="https://ww1.anoboy.boo/2023/06/jigokuraku-episode-1/">Jigokuraku Episode 1</a></li>
    </ul>
  </div>
</div>
</body>
</html>
''';

  test('Anoboy: Parses multiple seasons and respects order/sorting', () {
    final service = ScrapingService();
    final document = parse(anoboyHtml);
    final show = Show(id: 1, title: 'Jigokuraku', type: 'anime', status: 'ongoing', genres: []);

    final result = service.parseAnoboyShowDetailsFromDoc(document, show);

    expect(result.episodes, isNotNull);
    final episodes = result.episodes!;

    expect(episodes.length, 5);

    // Verify Sort Order:
    // Should be Season 0 (or null) then Season 2.
    // "Jigokuraku Episode 1" -> Season 0/1 (implicit)
    // "Jigokuraku Season 2 Episode 1" -> Season 2

    // Expected order:
    // Episode 1 (S0)
    // Episode 13 (S0)
    // Season 2 Episode 1 (S2)
    // Season 2 Episode 5 (S2)
    // Season 2 Episode 6 (S2)

    expect(episodes[0].title, contains('Episode 1')); // Implicit Season 1/0
    expect(episodes[1].title, contains('Episode 13'));
    expect(episodes[2].title, contains('Season 2 Episode 1'));
    expect(episodes[3].title, contains('Season 2 Episode 5'));
    expect(episodes[4].title, contains('Season 2 Episode 6'));
  });

  test('Anoboy: Extracts "Semua Episode" link correctly from table', () {
    // Verifying the logic used in ScrapingService for selector correctness
    final document = parse(anoboyHtml);

    String? parentShowUrl;
    final rows = document.querySelectorAll('.entry-content table tr, .post-body table tr');
    for (var row in rows) {
       final th = row.querySelector('th');
       if (th != null && th.text.toLowerCase().contains('semua episode')) {
          parentShowUrl = row.querySelector('td a')?.attributes['href'];
          break;
       }
    }

    expect(parentShowUrl, '/2023/04/jigokuraku-season-1-2/');
  });
}
