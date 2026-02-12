// lib/data/services/scraping_service.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class ScrapingService {
  static const String anoboyBaseUrl = 'https://ww1.anoboy.boo';
  static const String anichinBaseUrl = 'https://anichin.asia';

  Future<List<Episode>> getAnoboyRecentEpisodes() async {
    try {
      final response = await http.get(
        Uri.parse(anoboyBaseUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Episode> episodes = [];

      // Anoboy episodes are in .home_index with a[rel="bookmark"]
      // Filter only those that contain .amv to avoid picking up the 'Jadwal' table links
      final elements = document.querySelectorAll('.home_index a[rel="bookmark"]');
      for (var element in elements) {
        if (element.querySelector('.amv') == null) continue;

        final title = element.attributes['title'] ?? element.querySelector('h3.ibox1')?.text.trim() ?? '';
        final url = element.attributes['href'] ?? '';
        final imgElement = element.querySelector('img');

        if (title.isNotEmpty && url.isNotEmpty) {
          final thumb = imgElement?.attributes['src'] ?? '';

          // Try to extract episode number from title
          int epNum = 0;
          final epMatch = RegExp(r'Episode\s+(\d+)').firstMatch(title);
          if (epMatch != null) {
            epNum = int.tryParse(epMatch.group(1)!) ?? 0;
          }

          episodes.add(Episode(
            id: url.hashCode,
            showId: title.hashCode,
            episodeNumber: epNum,
            title: title,
            videoUrl: '', // Will be fetched in details
            thumbnailUrl: thumb.isEmpty ? '' : (thumb.startsWith('http') ? thumb : '$anoboyBaseUrl$thumb'),
            originalUrl: url.startsWith('http') ? url : '$anoboyBaseUrl$url',
            show: Show(
              id: title.hashCode,
              title: title.split(' Episode')[0],
              type: 'anime',
              status: 'ongoing',
              genres: [],
            ),
          ));
        }
      }
      return episodes;
    } catch (e) {
      debugPrint('Error scraping Anoboy: $e');
      return [];
    }
  }

  Future<List<Episode>> getAnichinRecentEpisodes() async {
    try {
      final response = await http.get(Uri.parse(anichinBaseUrl));
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Episode> episodes = [];

      // Anichin recent episodes
      final elements = document.querySelectorAll('.listupd .bs');
      for (var element in elements) {
        final titleElement = element.querySelector('.tt');
        final linkElement = element.querySelector('a');
        final imgElement = element.querySelector('img');
        final epElement = element.querySelector('.epx');

        if (titleElement != null && linkElement != null) {
          final title = titleElement.text.trim();
          final url = linkElement.attributes['href'] ?? '';
          final thumb = imgElement?.attributes['src'] ?? '';
          final epText = epElement?.text.trim() ?? '';

          int epNum = 0;
          final epMatch = RegExp(r'(\d+)').firstMatch(epText);
          if (epMatch != null) {
            epNum = int.tryParse(epMatch.group(1)!) ?? 0;
          }

          episodes.add(Episode(
            id: url.hashCode,
            showId: title.hashCode,
            episodeNumber: epNum,
            title: title,
            videoUrl: '',
            thumbnailUrl: thumb,
            originalUrl: url,
            show: Show(
              id: title.hashCode,
              title: title.split(' Episode')[0],
              type: 'donghua',
              status: 'ongoing',
              genres: [],
            ),
          ));
        }
      }
      return episodes;
    } catch (e) {
      debugPrint('Error scraping Anichin: $e');
      return [];
    }
  }

  Future<Episode> getAnoboyEpisodeDetails(Episode episode) async {
    if (episode.originalUrl == null || episode.originalUrl!.isEmpty) return episode;

    try {
      final response = await http.get(
        Uri.parse(episode.originalUrl!),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return episode;

      final document = parse(response.body);

      // Extract IFrame and Servers
      final List<Map<String, String>> videoServers = [];
      String? primaryIframe;

      final iframeElement = document.querySelector('iframe#mediaplayer') ?? document.querySelector('iframe');
      if (iframeElement != null) {
        primaryIframe = iframeElement.attributes['src'];
        if (primaryIframe != null) {
          final iframeUrl = primaryIframe!.startsWith('http') ? primaryIframe! : '$anoboyBaseUrl$primaryIframe';
          videoServers.add({
            'name': 'Primary Server',
            'url': iframeUrl
          });
          primaryIframe = iframeUrl;
        }
      }

      // Extract Mirror Links as additional servers
      // Selector fixed to .vmiror (one 'r') based on actual HTML
      final mirrorElements = document.querySelectorAll('.vmiror a');
      for (var mirror in mirrorElements) {
        final link = mirror.attributes['data-video'] ?? mirror.attributes['href'];
        if (link != null && link.isNotEmpty && link != '#') {
          // Extract server name from text or parent text
          String serverName = mirror.text.trim();
          final parentText = mirror.parent?.text.split('|')[0].trim() ?? '';
          if (parentText.isNotEmpty && parentText != serverName) {
            serverName = '$parentText $serverName';
          }

          final fullLink = link.startsWith('http') ? link : '$anoboyBaseUrl$link';

          // Avoid duplicates
          if (!videoServers.any((s) => s['url'] == fullLink)) {
            videoServers.add({
              'name': serverName.isEmpty ? 'Mirror Server' : serverName,
              'url': fullLink
            });
          }
        }
      }

      // Extract Download Links using a.udl
      final List<Map<String, String>> downloadLinks = [];
      final dlElements = document.querySelectorAll('a.udl');
      for (var dl in dlElements) {
        final name = dl.text.trim();
        final link = dl.attributes['href'];
        if (link != null && link.isNotEmpty && link != 'none') {
          // Try to get resolution/provider info from sibling/parent
          String dlName = name;
          final parent = dl.parent;
          if (parent != null) {
            final providerText = parent.querySelector('.udj')?.text.trim() ?? '';
            if (providerText.isNotEmpty) {
              dlName = '$providerText $name';
            }
          }

          downloadLinks.add({
            'name': dlName,
            'url': link.startsWith('http') ? link : '$anoboyBaseUrl$link'
          });
        }
      }

      // If a.udl not found, fallback to old method
      if (downloadLinks.isEmpty) {
        for (var dl in mirrorElements) {
          final name = dl.text.trim();
          final link = dl.attributes['href'];
          if (link != null && link.isNotEmpty && link != '#' && (link.contains('download') || name.toLowerCase().contains('download'))) {
            downloadLinks.add({'name': name, 'url': link});
          }
        }
      }

      return Episode(
        id: episode.id,
        showId: episode.showId,
        episodeNumber: episode.episodeNumber,
        title: episode.title,
        videoUrl: episode.videoUrl,
        iframeUrl: videoServers.isNotEmpty ? videoServers[0]['url'] : primaryIframe,
        videoServers: videoServers,
        originalUrl: episode.originalUrl,
        downloadLinks: downloadLinks,
        thumbnailUrl: episode.thumbnailUrl,
        show: episode.show,
      );
    } catch (e) {
      debugPrint('Error getting Anoboy details: $e');
      return episode;
    }
  }

  Future<Episode> getAnichinEpisodeDetails(Episode episode) async {
    if (episode.originalUrl == null || episode.originalUrl!.isEmpty) return episode;

    try {
      final response = await http.get(Uri.parse(episode.originalUrl!));
      if (response.statusCode != 200) return episode;

      final document = parse(response.body);

      // Extract IFrame and Servers
      final List<Map<String, String>> videoServers = [];
      String? primaryIframe;

      final iframeElement = document.querySelector('.video-content iframe');
      if (iframeElement != null) {
        primaryIframe = iframeElement.attributes['src'];
        if (primaryIframe != null) {
          videoServers.add({'name': 'Server 1', 'url': primaryIframe});
        }
      }

      // Anichin sometimes has multiple servers in a list
      final serverElements = document.querySelectorAll('.mirror option');
      if (serverElements.isNotEmpty) {
        videoServers.clear();
        int serverCount = 1;
        for (var opt in serverElements) {
          final url = opt.attributes['value'];
          if (url != null && url.isNotEmpty) {
             // value often needs decoding or is a base64, but for this mock-up/scraper we assume it's a direct URL or handled by webview
             // Some sites use data-post and data-nounce for AJAX servers, which is harder.
             // Let's stick to what's easily available.
             videoServers.add({'name': 'Server $serverCount', 'url': url});
             serverCount++;
          }
        }
      }

      // Extract Download Links
      final List<Map<String, String>> downloadLinks = [];
      final downloadSection = document.querySelector('.download');
      if (downloadSection != null) {
        final links = downloadSection.querySelectorAll('a');
        for (var dl in links) {
          final name = dl.text.trim();
          final link = dl.attributes['href'];
          if (link != null && link.isNotEmpty) {
            downloadLinks.add({'name': name, 'url': link});
          }
        }
      }

      return Episode(
        id: episode.id,
        showId: episode.showId,
        episodeNumber: episode.episodeNumber,
        title: episode.title,
        videoUrl: episode.videoUrl,
        iframeUrl: videoServers.isNotEmpty ? videoServers[0]['url'] : primaryIframe,
        videoServers: videoServers,
        originalUrl: episode.originalUrl,
        downloadLinks: downloadLinks,
        thumbnailUrl: episode.thumbnailUrl,
        show: episode.show,
      );
    } catch (e) {
      debugPrint('Error getting Anichin details: $e');
      return episode;
    }
  }

  Future<List<Show>> searchAnoboy(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$anoboyBaseUrl/?s=${Uri.encodeComponent(query)}'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Show> shows = [];

      // Search results use similar structure as home page
      final elements = document.querySelectorAll('a[rel="bookmark"]');
      for (var element in elements) {
        final title = element.attributes['title'] ?? element.querySelector('h3.ibox1')?.text.trim() ?? '';
        final url = element.attributes['href'] ?? '';
        final imgElement = element.querySelector('img');

        if (title.isNotEmpty && url.isNotEmpty) {
          final thumb = imgElement?.attributes['src'] ?? '';

          shows.add(Show(
            id: url.hashCode,
            title: title,
            type: 'anime',
            status: 'ongoing',
            coverImageUrl: thumb.isEmpty ? '' : (thumb.startsWith('http') ? thumb : '$anoboyBaseUrl$thumb'),
            originalUrl: url.startsWith('http') ? url : '$anoboyBaseUrl$url',
            genres: [],
          ));
        }
      }
      return shows;
    } catch (e) {
      return [];
    }
  }

  Future<List<Show>> searchAnichin(String query) async {
    try {
      final response = await http.get(Uri.parse('$anichinBaseUrl/?s=${Uri.encodeComponent(query)}'));
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Show> shows = [];

      final elements = document.querySelectorAll('.listupd .bs');
      for (var element in elements) {
        final titleElement = element.querySelector('.tt');
        final linkElement = element.querySelector('a');
        final imgElement = element.querySelector('img');

        if (titleElement != null && linkElement != null) {
          final title = titleElement.text.trim();
          final url = linkElement.attributes['href'] ?? '';
          final thumb = imgElement?.attributes['src'] ?? '';

          shows.add(Show(
            id: url.hashCode,
            title: title,
            type: 'donghua',
            status: 'ongoing',
            coverImageUrl: thumb,
            originalUrl: url,
            genres: [],
          ));
        }
      }
      return shows;
    } catch (e) {
      return [];
    }
  }
}
