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

      final elements = document.querySelectorAll('.home_index a[rel="bookmark"]');
      for (var element in elements) {
        if (element.querySelector('.amv') == null) continue;

        final title = element.attributes['title'] ?? element.querySelector('h3.ibox1')?.text.trim() ?? '';
        final url = element.attributes['href'] ?? '';
        final imgElement = element.querySelector('img');

        if (title.isNotEmpty && url.isNotEmpty) {
          final thumb = imgElement?.attributes['src'] ?? '';
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
            videoUrl: '',
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
          final h2 = titleElement.querySelector('h2');
          final rawTitle = h2 != null ? h2.text.trim() : titleElement.text.trim();
          final url = linkElement.attributes['href'] ?? '';
          final thumb = imgElement?.attributes['src'] ?? '';
          final epText = epElement?.text.trim() ?? '';

          if (epText.contains('Ep 0') && !epText.contains('Ep 01')) continue;

          int epNum = 0;
          final epMatch = RegExp(r'(\d+)').firstMatch(epText);
          if (epMatch != null) {
            epNum = int.tryParse(epMatch.group(1)!) ?? 0;
          }

          final showTitle = rawTitle.split(' Episode')[0].split(' Ep ')[0];

          episodes.add(Episode(
            id: url.hashCode,
            showId: showTitle.hashCode,
            episodeNumber: epNum,
            title: showTitle,
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
          final h2 = titleElement.querySelector('h2');
          final title = h2 != null ? h2.text.trim() : titleElement.text.trim();
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
          final h2 = titleElement.querySelector('h2');
          final title = h2 != null ? h2.text.trim() : titleElement.text.trim();
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

      final hasPlayer = document.querySelector('#mediaplayer') != null || document.querySelector('iframe') != null;
      final isShowPage = !hasPlayer && document.querySelectorAll('a[rel="bookmark"]').isNotEmpty;

      List<Episode> allEpisodes = [];
      String? showUrl;

      final List<Map<String, String>> videoServers = [];
      String? primaryIframe;
      final List<Map<String, String>> downloadLinks = [];

      if (isShowPage) {
        allEpisodes = _parseAnoboyEpisodesFromDoc(document, episode.showId);
        showUrl = episode.originalUrl;

        if (allEpisodes.isNotEmpty) {
          final targetEp = allEpisodes.firstWhere(
            (e) => e.episodeNumber == episode.episodeNumber,
            orElse: () => allEpisodes.first,
          );

          final detailedEp = await getAnoboyEpisodeDetails(targetEp);

          final fullShow = detailedEp.show ?? Show(
            id: episode.showId,
            title: episode.title ?? 'Anime',
            type: 'anime',
            status: 'ongoing',
            genres: [],
            coverImageUrl: episode.thumbnailUrl,
            originalUrl: showUrl,
          );

          final updatedShow = Show(
            id: fullShow.id,
            title: fullShow.title,
            type: fullShow.type,
            status: fullShow.status,
            genres: fullShow.genres,
            originalUrl: fullShow.originalUrl ?? showUrl,
            coverImageUrl: fullShow.coverImageUrl,
            episodes: allEpisodes,
          );

          return Episode(
            id: detailedEp.id,
            showId: detailedEp.showId,
            episodeNumber: detailedEp.episodeNumber,
            title: detailedEp.title,
            videoUrl: detailedEp.videoUrl,
            iframeUrl: detailedEp.iframeUrl,
            videoServers: detailedEp.videoServers,
            originalUrl: detailedEp.originalUrl,
            downloadLinks: detailedEp.downloadLinks,
            thumbnailUrl: detailedEp.thumbnailUrl,
            show: updatedShow,
            prevEpisodeUrl: detailedEp.prevEpisodeUrl,
            nextEpisodeUrl: detailedEp.nextEpisodeUrl,
          );
        }
      } else {
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

        final breadcrumbs = document.querySelectorAll('.anime > a');
        if (breadcrumbs.length >= 2) {
          showUrl = breadcrumbs[1].attributes['href'];
        }

        if (showUrl == null) {
          try {
            final allEpLink = document.querySelectorAll('a').firstWhere(
              (a) => a.text.contains('Semua Episode'),
            ).attributes['href'];
            showUrl = allEpLink;
          } catch (_) {}
        }

        if (showUrl != null) {
          final showResponse = await http.get(
            Uri.parse(showUrl.startsWith('http') ? showUrl : '$anoboyBaseUrl$showUrl'),
            headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' },
          );
          if (showResponse.statusCode == 200) {
            final showDoc = parse(showResponse.body);
            allEpisodes = _parseAnoboyEpisodesFromDoc(showDoc, episode.showId);
          }
        }
      }

      allEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

      String? prevEpisodeUrl;
      String? nextEpisodeUrl;

      final currentIdx = allEpisodes.indexWhere((e) => e.originalUrl == episode.originalUrl);
      if (currentIdx != -1) {
        if (currentIdx > 0) prevEpisodeUrl = allEpisodes[currentIdx - 1].originalUrl;
        if (currentIdx < allEpisodes.length - 1) nextEpisodeUrl = allEpisodes[currentIdx + 1].originalUrl;
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

      // Check if this is a Show Page (no video player, has episode list)
      final isShowPage = document.querySelector('.eplister') != null && document.querySelector('iframe') == null;

      if (isShowPage) {
         // Parse episodes
         List<Episode> allEpisodes = [];
         final epElements = document.querySelectorAll('.eplister li a');
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

          if (allEpisodes.isNotEmpty) {
             // Pick the target episode (matching number or first)
             final targetEp = allEpisodes.firstWhere(
                (e) => e.episodeNumber == episode.episodeNumber,
                orElse: () => allEpisodes.first,
             );
             // Fetch details for this target episode
             final detailedEp = await getAnichinEpisodeDetails(targetEp);

             final fullShow = detailedEp.show ?? Show(id: episode.showId, title: episode.title ?? 'Donghua', type: 'donghua', status: 'ongoing', genres: []);
             final updatedShow = Show(
               id: fullShow.id,
               title: fullShow.title,
               type: fullShow.type,
               status: fullShow.status,
               genres: fullShow.genres,
               originalUrl: fullShow.originalUrl ?? episode.originalUrl,
               coverImageUrl: fullShow.coverImageUrl,
               episodes: allEpisodes,
             );

             return Episode(
                id: detailedEp.id,
                showId: detailedEp.showId,
                episodeNumber: detailedEp.episodeNumber,
                title: detailedEp.title,
                videoUrl: detailedEp.videoUrl,
                iframeUrl: detailedEp.iframeUrl,
                videoServers: detailedEp.videoServers,
                originalUrl: detailedEp.originalUrl,
                downloadLinks: detailedEp.downloadLinks,
                thumbnailUrl: detailedEp.thumbnailUrl,
                show: updatedShow,
                prevEpisodeUrl: detailedEp.prevEpisodeUrl,
                nextEpisodeUrl: detailedEp.nextEpisodeUrl,
             );
          }
      }

      final List<Map<String, String>> videoServers = [];
      var iframeElement = document.querySelector('iframe[src*="anichin.stream"]');
      iframeElement ??= document.querySelector('.video-content iframe');
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

      String? prevUrl;
      String? nextUrl;
      for (var a in dlElements) {
         final text = a.text.trim().toLowerCase();
         if (text == 'prev' || text == 'sebelumnya' || text.contains('prev')) {
           prevUrl = a.attributes['href'];
         }
         if (text == 'next' || text == 'selanjutnya' || text.contains('next')) {
           nextUrl = a.attributes['href'];
         }
      }

      List<Episode> allEpisodes = [];
      String? showUrl = document.querySelector('.breadcrumb a:nth-child(2)')?.attributes['href'];
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
          final h2 = titleElement.querySelector('h2');
          final title = h2 != null ? h2.text.trim() : titleElement.text.trim();
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

  Future<Map<String, List<Show>>> getAnichinSchedule() async {
    try {
      final response = await http.get(Uri.parse('$anichinBaseUrl/schedule/'));
      if (response.statusCode != 200) return {};

      final document = parse(response.body);
      final Map<String, List<Show>> schedule = {};

      // Look for tab-content structure which is common
      final tabContent = document.querySelector('.tab-content');
      if (tabContent != null) {
        // usually days are in tab panes
        final panes = tabContent.children;
        // Need to map pane index to day name. Usually tabs are above.
        final tabs = document.querySelectorAll('.nav-tabs li a');
        for (int i=0; i < tabs.length && i < panes.length; i++) {
           final dayName = tabs[i].text.trim();
           final pane = panes[i];
           final shows = <Show>[];

           final items = pane.querySelectorAll('.bs'); // .bs is common item class
           for (var item in items) {
             final title = item.querySelector('.tt')?.text.trim() ?? '';
             final link = item.querySelector('a')?.attributes['href'] ?? '';
             final img = item.querySelector('img')?.attributes['src'] ?? '';

             if (title.isNotEmpty && link.isNotEmpty) {
               shows.add(Show(
                 id: link.hashCode,
                 title: title,
                 type: 'donghua',
                 status: 'ongoing',
                 coverImageUrl: img,
                 originalUrl: link,
                 genres: [],
               ));
             }
           }
           if (shows.isNotEmpty) schedule[dayName] = shows;
        }
      }

      // Fallback: Linear scan for H2/H3 headers
      if (schedule.isEmpty) {
         final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu', 'Minggu'];
         final content = document.querySelector('.entry-content') ?? document.body;
         if (content != null) {
            String currentDay = '';
            // Iterate all elements in content
            for (var element in content.children) {
               final text = element.text.trim();
               if (days.any((d) => text.contains(d) && text.length < 20)) {
                  currentDay = text;
                  schedule[currentDay] = [];
               } else if (currentDay.isNotEmpty && schedule.containsKey(currentDay)) {
                  // Check if this element contains links or is a link
                  final links = element.localName == 'a' ? [element] : element.querySelectorAll('a');
                  for (var link in links) {
                      final title = link.text.trim();
                      final url = link.attributes['href'] ?? '';
                      final img = link.querySelector('img')?.attributes['src'] ?? '';
                      if (title.isNotEmpty && url.isNotEmpty) {
                         schedule[currentDay]!.add(Show(
                           id: url.hashCode,
                           title: title,
                           type: 'donghua',
                           status: 'ongoing',
                           coverImageUrl: img,
                           originalUrl: url,
                           genres: []
                         ));
                      }
                  }
               }
            }
         }
      }

      return schedule;
    } catch (e) {
      debugPrint('Error scraping schedule: $e');
      return {};
    }
  }
}
