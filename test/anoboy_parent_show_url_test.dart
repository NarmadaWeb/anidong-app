import 'package:anidong/data/services/scraping_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;

void main() {
  group('Anoboy Show Details Fix', () {
    late ScrapingService service;

    setUp(() {
      service = ScrapingService();
    });

    test('findAnoboyParentShowUrl finds parent URL when table is outside entry-content', () async {
      const html = '''
<div class="deskripsi">
<div class="sisi entry-content">
	<img src="cover.jpg" />
    <h2 class="entry-title">Maou no Musume wa Yasashisugiru!! Episode 8 Subtitle Indonesia</h2>
</div>

<div class="sisi">
<h3 class="sub">Informasi</h3>
<div class="contentdeks">
Description here.
</div>
<div class="contenttable">
<table>
<tbody>
<tr>
<th scope="row">Semua Episode</th>
<td><a href="https://ww1.anoboy.boo/2026/01/maou-no-musume-wa-yasashisugiru/">Maou no Musume wa Yasashisugiru!!</a><br />
</tr>
<tr>
<th scope="row">Studio</th>
<td>EMT Squared</td>
</tr>
</tbody>
</table>
</div>
</div>
</div>
      ''';

      final document = parse(html);
      final parentShowUrl = service.findAnoboyParentShowUrl(document);

      expect(parentShowUrl, 'https://ww1.anoboy.boo/2026/01/maou-no-musume-wa-yasashisugiru/');
    });

    test('findAnoboyParentShowUrl finds parent URL from breadcrumbs', () async {
        const html = '''
<div class="breadcrumb" itemprop="breadcrumb">
<span itemscope itemtype="https://schema.org/BreadcrumbList">
<span itemprop="itemListElement" itemscope itemtype="https://schema.org/ListItem">
 <a itemprop="item" href="https://ww1.anoboy.boo"><span itemprop="name">anime</span></a>
 <meta itemprop="position" content="1" />
</span>
>
<span itemprop="itemListElement" itemscope itemtype="https://schema.org/ListItem">
<a itemscope itemtype="https://schema.org/WebPage" itemprop="item" itemid="https://ww1.anoboy.boo/maou-no-musume-wa-yasashisugiru/" href="https://ww1.anoboy.boo/maou-no-musume-wa-yasashisugiru/">
      <span itemprop="name">Maou no Musume wa Yasashisugiru!!</span></a>    <meta itemprop="position" content="2" />
  </span>
>
  <span itemprop="itemListElement" itemscope itemtype="https://schema.org/ListItem">
    <a itemprop="item" href="https://ww1.anoboy.boo/2026/02/maou-no-musume-wa-yasashisugiru-episode-8/">
    <span itemprop="name">Episode 8 </span></a>
<meta itemprop="position" content="3" />
  </span>
</span>
</div>
        ''';

        final document = parse(html);
        final parentShowUrl = service.findAnoboyParentShowUrl(document);
        expect(parentShowUrl, 'https://ww1.anoboy.boo/maou-no-musume-wa-yasashisugiru/');
    });

    test('findAnoboyParentShowUrl fallback to text link', () async {
        const html = '''
        <div>
           <a href="https://ww1.anoboy.boo/some-show/">Semua Episode</a>
        </div>
        ''';
        final document = parse(html);
        final parentShowUrl = service.findAnoboyParentShowUrl(document);
        expect(parentShowUrl, 'https://ww1.anoboy.boo/some-show/');
    });
  });
}
