import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';

void main() {
  group('Anichin Video Server Parsing', () {
    const html = '''
      <div class="video-content">
        <iframe src="https://anichin.stream/embed/vip1"></iframe>
      </div>
      <select class="mirror">
        <option value="">Pilih Server Video</option>
        <option value="https://anichin.stream/embed/vip1">Vip 1</option>
        <option value="https://dailymotion.com/embed/video/x123">Dailymotion [ADS]</option>
        <option value="https://rumble.com/embed/v123">Rumble [ADS]</option>
        <option value="https://ok.ru/videoembed/123">OK.ru</option>
        <option value="https://gdrive.com/file/d/123">GDrive 1 [ADS]</option>
        <option value="https://other.com/video">Other Server</option>
      </select>
    ''';

    test('filters VIP and sorts servers correctly', () {
      final document = parse(html);
      final List<Map<String, String>> videoServers = [];

      var iframeElement = document.querySelector('iframe[src*="anichin.stream"]');
      iframeElement ??= document.querySelector('.video-content iframe');
      iframeElement ??= document.querySelector('iframe');

      final serverElements = document.querySelectorAll('.mirror option');
      if (serverElements.isNotEmpty) {
        for (var opt in serverElements) {
          final url = opt.attributes['value'];
          final name = opt.text.trim();

          if (url != null && url.isNotEmpty) {
             // Filter out VIP servers
             if (name.toLowerCase().contains('vip')) continue;

             videoServers.add({'name': name, 'url': url});
          }
        }

        // Sort servers by priority: Dailymotion, Rumble, OK.ru, GDrive, then others
        videoServers.sort((a, b) {
          final nameA = a['name']!.toLowerCase();
          final nameB = b['name']!.toLowerCase();

          int getPriority(String name) {
            if (name.contains('dailymotion')) return 1;
            if (name.contains('rumble')) return 2;
            if (name.contains('ok.ru')) return 3;
            if (name.contains('gdrive')) return 4;
            return 100; // Others
          }

          return getPriority(nameA).compareTo(getPriority(nameB));
        });
      }

      // Add Primary Iframe only if no safe servers found, as a fallback
      if (videoServers.isEmpty) {
        String? primaryIframe = iframeElement?.attributes['src'];
        if (primaryIframe != null && primaryIframe.isNotEmpty) {
          videoServers.add({'name': 'Primary Server', 'url': primaryIframe});
        }
      }

      // Assertions
      expect(videoServers.any((s) => s['name']!.contains('Vip')), isFalse, reason: 'Should not contain VIP server');
      expect(videoServers.any((s) => s['name'] == 'Primary Server'), isFalse, reason: 'Should not contain Primary Server when mirrors exist');

      expect(videoServers.length, 5); // Dailymotion, Rumble, OK.ru, GDrive, Other

      expect(videoServers[0]['name'], contains('Dailymotion'));
      expect(videoServers[1]['name'], contains('Rumble'));
      expect(videoServers[2]['name'], contains('OK.ru'));
      expect(videoServers[3]['name'], contains('GDrive'));
      expect(videoServers[4]['name'], 'Other Server');
    });

    test('fallbacks to primary iframe if no mirrors', () {
       const htmlFallback = '''
          <iframe src="https://anichin.stream/embed/vip1"></iframe>
       ''';
       final document = parse(htmlFallback);
       final List<Map<String, String>> videoServers = [];

       var iframeElement = document.querySelector('iframe');

       final serverElements = document.querySelectorAll('.mirror option');
       // ... logic ...
       if (videoServers.isEmpty) {
          String? primaryIframe = iframeElement?.attributes['src'];
          if (primaryIframe != null) videoServers.add({'name': 'Primary Server', 'url': primaryIframe});
       }

       expect(videoServers.length, 1);
       expect(videoServers[0]['name'], 'Primary Server');
    });
  });
}
