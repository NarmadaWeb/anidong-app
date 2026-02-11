// lib/data/services/scraping_service.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
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
      print('Error scraping Anoboy: $e');
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
      print('Error scraping Anichin: $e');
      return [];
    }
  }

  Future<Episode> getAnoboyEpisodeDetails(Episode episode) async {
    if (episode.originalUrl == null || episode.originalUrl!.isEmpty) return episode;

    try {
      final response = await http.get(Uri.parse(episode.originalUrl!));
      if (response.statusCode != 200) return episode;

      final document = parse(response.body);

      // Extract IFrame
      String? iframeUrl;
      final iframeElement = document.querySelector('iframe');
      if (iframeElement != null) {
        iframeUrl = iframeElement.attributes['src'];
      }

      // If iframe not found directly, look for the adsbatch link
      if (iframeUrl == null) {
        final allIframes = document.querySelectorAll('iframe');
        for (var ifr in allIframes) {
          final src = ifr.attributes['src'];
          if (src != null && src.contains('uploads')) {
            iframeUrl = src;
            if (!iframeUrl.startsWith('http')) {
              iframeUrl = '$anoboyBaseUrl$iframeUrl';
            }
            break;
          }
        }
      }

      // Extract Download Links
      final List<Map<String, String>> downloadLinks = [];
      final downloadElements = document.querySelectorAll('.vmirror a');
      for (var dl in downloadElements) {
        final name = dl.text.trim();
        final link = dl.attributes['href'];
        if (link != null && link.isNotEmpty) {
          downloadLinks.add({'name': name, 'url': link});
        }
      }

      return Episode(
        id: episode.id,
        showId: episode.showId,
        episodeNumber: episode.episodeNumber,
        title: episode.title,
        videoUrl: episode.videoUrl,
        iframeUrl: iframeUrl,
        originalUrl: episode.originalUrl,
        downloadLinks: downloadLinks,
        thumbnailUrl: episode.thumbnailUrl,
        show: episode.show,
      );
    } catch (e) {
      print('Error getting Anoboy details: $e');
      return episode;
    }
  }

  Future<Episode> getAnichinEpisodeDetails(Episode episode) async {
    if (episode.originalUrl == null || episode.originalUrl!.isEmpty) return episode;

    try {
      final response = await http.get(Uri.parse(episode.originalUrl!));
      if (response.statusCode != 200) return episode;

      final document = parse(response.body);

      // Extract IFrame
      String? iframeUrl;
      final iframeElement = document.querySelector('.video-content iframe');
      if (iframeElement != null) {
        iframeUrl = iframeElement.attributes['src'];
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
        iframeUrl: iframeUrl,
        originalUrl: episode.originalUrl,
        downloadLinks: downloadLinks,
        thumbnailUrl: episode.thumbnailUrl,
        show: episode.show,
      );
    } catch (e) {
      print('Error getting Anichin details: $e');
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
