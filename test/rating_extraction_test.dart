import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';

void main() {
  group('Rating Extraction Tests', () {
    test('Anichin: Extracts rating from .rating strong', () {
      const html = '''
      <div class="rating">
        <strong>Rating 9.20</strong>
        <div class="rating-prc">
          <meta itemprop="ratingValue" content="9.20">
        </div>
      </div>
      ''';
      final document = parse(html);

      // Method 1: Strong tag text parsing
      final strongText = document.querySelector('.rating strong')?.text.trim();
      double? rating;
      if (strongText != null) {
        final match = RegExp(r'Rating\s+(\d+\.?\d*)').firstMatch(strongText);
        if (match != null) {
          rating = double.tryParse(match.group(1)!);
        }
      }

      expect(rating, 9.20);
    });

    test('Anichin: Extracts rating from meta tag (preferred)', () {
      const html = '''
      <div class="rating">
        <strong>Rating 9.20</strong>
        <div class="rating-prc">
          <meta itemprop="ratingValue" content="8.5">
        </div>
      </div>
      ''';
      final document = parse(html);

      // Method 2: Meta tag
      final metaContent = document.querySelector('meta[itemprop="ratingValue"]')?.attributes['content'];
      final rating = double.tryParse(metaContent ?? '');

      expect(rating, 8.5);
    });

    test('Anichin: Returns null if rating is missing', () {
      const html = '<div>No rating here</div>';
      final document = parse(html);

      final metaContent = document.querySelector('meta[itemprop="ratingValue"]')?.attributes['content'];
      final rating = double.tryParse(metaContent ?? '');

      expect(rating, isNull);
    });
  });
}
