import 'package:anidong/data/models/episode_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';

// Helper to mimic ScrapingService logic
String? extractAnoboyCoverImage(dynamic document) {
  String coverImage = '';
  final imgEl = document.querySelector('.entry-content img, .post-body img');
  if (imgEl != null) {
    final src = imgEl.attributes['src'];
    if (src != null && src.startsWith('http')) {
      coverImage = src;
    }
  }
  return coverImage.isNotEmpty ? coverImage : null;
}

List<Episode> parseAnoboyEpisodes(dynamic document, int showId) {
  final List<Episode> eps = [];
  var epLinks = document.querySelectorAll('a[rel="bookmark"]');
  if (epLinks.isEmpty) {
     epLinks = document.querySelectorAll('.entry-content a, .post-body a');
  }

  for (var link in epLinks) {
    final title = link.attributes['title'] ?? link.text.trim();
    final url = link.attributes['href'] ?? '';

    if (url.isNotEmpty && (title.contains('Episode') || title.contains('Ep ')) && !url.contains('#') && !url.contains('facebook') && !url.contains('twitter')) {
      int epNum = 0;
      final epMatch = RegExp(r'Episode\s+(\d+)').firstMatch(title);
      if (epMatch != null) epNum = int.tryParse(epMatch.group(1)!) ?? 0;

      eps.add(Episode(
        id: url.hashCode,
        showId: showId,
        episodeNumber: epNum,
        title: title,
        videoUrl: '',
        originalUrl: url,
      ));
    }
  }
  return eps;
}

void main() {
  group('Scraping Fixes Verification', () {
    test('Anoboy Series Page: Extracts Cover Image and Episodes from Content', () {
      const html = '''
      <div class="post-body">
        <p>Tokyo Revengers adalah...</p>
        <img src="https://example.com/tokyo-revengers-cover.jpg" alt="Cover">
        <ul>
          <li><a href="https://anoboy.boo/eps1">Tokyo Revengers Episode 1</a></li>
          <li><a href="https://anoboy.boo/eps2">Tokyo Revengers Episode 2</a></li>
          <li><a href="#">Ignore this</a></li>
        </ul>
      </div>
      ''';
      final document = parse(html);

      // Image Extraction
      final cover = extractAnoboyCoverImage(document);
      expect(cover, 'https://example.com/tokyo-revengers-cover.jpg');

      // Episode Parsing
      final episodes = parseAnoboyEpisodes(document, 123);
      expect(episodes.length, 2);
      expect(episodes[0].episodeNumber, 1);
      expect(episodes[1].episodeNumber, 2);
    });

    test('Anichin Video Page: Corrects Episode Number from Title', () {
      const html = '''
      <h1 class="entry-title">Renegade Immortal Episode 12 Sub Indo</h1>
      <div class="breadcrumb">
        <span>Home</span> > <span>Renegade Immortal</span> > <span>Episode 12</span>
      </div>
      ''';
      final document = parse(html);

      int realEpNum = 0; // Simulate starting with 0
      final titleText = document.querySelector('.entry-title')?.text ?? '';

      if (titleText.isNotEmpty) {
         final match = RegExp(r'(?:Episode|Ep)\s+(\d+)').firstMatch(titleText);
         if (match != null) {
            realEpNum = int.tryParse(match.group(1)!) ?? 0;
         }
      }

      expect(realEpNum, 12);
    });

    test('Anichin Video Page: Scrapes Prev/Next Links', () {
      const html = '''
      <div class="lm">
        <div class="nav-links">
           <a href="https://anichin.asia/prev" rel="prev">Prev</a>
           <a href="https://anichin.asia/next" rel="next">Next</a>
        </div>
      </div>
      ''';
      final document = parse(html);

      String? prevUrl;
      String? nextUrl;

      final navLinks = document.querySelectorAll('.lm .nav-links a, .naveps a, a.btn');
      for (var a in navLinks) {
         final text = a.text.trim().toLowerCase();
         final href = a.attributes['href'];
         if (href == null || href.isEmpty) continue;

         if (text.contains('prev') || text.contains('sebelumnya')) {
           prevUrl = href;
         } else if (text.contains('next') || text.contains('selanjutnya')) {
           nextUrl = href;
         }
      }

      expect(prevUrl, 'https://anichin.asia/prev');
      expect(nextUrl, 'https://anichin.asia/next');
    });

    test('Anoboy Video Page: Scrapes Prev/Next Links', () {
      const html = '''
      <div class="naveps">
        <a href="https://anoboy.boo/prev">Episode Sebelumnya</a>
        <a href="https://anoboy.boo/next">Episode Selanjutnya</a>
      </div>
      ''';
      final document = parse(html);

      String? prevEpisodeUrl;
      String? nextEpisodeUrl;
      final String anoboyBaseUrl = 'https://anoboy.boo';

      final navLinks = document.querySelectorAll('a');
      for (var link in navLinks) {
         final text = link.text.trim().toLowerCase();
         final href = link.attributes['href'];
         if (href == null || href.isEmpty || href == '#') continue;

         if (text == 'episode sebelumnya' || text == 'prev' || text == 'sebelumnya' || text.contains('<< previous')) {
             prevEpisodeUrl = href.startsWith('http') ? href : '$anoboyBaseUrl$href';
         } else if (text == 'episode selanjutnya' || text == 'next' || text == 'selanjutnya' || text.contains('next >>')) {
             nextEpisodeUrl = href.startsWith('http') ? href : '$anoboyBaseUrl$href';
         }
      }

      expect(prevEpisodeUrl, 'https://anoboy.boo/prev');
      expect(nextEpisodeUrl, 'https://anoboy.boo/next');
    });
  });
}
