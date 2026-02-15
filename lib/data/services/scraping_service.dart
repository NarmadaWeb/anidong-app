// lib/data/services/scraping_service.dart

import 'dart:convert';
import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class ScrapingService {
  static String anoboyBaseUrl = 'https://ww1.anoboy.boo';
  static String anichinBaseUrl = 'https://anichin.asia';

  static void updateBaseUrls(String anoboy, String anichin) {
    if (anoboy.isNotEmpty) anoboyBaseUrl = anoboy;
    if (anichin.isNotEmpty) anichinBaseUrl = anichin;
  }

  String _extractImageUrl(Element? imgElement) {
    if (imgElement == null) return '';
    String thumb = imgElement.attributes['data-src'] ??
                   imgElement.attributes['data-lazy-src'] ??
                   imgElement.attributes['src'] ?? '';

    if (thumb.startsWith('//')) {
      return 'https:$thumb';
    }
    // For Anoboy, relative paths often need the base URL
    if (thumb.isNotEmpty && !thumb.startsWith('http')) {
       return '$anoboyBaseUrl$thumb';
    }
    return thumb;
  }

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
          final thumb = _extractImageUrl(imgElement);
          int epNum = 0;
          final epMatch = RegExp(r'(?:Episode|Ep)\s+(\d+)').firstMatch(title);
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
            originalUrl: url.startsWith('http') ? url : '$anoboyBaseUrl$url',
            show: Show(
              id: title.hashCode,
              title: title.split(' Episode')[0],
              type: 'anime',
              status: 'ongoing',
              genres: [],
              coverImageUrl: thumb,
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

          String status = 'ongoing';
          final statusEl = element.querySelector('.status') ?? element.querySelector('.sb') ?? element.querySelector('.limit .bt');
          if (statusEl != null) {
            final text = statusEl.text.trim().toLowerCase();
            if (text.contains('completed') || text.contains('end') || text.contains('tamat')) {
              status = 'completed';
            }
          }

          shows.add(Show(
            id: url.hashCode,
            title: title.split(' Episode')[0].split(' Ep ')[0],
            type: 'donghua',
            status: status,
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

          String status = 'ongoing';
          final statusEl = element.querySelector('.status') ?? element.querySelector('.sb') ?? element.querySelector('.limit .bt');
          if (statusEl != null) {
            final text = statusEl.text.trim().toLowerCase();
            if (text.contains('completed') || text.contains('end') || text.contains('tamat')) {
              status = 'completed';
            }
          }

          shows.add(Show(
            id: url.hashCode,
            title: title.split(' Episode')[0].split(' Ep ')[0],
            type: 'donghua',
            status: status,
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

      // Always try to parse episode list first to populate show.episodes
      List<Episode> allEpisodes = _parseAnoboyEpisodesFromDoc(document, episode.showId);

      final hasPlayer = document.querySelector('#mediaplayer') != null || document.querySelector('iframe') != null;

      // Determine if this is primarily a Show Page (List) or Episode Page (Video)
      // If no player, it's definitely a Show Page.
      bool isShowPage = !hasPlayer;

      // Fix for episode number if 0
      int currentEpisodeNumber = episode.episodeNumber;
      if (currentEpisodeNumber == 0) {
          // Try from title
          String titleText = document.querySelector('title')?.text ?? '';
          var match = RegExp(r'(?:Episode|Ep)\s+(\d+)', caseSensitive: false).firstMatch(titleText);
          if (match != null) {
             currentEpisodeNumber = int.tryParse(match.group(1)!) ?? 0;
          } else {
             // Try from breadcrumbs
             final breadcrumb = document.querySelector('.anime > span');
             if (breadcrumb != null) {
                 match = RegExp(r'Episode\s+(\d+)', caseSensitive: false).firstMatch(breadcrumb.text);
                 if (match != null) currentEpisodeNumber = int.tryParse(match.group(1)!) ?? 0;
             }
          }
      }

      String? showUrl = episode.originalUrl;
      final List<Map<String, String>> videoServers = [];
      String? primaryIframe;
      final List<Map<String, String>> downloadLinks = [];

      if (isShowPage) {
         // Pure Show Page logic (recurse to target episode)
         String coverImage = episode.thumbnailUrl ?? '';
         if (coverImage.isEmpty) {
             final imgEl = document.querySelector('.entry-content img, .post-body img');
             coverImage = _extractImageUrl(imgEl);
         }

         if (allEpisodes.isNotEmpty) {
            final targetEp = allEpisodes.firstWhere(
               (e) => e.episodeNumber == episode.episodeNumber,
               orElse: () => allEpisodes.first,
            );

            // Recurse ONLY if target URL is different to prevent loops
            if (targetEp.originalUrl != episode.originalUrl) {
               final detailedEp = await getAnoboyEpisodeDetails(targetEp);
                final fullShow = detailedEp.show ?? Show(
                    id: episode.showId,
                    title: episode.title ?? 'Anime',
                    type: 'anime',
                    status: 'ongoing',
                    genres: [],
                    coverImageUrl: coverImage,
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
                    rating: fullShow.rating,
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
      }

      // Episode Page Logic (Extract Player) - Runs for Episode Pages OR Bulk Pages (Player + List)
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

      // Breadcrumbs
      final breadcrumbs = document.querySelectorAll('.anime > a');
      if (breadcrumbs.length >= 2) {
          showUrl = breadcrumbs[1].attributes['href'];
      }

      // Fallback Breadcrumbs (e.g. standard WP breadcrumbs)
      if (showUrl == null) {
          final bc = document.querySelectorAll('.breadcrumbs a, .breadcrumb a');
          for (var b in bc) {
             if (b.attributes['href']?.contains('/anime/') ?? false) {
                 showUrl = b.attributes['href'];
                 break;
             }
          }
      }

      if (showUrl == null) {
          try {
            final allEpLink = document.querySelectorAll('a').firstWhere(
              (a) => a.text.toLowerCase().contains('semua episode') || a.text.toLowerCase().contains('list episode'),
            ).attributes['href'];
            showUrl = allEpLink;
          } catch (_) {}
      }

      // Fetch episodes from Show Page if not already parsed and we have a Show URL
      if (allEpisodes.isEmpty && showUrl != null && showUrl != episode.originalUrl) {
           final showResponse = await http.get(
            Uri.parse(showUrl.startsWith('http') ? showUrl : '$anoboyBaseUrl$showUrl'),
            headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' },
          );
          if (showResponse.statusCode == 200) {
            final showDoc = parse(showResponse.body);
            allEpisodes = _parseAnoboyEpisodesFromDoc(showDoc, episode.showId);
          }
      }

      // Rating
      double? extractedRating;
      final scoreElement = document.querySelector('#score');
      if (scoreElement != null) {
        extractedRating = double.tryParse(scoreElement.text.trim());
      }

      allEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

      final navResult = findAnoboyNavigationLinks(document, currentEpisodeNumber, episode.title ?? '');
      String? prevEpisodeUrl = navResult['prev'];
      String? nextEpisodeUrl = navResult['next'];

      // Fallback/Override with list-based navigation
      final currentIdx = allEpisodes.indexWhere((e) => e.episodeNumber == currentEpisodeNumber);
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
        rating: extractedRating ?? show.rating,
        episodes: allEpisodes.isNotEmpty ? allEpisodes : null,
      );

       return Episode(
        id: episode.id,
        showId: episode.showId,
        episodeNumber: currentEpisodeNumber,
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

  @visibleForTesting
  Map<String, String?> findAnoboyNavigationLinks(Document document, int currentEpisodeNumber, String showTitle) {
    String? prevEpisodeUrl;
    String? nextEpisodeUrl;

    String cleanTitle = showTitle.toLowerCase();
    // Remove "episode ..." suffix to get base title for matching
    final epMatch = RegExp(r'(?:episode|ep)\s+\d+').firstMatch(cleanTitle);
    if (epMatch != null) {
      cleanTitle = cleanTitle.substring(0, epMatch.start).trim();
    }

    // Enhanced Prev/Next Scrape
    var navLinks = document.querySelectorAll('.naveps a, .entry-content a, .post-body a');
    if (navLinks.isEmpty) {
      navLinks = document.querySelectorAll('a');
    }

    for (var link in navLinks) {
      final text = link.text.trim().toLowerCase();
      final href = link.attributes['href'];
      if (href == null || href.isEmpty || href == '#') continue;

      // Check for specific keywords first
      if (text == 'episode sebelumnya' || text == 'prev' || text == 'sebelumnya' || text.contains('<< previous') || text.contains('previous episode')) {
        prevEpisodeUrl = href.startsWith('http') ? href : '$anoboyBaseUrl$href';
      } else if (text == 'episode selanjutnya' || text == 'next' || text == 'selanjutnya' || text.contains('next >>') || text.contains('next episode')) {
        nextEpisodeUrl = href.startsWith('http') ? href : '$anoboyBaseUrl$href';
      } else {
        // Heuristic: specific episode links in nav area
        // Often links like "Title Episode X"
        if (currentEpisodeNumber > 0) {
          final isGenericButton = RegExp(r'^(?:episode|ep)\s+\d+$').hasMatch(text);

          if (text.contains('episode ${currentEpisodeNumber - 1}')) {
             // Validate context: Must be generic button OR contain show title
             if (isGenericButton || (cleanTitle.isNotEmpty && text.contains(cleanTitle))) {
                prevEpisodeUrl = href.startsWith('http') ? href : '$anoboyBaseUrl$href';
             }
          } else if (text.contains('episode ${currentEpisodeNumber + 1}')) {
             // Validate context
             if (isGenericButton || (cleanTitle.isNotEmpty && text.contains(cleanTitle))) {
                nextEpisodeUrl = href.startsWith('http') ? href : '$anoboyBaseUrl$href';
             }
          }
        }
      }
    }
    return {'prev': prevEpisodeUrl, 'next': nextEpisodeUrl};
  }

  List<Episode> _parseAnoboyEpisodesFromDoc(dynamic document, int showId) {
    final List<Episode> eps = [];

    var contentContainers = document.querySelectorAll('.entry-content, .post-body, .episodelist, #content');

    List<Element> epLinks = [];
    if (contentContainers.isNotEmpty) {
      for (var container in contentContainers) {
        epLinks.addAll(container.querySelectorAll('a'));
      }
    } else {
      epLinks = document.querySelectorAll('a');
    }

    final seenUrls = <String>{};

    for (var link in epLinks) {
      final title = link.attributes['title'] ?? link.text.trim();
      final url = link.attributes['href'] ?? '';

      if (url.isEmpty || url.contains('#') || url.contains('facebook') || url.contains('twitter') || url.contains('whatsapp')) continue;
      if (!url.contains('anoboy')) continue;
      if (seenUrls.contains(url)) continue;

      if (title.contains('Episode') || title.contains('Ep ')) {
        int epNum = 0;
        final epMatch = RegExp(r'(?:Episode|Ep)\s+(\d+)').firstMatch(title);

        if (epMatch != null) {
          epNum = int.tryParse(epMatch.group(1)!) ?? 0;

          final fullUrl = url.startsWith('http') ? url : '$anoboyBaseUrl$url';
          final uniqueId = (fullUrl + title + epNum.toString()).hashCode;

          seenUrls.add(url);

          eps.add(Episode(
            id: uniqueId,
            showId: showId,
            episodeNumber: epNum,
            title: title,
            videoUrl: '',
            originalUrl: fullUrl,
          ));
        }
      }
    }
    return eps;
  }

  @visibleForTesting
  List<Map<String, String>> extractAnichinServers(Document document) {
    final List<Map<String, String>> videoServers = [];

    // Default iframe extraction
    var iframeElement = document.querySelector('iframe[src*="anichin.stream"]');
    iframeElement ??= document.querySelector('.video-content iframe');
    iframeElement ??= document.querySelector('iframe');

    String? primaryIframe = iframeElement?.attributes['src'];
    if (primaryIframe != null && primaryIframe.isNotEmpty) {
      videoServers.add({'name': 'Primary Server', 'url': primaryIframe});
    }

    // Mirror extraction
    final serverElements = document.querySelectorAll('.mirror option');
    if (serverElements.isNotEmpty) {
      for (var opt in serverElements) {
        String? url = opt.attributes['value'];
        final name = opt.text.trim();

        if (url != null && url.isNotEmpty) {
          // Check for Base64 encoding (Anichin uses this often now)
          if (url.startsWith('PG')) {
            try {
              final decoded = utf8.decode(base64.decode(url));
              // The decoded string is typically an HTML fragment like <iframe src="..."></iframe>
              final decodedDoc = parse(decoded);
              final src = decodedDoc.querySelector('iframe')?.attributes['src'];
              if (src != null) {
                url = src;
              }
            } catch (e) {
              debugPrint('Error decoding Anichin server: $e');
            }
          }

          videoServers.add({
            'name': name.isNotEmpty ? name : 'Server ${videoServers.length + 1}',
            'url': url!
          });
        }
      }
    }

    // Priority Sorting Logic
    videoServers.sort((a, b) {
      final nameA = a['name']!.toLowerCase();
      final nameB = b['name']!.toLowerCase();

      int getPriority(String name) {
        if (name.contains('dailymotion')) return 1;
        if (name.contains('rumble')) return 2;
        if (name.contains('ok.ru')) return 3;
        if (name.contains('gdrive 1')) return 4;
        if (name.contains('gdrive 2')) return 5;
        if (name.contains('vip 1')) return 6;
        return 99;
      }

      final pA = getPriority(nameA);
      final pB = getPriority(nameB);

      if (pA != pB) {
        return pA.compareTo(pB);
      }

      return 0;
    });

    return videoServers;
  }

  Future<Episode> getAnichinEpisodeDetails(Episode episode) async {
    if (episode.originalUrl == null || episode.originalUrl!.isEmpty) return episode;

    try {
      final response = await http.get(Uri.parse(episode.originalUrl!));
      if (response.statusCode != 200) return episode;

      final document = parse(response.body);

      int realEpNum = episode.episodeNumber;
      if (realEpNum == 0) {
        final titleText = document.querySelector('.entry-title')?.text ??
                          document.querySelector('.ts-breadcrumb li:last-child')?.text ??
                          '';
        if (titleText.isNotEmpty) {
           final match = RegExp(r'(?:Episode|Ep)\s+(\d+)').firstMatch(titleText);
           if (match != null) {
              realEpNum = int.tryParse(match.group(1)!) ?? 0;
           }
        }
      }

      final hasList = document.querySelector('.eplister') != null || document.querySelector('.lstep') != null || document.querySelector('.episodelist') != null;
      final isShowPage = hasList && document.querySelector('iframe') == null;

      if (isShowPage) {
         List<Episode> allEpisodes = [];
         var epElements = document.querySelectorAll('.eplister li a');
         if (epElements.isEmpty) epElements = document.querySelectorAll('.lstep li a');
         if (epElements.isEmpty) epElements = document.querySelectorAll('.episodelist li a');

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
             final targetEp = allEpisodes.firstWhere(
                (e) => e.episodeNumber == episode.episodeNumber,
                orElse: () => allEpisodes.first,
             );

             Episode detailedEp = targetEp;
             if (targetEp.originalUrl != episode.originalUrl) {
                detailedEp = await getAnichinEpisodeDetails(targetEp);
             }

             final fullShow = detailedEp.show ?? Show(id: episode.showId, title: episode.title ?? 'Donghua', type: 'donghua', status: 'ongoing', genres: []);
             final updatedShow = Show(
               id: fullShow.id,
               title: fullShow.title,
               type: fullShow.type,
               status: fullShow.status,
               genres: fullShow.genres,
               originalUrl: fullShow.originalUrl ?? episode.originalUrl,
               coverImageUrl: fullShow.coverImageUrl,
               rating: fullShow.rating,
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

      double? extractedRating;
      final metaContent = document.querySelector('meta[itemprop="ratingValue"]')?.attributes['content'];
      if (metaContent != null) {
        extractedRating = double.tryParse(metaContent);
      } else {
        final strongText = document.querySelector('.rating strong')?.text.trim();
        if (strongText != null) {
          final match = RegExp(r'Rating\s+(\d+\.?\d*)').firstMatch(strongText);
          if (match != null) {
            extractedRating = double.tryParse(match.group(1)!);
          }
        }
      }

      final List<Map<String, String>> videoServers = extractAnichinServers(document);

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

      final navLinks = document.querySelectorAll('.lm .nav-links a, .naveps a, a.btn');
      for (var a in navLinks) {
         final text = a.text.trim().toLowerCase();
         final href = a.attributes['href'];
         if (href == null || href.isEmpty) continue;

         if (text.contains('prev') || text.contains('sebelumnya')) {
           prevUrl = href;
         } else if (text.contains('next') || text.contains('selanjutnya')) {
           nextUrl = href;
         }
      }
      if (prevUrl == null && nextUrl == null) {
        for (var a in dlElements) {
           final text = a.text.trim().toLowerCase();
           if (text == 'prev' || text == 'sebelumnya' || text.contains('prev')) {
             prevUrl = a.attributes['href'];
           }
           if (text == 'next' || text == 'selanjutnya' || text.contains('next')) {
             nextUrl = a.attributes['href'];
           }
        }
      }

      List<Episode> allEpisodes = [];
      String? showUrl = document.querySelector('.breadcrumb a:nth-child(2)')?.attributes['href'];

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

      if (showUrl != null) {
        final showResponse = await http.get(Uri.parse(showUrl));
        if (showResponse.statusCode == 200) {
          final showDoc = parse(showResponse.body);
          var epElements = showDoc.querySelectorAll('.eplister li a');
          if (epElements.isEmpty) epElements = showDoc.querySelectorAll('.lstep li a');
          if (epElements.isEmpty) epElements = showDoc.querySelectorAll('.episodelist li a');

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
        rating: extractedRating ?? show.rating,
        episodes: allEpisodes.isNotEmpty ? allEpisodes : null,
      );

      return Episode(
        id: episode.id,
        showId: episode.showId,
        episodeNumber: realEpNum,
        title: episode.title,
        videoUrl: episode.videoUrl,
        iframeUrl: videoServers.isNotEmpty ? videoServers[0]['url'] : null,
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
          final thumb = _extractImageUrl(imgElement);

          String status = 'ongoing';
          if (title.toLowerCase().contains('completed') || title.toLowerCase().contains('tamat')) {
            status = 'completed';
          }

          shows.add(Show(
            id: url.hashCode,
            title: title.split(' Episode')[0].split(' Ep ')[0],
            type: 'anime',
            status: status,
            coverImageUrl: thumb,
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

  Future<List<Show>> getAnoboyAnimeList() async {
    try {
      final response = await http.get(
        Uri.parse('$anoboyBaseUrl/anime-list/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Show> shows = [];

      var content = document.querySelector('#ada') ?? document.querySelector('.entry-content') ?? document.querySelector('.post-body');

      final links = content != null ? content.querySelectorAll('a') : document.querySelectorAll('a[rel="bookmark"]');

      for (var link in links) {
        final title = link.attributes['title'] ?? link.text.trim();
        final url = link.attributes['href'] ?? '';

        if (title.isEmpty || title.length < 2) continue;
        if (!url.contains('anoboy')) continue;

        if (url.contains('/page/') || url.contains('wp-json') || url.contains('feed') || url.contains('comment-page')) continue;
        if (url.endsWith('#') || url.contains('#')) continue;

        if (['Home', 'Jadwal', 'AnimeList', 'DonghuaList', 'Movie', 'Tokusatsu', 'Live Action', 'Studio Ghibli', 'One Piece', 'Rekomendasi', 'Lapor Eror', 'Advertise'].contains(title)) continue;

        if (shows.any((s) => s.originalUrl == url)) continue;

        String status = 'ongoing';
        if (title.toLowerCase().contains('completed') || title.toLowerCase().contains('tamat')) {
          status = 'completed';
        }

        shows.add(Show(
          id: url.hashCode,
          title: title,
          type: 'anime',
          status: status,
          genres: [],
          originalUrl: url,
          coverImageUrl: '',
        ));
      }

      return shows;
    } catch (e) {
      debugPrint('Error getting Anoboy Anime List: $e');
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

          String status = 'ongoing';
          final statusEl = element.querySelector('.status') ?? element.querySelector('.sb') ?? element.querySelector('.limit .bt');
          if (statusEl != null) {
            final text = statusEl.text.trim().toLowerCase();
            if (text.contains('completed') || text.contains('end') || text.contains('tamat')) {
              status = 'completed';
            }
          }

          shows.add(Show(
            id: url.hashCode,
            title: title.split(' Episode')[0].split(' Ep ')[0],
            type: 'donghua',
            status: status,
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

      final tabContent = document.querySelector('.tab-content');
      if (tabContent != null) {
        final panes = tabContent.children;
        final tabs = document.querySelectorAll('.nav-tabs li a');
        for (int i=0; i < tabs.length && i < panes.length; i++) {
           final dayName = tabs[i].text.trim();
           final pane = panes[i];
           final shows = <Show>[];

           final items = pane.querySelectorAll('.bs');
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

      if (schedule.isEmpty) {
         final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu', 'Minggu'];
         final content = document.querySelector('.entry-content') ?? document.body;
         if (content != null) {
            String currentDay = '';
            for (var element in content.children) {
               final text = element.text.trim();
               if (days.any((d) => text.contains(d) && text.length < 20)) {
                  currentDay = text;
                  schedule[currentDay] = [];
               } else if (currentDay.isNotEmpty && schedule.containsKey(currentDay)) {
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
