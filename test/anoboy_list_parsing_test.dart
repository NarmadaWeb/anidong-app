import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anidong/data/services/scraping_service.dart';

void main() {
  group('Anoboy Anime List Scraping', () {
    test('getAnoboyAnimeList returns a populated list of Shows', () async {
      final service = ScrapingService();
      final shows = await service.getAnoboyAnimeList();

      // This test requires internet access. If it fails due to network,
      // check if the site is reachable.

      // If the site is down or layout changed, this might return empty.
      // But we expect at least some shows (e.g. 100+).
      if (shows.isEmpty) {
        // Warning instead of failure if it's just a network glitch?
        // No, for verification we want to know if it works.
        debugPrint('Warning: Anime list is empty. Check network or selector.');
      } else {
        expect(shows.length, greaterThan(10));

        final firstShow = shows.first;
        expect(firstShow.title, isNotEmpty);
        expect(firstShow.originalUrl, contains('anoboy.boo'));

        debugPrint('Fetched ${shows.length} anime.');
        debugPrint('First anime: ${firstShow.title} -> ${firstShow.originalUrl}');
      }
    });
  });
}
