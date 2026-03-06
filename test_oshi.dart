import 'package:flutter_test/flutter_test.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:anidong/data/models/show_model.dart';

void main() {
  test('Oshi no ko episodes', () async {
    final service = ScrapingService();
    final show = Show(
      id: 1,
      title: 'Oshi no Ko Season 1 + 2 + 3',
      type: 'anime',
      status: 'ongoing',
      originalUrl: 'https://ww1.anoboy.boo/2023/04/oshi-no-ko-season-1-2-3/',
      genres: [],
    );

    final details = await service.getAnoboyShowDetails(show);
    print('Show: ${details.title}');
    print('Total episodes parsed: ${details.episodes?.length ?? 0}');
  });
}
