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
      final response = await http.get(Uri.parse(anoboyBaseUrl));
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Episode> episodes = [];

      // Anoboy episodes are usually in a grid
      final elements = document.querySelectorAll('.home-mgrid .home-mcont');
      for (var element in elements) {
        final titleElement = element.querySelector('.home-mtitle');
        final linkElement = element.querySelector('a');
        final imgElement = element.querySelector('img');

        if (titleElement != null && linkElement != null) {
          final title = titleElement.text.trim();
          final url = linkElement.attributes['href'] ?? '';
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
            thumbnailUrl: thumb.startsWith('http') ? thumb : '$anoboyBaseUrl$thumb',
            originalUrl: url,
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
      final response = await http.get(Uri.parse(episode.originalUrl!));
      if (response.statusCode != 200) return episode;

      final document = parse(response.body);

      // Extract IFrame and Servers
      final List<Map<String, String>> videoServers = [];
      String? primaryIframe;

      final iframeElement = document.querySelector('iframe');
      if (iframeElement != null) {
        primaryIframe = iframeElement.attributes['src'];
        if (primaryIframe != null) {
          videoServers.add({
            'name': 'Server 1',
            'url': primaryIframe.startsWith('http') ? primaryIframe : '$anoboyBaseUrl$primaryIframe'
          });
        }
      }

      // Extract Mirror Links as additional servers
      final mirrorElements = document.querySelectorAll('.vmirror a');
      int serverCount = videoServers.length + 1;
      for (var mirror in mirrorElements) {
        final link = mirror.attributes['data-video'] ?? mirror.attributes['href'];
        if (link != null && link.isNotEmpty && !link.contains('download')) {
          videoServers.add({
            'name': 'Server $serverCount',
            'url': link.startsWith('http') ? link : '$anoboyBaseUrl$link'
          });
          serverCount++;
        }
      }

      // Extract Download Links
      final List<Map<String, String>> downloadLinks = [];
      for (var dl in mirrorElements) {
        final name = dl.text.trim();
        final link = dl.attributes['href'];
        if (link != null && link.isNotEmpty && (link.contains('download') || name.toLowerCase().contains('download'))) {
          downloadLinks.add({'name': name, 'url': link});
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
      final response = await http.get(Uri.parse('$anoboyBaseUrl/?s=${Uri.encodeComponent(query)}'));
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Show> shows = [];

      final elements = document.querySelectorAll('.home-mgrid .home-mcont');
      for (var element in elements) {
        final titleElement = element.querySelector('.home-mtitle');
        final linkElement = element.querySelector('a');
        final imgElement = element.querySelector('img');

        if (titleElement != null && linkElement != null) {
          final title = titleElement.text.trim();
          final url = linkElement.attributes['href'] ?? '';
          final thumb = imgElement?.attributes['src'] ?? '';

          shows.add(Show(
            id: url.hashCode,
            title: title,
            type: 'anime',
            status: 'ongoing',
            coverImageUrl: thumb.startsWith('http') ? thumb : '$anoboyBaseUrl$thumb',
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
