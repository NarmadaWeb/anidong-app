// lib/data/services/scraping_service.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class ScrapingService {
  static const String anoboyBaseUrl = 'https://ww1.anoboy.boo';
  static const String anichinBaseUrl = 'https://anichin.asia';

  Future<List<Episode>> getAnoboyRecentEpisodes({int page = 1}) async {
    try {
      final url = page > 1 ? '$anoboyBaseUrl/page/$page/' : anoboyBaseUrl;
      final response = await http.get(
        Uri.parse(url),
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
              coverImageUrl: thumb.isEmpty ? '' : (thumb.startsWith('http') ? thumb : '$anoboyBaseUrl$thumb'),
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

  Future<List<Episode>> getAnichinRecentEpisodes({int page = 1}) async {
    try {
      final url = page > 1 ? '$anichinBaseUrl/page/$page/' : anichinBaseUrl;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Episode> episodes = [];

      // Find "Rilisan Terbaru" section
      var latestSection = document.querySelectorAll('.listupd').firstWhere(
          (e) => e.previousElementSibling?.text.contains('Rilisan Terbaru') ?? false,
          orElse: () => document.querySelectorAll('.listupd').length > 1 ? document.querySelectorAll('.listupd')[1] : document.querySelector('.listupd')!
      );

      final elements = latestSection.querySelectorAll('.bs');
      for (var element in elements) {
        final titleElement = element.querySelector('.tt');
        final linkElement = element.querySelector('a');
        final imgElement = element.querySelector('img');
        final epElement = element.querySelector('.epx');

        if (titleElement != null && linkElement != null) {
          final rawTitle = titleElement.text.trim();
          final url = linkElement.attributes['href'] ?? '';
          final thumb = imgElement?.attributes['src'] ?? '';
          final epText = epElement?.text.trim() ?? '';

          if (epText.contains('Ep 0') && !epText.contains('Ep 01')) continue; // Skip Ep 0 if it's likely placeholder

          int epNum = 0;
          final epMatch = RegExp(r'(\d+)').firstMatch(epText);
          if (epMatch != null) {
            epNum = int.tryParse(epMatch.group(1)!) ?? 0;
          }

          // Clean title to allow cleaner UI (Show Name only)
          // e.g. "Perfect World Episode 255 Subtitle Indonesia" -> "Perfect World"
          final showTitle = rawTitle.split(' Episode')[0].split(' Ep ')[0];

          episodes.add(Episode(
            id: url.hashCode,
            showId: showTitle.hashCode, // Use Show Title hash to group better
            episodeNumber: epNum,
            title: showTitle, // Use cleaned title for display
            videoUrl: '',
            thumbnailUrl: thumb,
            originalUrl: url,
            show: Show(
              id: showTitle.hashCode,
              title: showTitle,
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

  Future<List<Show>> getAnichinPopularToday() async {
    try {
      final response = await http.get(Uri.parse(anichinBaseUrl));
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Show> shows = [];

      // Find "Terpopuler Hari Ini" section
      var popularSection = document.querySelectorAll('.listupd').firstWhere(
          (e) => e.previousElementSibling?.text.contains('Terpopuler Hari Ini') ?? false,
          orElse: () => document.querySelector('.listupd')!
      );

      final elements = popularSection.querySelectorAll('.bs');
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
            title: title.split(' Episode')[0].split(' Ep ')[0],
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

  Future<List<Show>> getAnichinRecommendations() async {
    try {
      final response = await http.get(Uri.parse(anichinBaseUrl));
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Show> shows = [];

      // Find "Rekomendasi" section
      var recSection = document.querySelectorAll('.listupd').firstWhere(
          (e) => e.previousElementSibling?.text.contains('Rekomendasi') ?? false,
          orElse: () => document.querySelectorAll('.listupd').length > 2 ? document.querySelectorAll('.listupd')[2] : document.querySelector('.listupd')!
      );

      final elements = recSection.querySelectorAll('.bs');
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
            title: title.split(' Episode')[0].split(' Ep ')[0],
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

      // Detection: Is this a Show Page (list of eps) or Episode Page (player)?
      // Episode page has #mediaplayer or iframe. Show page has list of bookmarks but no player.
      final hasPlayer = document.querySelector('#mediaplayer') != null || document.querySelector('iframe') != null;
      final isShowPage = !hasPlayer && document.querySelectorAll('a[rel="bookmark"]').isNotEmpty;

      List<Episode> allEpisodes = [];
      String? showUrl;

      final List<Map<String, String>> videoServers = [];
      String? primaryIframe;
      final List<Map<String, String>> downloadLinks = [];

      if (isShowPage) {
        // Parse episodes directly from this page
        allEpisodes = _parseAnoboyEpisodesFromDoc(document, episode.showId);
        showUrl = episode.originalUrl;
      } else {
        // Episode Page: Extract Video, Servers, Downloads
        final iframeElement = document.querySelector('iframe#mediaplayer') ?? document.querySelector('iframe');
        if (iframeElement != null) {
          primaryIframe = iframeElement.attributes['src'];
          if (primaryIframe != null) {
            final iframeUrl = primaryIframe.startsWith('http') ? primaryIframe : '$anoboyBaseUrl$primaryIframe';
            videoServers.add({
              'name': 'Primary Server',
              'url': iframeUrl
            });
            primaryIframe = iframeUrl;
          }
        }

        final mirrorElements = document.querySelectorAll('.vmiror a');
        for (var mirror in mirrorElements) {
          final link = mirror.attributes['data-video'] ?? mirror.attributes['href'];
          if (link != null && link.isNotEmpty && link != '#') {
            String serverName = mirror.text.trim();
            final parentText = mirror.parent?.text.split('|')[0].trim() ?? '';
            if (parentText.isNotEmpty && parentText != serverName) {
              serverName = '$parentText $serverName';
            }
            final fullLink = link.startsWith('http') ? link : '$anoboyBaseUrl$link';
            if (!videoServers.any((s) => s['url'] == fullLink)) {
              videoServers.add({
                'name': serverName.isEmpty ? 'Mirror Server' : serverName,
                'url': fullLink
              });
            }
          }
        }

        final dlElements = document.querySelectorAll('a.udl');
        for (var dl in dlElements) {
          final name = dl.text.trim();
          final link = dl.attributes['href'];
          if (link != null && link.isNotEmpty && link != 'none') {
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

        // Find Show URL to fetch all episodes
        // Try finding show link from breadcrumbs
        final breadcrumbs = document.querySelectorAll('.anime > a');
        if (breadcrumbs.length >= 2) {
          showUrl = breadcrumbs[1].attributes['href'];
        }

        // Fallback: search for "Semua Episode" link
        if (showUrl == null) {
          final allEpLink = document.querySelectorAll('a').firstWhere(
            (a) => a.text.contains('Semua Episode'),
            orElse: () => document.createElement('a')
          ).attributes['href'];
          showUrl = allEpLink;
        }

        if (showUrl != null) {
          final showResponse = await http.get(
            Uri.parse(showUrl!.startsWith('http') ? showUrl! : '$anoboyBaseUrl$showUrl'),
            headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' },
          );
          if (showResponse.statusCode == 200) {
            final showDoc = parse(showResponse.body);
            allEpisodes = _parseAnoboyEpisodesFromDoc(showDoc, episode.showId);
          }
        }
      }

      // Sort episodes by number (Ascending)
      allEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

      // Determine Prev/Next
      String? prevEpisodeUrl;
      String? nextEpisodeUrl;

      // Note: If isShowPage, we don't have a "current episode" context unless we pick one.
      // But typically this function returns 'episode' with details.
      // If isShowPage, we might want to return the FIRST or LATEST episode as the main one,
      // or just a placeholder.
      // Let's rely on passed 'episode.url' to find index if possible.

      final currentIdx = allEpisodes.indexWhere((e) => e.originalUrl == episode.originalUrl);
      if (currentIdx != -1) {
        if (currentIdx > 0) prevEpisodeUrl = allEpisodes[currentIdx - 1].originalUrl;
        if (currentIdx < allEpisodes.length - 1) nextEpisodeUrl = allEpisodes[currentIdx + 1].originalUrl;
      } else if (isShowPage && allEpisodes.isNotEmpty) {
        // If we are on Show Page, maybe we want to facilitate playing the first episode?
        // But VideoPlayerScreen expects a video.
        // Let's leave prev/next null, user will select from list.
      }

      final show = episode.show ?? Show(id: episode.showId, title: episode.title ?? 'Anime', type: 'anime', status: 'ongoing', genres: []);
      final updatedShow = Show(
        id: show.id,
        title: show.title,
        type: show.type,
        status: show.status,
        genres: show.genres,
        originalUrl: show.originalUrl ?? showUrl,
        coverImageUrl: show.coverImageUrl,
        episodes: allEpisodes.isNotEmpty ? allEpisodes : null,
      );

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
        show: updatedShow,
        prevEpisodeUrl: prevEpisodeUrl,
        nextEpisodeUrl: nextEpisodeUrl,
      );
    } catch (e) {
      debugPrint('Error getting Anoboy details: $e');
      return episode;
    }
  }

  List<Episode> _parseAnoboyEpisodesFromDoc(dynamic document, int showId) {
    final List<Episode> eps = [];
    final epLinks = document.querySelectorAll('a[rel="bookmark"]');
    for (var link in epLinks) {
      final title = link.attributes['title'] ?? link.text.trim();
      final url = link.attributes['href'] ?? '';
      if (url.isNotEmpty && (title.contains('Episode') || title.contains('Ep '))) {
        int epNum = 0;
        final epMatch = RegExp(r'Episode\s+(\d+)').firstMatch(title);
        if (epMatch != null) epNum = int.tryParse(epMatch.group(1)!) ?? 0;

        eps.add(Episode(
          id: url.hashCode,
          showId: showId,
          episodeNumber: epNum,
          title: title,
          videoUrl: '',
          originalUrl: url.startsWith('http') ? url : '$anoboyBaseUrl$url',
        ));
      }
    }
    return eps;
  }

  Future<Episode> getAnichinEpisodeDetails(Episode episode) async {
    if (episode.originalUrl == null || episode.originalUrl!.isEmpty) return episode;

    try {
      final response = await http.get(Uri.parse(episode.originalUrl!));
      if (response.statusCode != 200) return episode;

      final document = parse(response.body);

      // Extract IFrame and Servers
      final List<Map<String, String>> videoServers = [];

      // Attempt 1: Look for iframe with src containing 'anichin.stream'
      var iframeElement = document.querySelector('iframe[src*="anichin.stream"]');
      // Attempt 2: Look for iframe in .video-content
      iframeElement ??= document.querySelector('.video-content iframe');
      // Attempt 3: Any iframe (risky but fallback)
      iframeElement ??= document.querySelector('iframe');

      String? primaryIframe = iframeElement?.attributes['src'];
      if (primaryIframe != null && primaryIframe.isNotEmpty) {
        videoServers.add({'name': 'Primary Server', 'url': primaryIframe});
      }

      final serverElements = document.querySelectorAll('.mirror option');
      if (serverElements.isNotEmpty) {
        int serverCount = 1;
        for (var opt in serverElements) {
          final url = opt.attributes['value'];
          if (url != null && url.isNotEmpty) {
             videoServers.add({'name': 'Server $serverCount', 'url': url});
             serverCount++;
          }
        }
      }

      // Download Links
      // Search for anchor tags containing typical download keywords
      final List<Map<String, String>> downloadLinks = [];
      final dlElements = document.querySelectorAll('a');
      for (var a in dlElements) {
        final text = a.text.trim();
        final lowerText = text.toLowerCase();
        final href = a.attributes['href'];

        if (href != null && href.isNotEmpty && !href.startsWith('#')) {
          if (lowerText.contains('mirrored') ||
              lowerText.contains('terabox') ||
              lowerText.contains('gdrive') ||
              lowerText.contains('acefile') ||
              lowerText.contains('files')) {
            downloadLinks.add({'name': text.isEmpty ? 'Download Link' : text, 'url': href});
          }
        }
      }

      // Prev/Next Links
      String? prevUrl;
      String? nextUrl;
      for (var a in dlElements) { // iterate all links again or query specifically
         final text = a.text.trim().toLowerCase();
         if (text == 'prev' || text == 'sebelumnya' || text.contains('prev')) {
           prevUrl = a.attributes['href'];
         }
         if (text == 'next' || text == 'selanjutnya' || text.contains('next')) {
           nextUrl = a.attributes['href'];
         }
      }

      // Fetch All Episodes from Show Page
      List<Episode> allEpisodes = [];
      // Attempt to find Show URL from breadcrumbs
      // Breadcrumb structure: Home > Show Title > Episode Title
      String? showUrl = document.querySelector('.breadcrumb a:nth-child(2)')?.attributes['href'];
      // Fallback
      showUrl ??= document.querySelector('.breadcrumb a[href*="/anime/"]')?.attributes['href'];

      if (showUrl != null) {
        final showResponse = await http.get(Uri.parse(showUrl));
        if (showResponse.statusCode == 200) {
          final showDoc = parse(showResponse.body);
          final epElements = showDoc.querySelectorAll('.eplister li a');
          for (var epEl in epElements) {
            final url = epEl.attributes['href'] ?? '';
            final numText = epEl.querySelector('.epl-num')?.text.trim() ?? '';
            final title = epEl.querySelector('.epl-title')?.text.trim() ?? '';

            if (url.isNotEmpty) {
              allEpisodes.add(Episode(
                id: url.hashCode,
                showId: episode.showId,
                episodeNumber: int.tryParse(numText) ?? 0,
                title: title,
                videoUrl: '',
                originalUrl: url,
              ));
            }
          }
        }
      }

      final show = episode.show ?? Show(id: episode.showId, title: episode.title ?? 'Donghua', type: 'donghua', status: 'ongoing', genres: []);
      final updatedShow = Show(
        id: show.id,
        title: show.title,
        type: show.type,
        status: show.status,
        genres: show.genres,
        originalUrl: show.originalUrl ?? showUrl,
        coverImageUrl: show.coverImageUrl,
        episodes: allEpisodes.isNotEmpty ? allEpisodes : null,
      );

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
        show: updatedShow,
        prevEpisodeUrl: prevUrl,
        nextEpisodeUrl: nextUrl,
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

      final elements = document.querySelectorAll('a[rel="bookmark"]');
      for (var element in elements) {
        final title = element.attributes['title'] ?? element.querySelector('h3.ibox1')?.text.trim() ?? '';
        final url = element.attributes['href'] ?? '';
        final imgElement = element.querySelector('img');

        if (title.isNotEmpty && url.isNotEmpty) {
          final thumb = imgElement?.attributes['src'] ?? '';

          shows.add(Show(
            id: url.hashCode,
            title: title.split(' Episode')[0].split(' Ep ')[0],
            type: 'anime',
            status: 'ongoing',
            coverImageUrl: thumb.isEmpty ? '' : (thumb.startsWith('http') ? thumb : '$anoboyBaseUrl$thumb'),
            originalUrl: url.startsWith('http') ? url : '$anoboyBaseUrl$url',
            genres: [],
          ));
        }
      }

      final seenTitles = <String>{};
      return shows.where((s) => seenTitles.add(s.title)).toList();
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
            title: title.split(' Episode')[0].split(' Ep ')[0],
            type: 'donghua',
            status: 'ongoing',
            coverImageUrl: thumb,
            originalUrl: url,
            genres: [],
          ));
        }
      }

      final seenTitles = <String>{};
      return shows.where((s) => seenTitles.add(s.title)).toList();
    } catch (e) {
      return [];
    }
  }
}
