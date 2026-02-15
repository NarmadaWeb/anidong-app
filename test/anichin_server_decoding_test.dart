import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';
import 'package:anidong/data/services/scraping_service.dart';

void main() {
  test('Extract Anichin Servers handles Base64 encoded options', () {
    const html = '''
    <div class="mobius">
        <select class="mirror" name="mirror">
            <option value="">Pilih Server Video</option>
            <option value="PGlmcmFtZSB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBzcmM9Imh0dHBzOi8vYW5pY2hpbi5zdHJlYW0vP2lkPXY3M2szODQiIGZyYW1lYm9yZGVyPSIwIiBhbGxvdz0iYWNjZWxlcm9tZXRlcjsgYXV0b3BsYXk7IGVuY3J5cHRlZC1tZWRpYTsgZ3lyb3Njb3BlOyBwaWN0dXJlLWluLXBpY3R1cmUiIGFsbG93ZnVsbHNjcmVlbj48L2lmcmFtZT4=" data-index="1">
            Vip 1		</option>
            <option value="PGlmcmFtZSB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBzcmM9Imh0dHBzOi8vZ2VvLmRhaWx5bW90aW9uLmNvbS9wbGF5ZXIveGlkMHQuaHRtbD92aWRlbz1rN295MmRMbjUxbWwxYUVWNFZJIiBmcmFtZWJvcmRlcj0iMCIgYWxsb3c9ImFjY2VsZXJvbWV0ZXI7IGF1dG9wbGF5OyBlbmNyeXB0ZWQtbWVkaWE7IGd5cm9zY29wZTsgcGljdHVyZS1pbi1waWN0dXJlIiBhbGxvd2Z1bGxzY3JlZW4+PC9pZnJhbWU+" data-index="2">
            Dailymotion [ADS]		</option>
        </select>
    </div>
    ''';

    final document = parse(html);
    final service = ScrapingService();
    final servers = service.extractAnichinServers(document);

    // Check if the URL is DECODED
    final vipServer = servers.firstWhere((s) => s['name'] == 'Vip 1');
    expect(vipServer['url'], equals('https://anichin.stream/?id=v73k384'), reason: 'URL should be decoded from Base64');

    final dailyServer = servers.firstWhere((s) => s['name']!.contains('Dailymotion'));
    expect(dailyServer['url'], contains('dailymotion.com/player'), reason: 'Dailymotion URL should be decoded');
  });
}
