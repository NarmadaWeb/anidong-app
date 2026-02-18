import 'package:anidong/data/services/scraping_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';

void main() {
  group('Anichin Show URL Extraction', () {
    test('extracts show URL from nested breadcrumbs without category slug', () {
      const html = '''
      <div class="breadcrumb">
        <span>
          <a href="https://anichin.asia">Beranda</a>
        </span>
        &gt;
        <span>
          <a href="https://anichin.asia/the-supreme-body-refining-master/">The Supreme Body Refining Master</a>
        </span>
        &gt;
        <span>
          The Supreme Body Refining Master Episode 10
        </span>
      </div>
      ''';
      final document = parse(html);
      final service = ScrapingService();

      final url = service.findAnichinShowUrl(document);

      expect(url, 'https://anichin.asia/the-supreme-body-refining-master/');
    });

    test('extracts show URL from "Semua Episode" link without category slug', () {
      const html = '''
      <div class="entry-content">
        <p>Some text</p>
        <a href="https://anichin.asia/the-supreme-body-refining-master/">Semua Episode</a>
      </div>
      ''';
      final document = parse(html);
      final service = ScrapingService();

      final url = service.findAnichinShowUrl(document);

      expect(url, 'https://anichin.asia/the-supreme-body-refining-master/');
    });

    test('extracts show URL when breadcrumb structure is flat', () {
      const html = '''
      <div class="breadcrumb">
        <a href="https://anichin.asia">Home</a>
        <a href="https://anichin.asia/show-title/">Show Title</a>
        <span>Episode 1</span>
      </div>
      ''';
      final document = parse(html);
      final service = ScrapingService();

      final url = service.findAnichinShowUrl(document);

      expect(url, 'https://anichin.asia/show-title/');
    });
  });
}
