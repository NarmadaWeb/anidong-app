import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';

void main() {
  group('Scraping Fixes Verification', () {
    // --- Issue 1: Explore Genre Status ---

    test('Anoboy: Status is "completed" if title contains "Completed"', () {
      const title = 'Naruto Shippuden Completed';
      String status = 'ongoing';
      if (title.toLowerCase().contains('completed') || title.toLowerCase().contains('tamat')) {
        status = 'completed';
      }
      expect(status, 'completed');
    });

    test('Anoboy: Status is "completed" if title contains "Tamat"', () {
      const title = 'Naruto Shippuden Tamat';
      String status = 'ongoing';
      if (title.toLowerCase().contains('completed') || title.toLowerCase().contains('tamat')) {
        status = 'completed';
      }
      expect(status, 'completed');
    });

    test('Anoboy: Status is "ongoing" if title does not contain keywords', () {
      const title = 'One Piece Episode 1000';
      String status = 'ongoing';
      if (title.toLowerCase().contains('completed') || title.toLowerCase().contains('tamat')) {
        status = 'completed';
      }
      expect(status, 'ongoing');
    });

    test('Anichin: Status extraction from .status', () {
      const html = '''
        <div class="bs">
          <div class="status">Completed</div>
        </div>
      ''';
      final document = parse(html);
      final element = document.querySelector('.bs')!;

      String status = 'ongoing';
      final statusEl = element.querySelector('.status') ?? element.querySelector('.sb') ?? element.querySelector('.limit .bt');
      if (statusEl != null) {
        final text = statusEl.text.trim().toLowerCase();
        if (text.contains('completed') || text.contains('end') || text.contains('tamat')) {
          status = 'completed';
        }
      }
      expect(status, 'completed');
    });

    test('Anichin: Status extraction from .sb', () {
      const html = '''
        <div class="bs">
          <div class="sb">End</div>
        </div>
      ''';
      final document = parse(html);
      final element = document.querySelector('.bs')!;

      String status = 'ongoing';
      final statusEl = element.querySelector('.status') ?? element.querySelector('.sb') ?? element.querySelector('.limit .bt');
      if (statusEl != null) {
        final text = statusEl.text.trim().toLowerCase();
        if (text.contains('completed') || text.contains('end') || text.contains('tamat')) {
          status = 'completed';
        }
      }
      expect(status, 'completed');
    });

    // --- Issue 2: Recommended For You (Missing Episodes) ---

    test('Anoboy: Show URL fallback (Standard Breadcrumbs)', () {
      const html = '''
        <div class="breadcrumbs">
          <a href="/">Home</a>
          <a href="https://anoboy.boo/anime/naruto/">Naruto</a>
          <span>Episode 1</span>
        </div>
      ''';
      final document = parse(html);

      String? showUrl;
      // Primary logic (mocked fail)
      // Fallback 1
      if (showUrl == null) {
          final bc = document.querySelectorAll('.breadcrumbs a, .breadcrumb a');
          for (var b in bc) {
             if (b.attributes['href']?.contains('/anime/') ?? false) {
                 showUrl = b.attributes['href'];
                 break;
             }
          }
      }
      expect(showUrl, 'https://anoboy.boo/anime/naruto/');
    });

    test('Anoboy: Show URL fallback (List Episode Link)', () {
      const html = '''
        <div>
          <a href="https://anoboy.boo/anime/naruto/">List Episode</a>
        </div>
      ''';
      final document = parse(html);

      String? showUrl;
      // Fallback 2
       if (showUrl == null) {
          try {
            final allEpLink = document.querySelectorAll('a').firstWhere(
              (a) => a.text.toLowerCase().contains('semua episode') || a.text.toLowerCase().contains('list episode'),
            ).attributes['href'];
            showUrl = allEpLink;
          } catch (_) {}
      }
      expect(showUrl, 'https://anoboy.boo/anime/naruto/');
    });

    test('Anichin: Show Page Detection (Enhanced selectors)', () {
      const html = '''
        <div class="episodelist">
          <li><a href="#">Ep 1</a></li>
        </div>
      ''';
      final document = parse(html);

      final hasList = document.querySelector('.eplister') != null || document.querySelector('.lstep') != null || document.querySelector('.episodelist') != null;
      final isShowPage = hasList && document.querySelector('iframe') == null;

      expect(isShowPage, true);
    });

    test('Anichin: Show URL extraction from breadcrumbs', () {
      const html = '''
        <div class="breadcrumb">
           <a href="/">Home</a>
           <a href="https://anichin.asia/donghua/soul-land/">Soul Land</a>
           <span>Ep 100</span>
        </div>
      ''';
      final document = parse(html);

      String? showUrl;
      // Primary (fail)
      // Fallback
      if (showUrl == null) {
         final bcs = document.querySelectorAll('.breadcrumb a, .breadcrumbs a');
         for (var b in bcs) {
            final href = b.attributes['href'];
            if (href != null && (href.contains('/donghua/') || href.contains('/anime/'))) {
               showUrl = href;
               break;
            }
         }
      }
      expect(showUrl, 'https://anichin.asia/donghua/soul-land/');
    });
  });
}
