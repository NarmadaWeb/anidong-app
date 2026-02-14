// lib/data/services/scraping_service.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class ScrapingService {
  // static String anoboyBaseUrl = 'https://ww1.anoboy.boo'; // Deprecated
  static String samehadakuBaseUrl = 'https://v1.samehadaku.how';
  static String anichinBaseUrl = 'https://anichin.asia';

  static void updateBaseUrls(String samehadaku, String anichin) {
    if (samehadaku.isNotEmpty) samehadakuBaseUrl = samehadaku;
    if (anichin.isNotEmpty) anichinBaseUrl = anichin;
  }

  String _extractImageUrl(Element? imgElement) {
    if (imgElement == null) return '';
    String thumb = imgElement.attributes['data-src'] ??
                   imgElement.attributes['data-lazy-src'] ??
                   imgElement.attributes['src'] ?? '';

    // Remove query params like ?quality=80 if present to get clean URL
    if (thumb.contains('?')) {
      thumb = thumb.split('?')[0];
    }

    if (thumb.startsWith('//')) {
      return 'https:$thumb';
    }
    if (thumb.isNotEmpty && !thumb.startsWith('http')) {
      return '$samehadakuBaseUrl$thumb';
    }
    return thumb;
  }

  // --- Samehadaku Implementation ---

  Future<List<Episode>> getSamehadakuLatestEpisodes({int page = 1}) async {
    try {
      final url = page > 1 ? '$samehadakuBaseUrl/page/$page/' : samehadakuBaseUrl;
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Episode> episodes = [];

      // Selector based on analysis: .post-show ul li
      final elements = document.querySelectorAll('.post-show ul li');
      for (var element in elements) {
        final titleElement = element.querySelector('.dtla .entry-title a');
        final imgElement = element.querySelector('.thumb a img');
        // 'span:first-of-type' is not supported by html package. Use a simpler selector or traversal.
        final authorElement = element.querySelector('.dtla span author');

        if (titleElement != null) {
          final title = titleElement.text.trim();
          final url = titleElement.attributes['href'] ?? '';
          final thumb = _extractImageUrl(imgElement);

          int epNum = 0;
          if (authorElement != null) {
             final epText = authorElement.text.trim(); // e.g., "Episode 12"
             final epMatch = RegExp(r'(?:Episode|Ep)\s*(\d+)').firstMatch(epText);
             if (epMatch != null) {
               epNum = int.tryParse(epMatch.group(1)!) ?? 0;
             }
          }

          // Fallback parsing from title if needed
          if (epNum == 0) {
             final epMatch = RegExp(r'(?:Episode|Ep)\s*(\d+)').firstMatch(title);
             if (epMatch != null) {
               epNum = int.tryParse(epMatch.group(1)!) ?? 0;
             }
          }

          final showTitle = title.replaceAll(RegExp(r'(?:Episode|Ep)\s*\d+.*', caseSensitive: false), '').trim();

          episodes.add(Episode(
            id: url.hashCode,
            showId: showTitle.hashCode,
            episodeNumber: epNum,
            title: title, // Full title including episode
            videoUrl: '',
            thumbnailUrl: thumb,
            originalUrl: url,
            show: Show(
              id: showTitle.hashCode,
              title: showTitle,
              type: 'anime',
              status: 'ongoing',
              genres: [],
              coverImageUrl: thumb,
              originalUrl: url, // Note: This is episode URL, ideally show URL
            ),
          ));
        }
      }
      return episodes;
    } catch (e) {
      debugPrint('Error scraping Samehadaku Latest: $e');
      return [];
    }
  }

  Future<List<Show>> getSamehadakuMovies() async {
    try {
      // Try specifically scraping the movie category
      String url = '$samehadakuBaseUrl/anime-movie/';
      var response = await http.get(
        Uri.parse(url),
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' },
      );

      // Fallback if 404 or redirect to home
      if (response.statusCode != 200) {
         url = '$samehadakuBaseUrl/movie/'; // Alternative slug
         response = await http.get(Uri.parse(url));
      }

      if (response.statusCode != 200) {
        // Ultimate fallback: Scrape home page and filter?
        // Or just return nothing.
        return [];
      }

      final document = parse(response.body);
      final List<Show> shows = [];

      // Selectors for lists usually .animpost or .animposx
      var elements = document.querySelectorAll('.animpost');
      if (elements.isEmpty) elements = document.querySelectorAll('.animposx');

      for (var element in elements) {
         final linkEl = element.querySelector('a');
         final imgEl = element.querySelector('img');
         final titleEl = element.querySelector('.title') ?? element.querySelector('h4');
         final typeEl = element.querySelector('.type');

         if (linkEl != null && titleEl != null) {
            final title = titleEl.text.trim();
            final href = linkEl.attributes['href'] ?? '';
            final thumb = _extractImageUrl(imgEl);
            final type = typeEl?.text.trim().toLowerCase() ?? 'movie';

            // Ensure it's likely a movie
            if (type.contains('tv') || type.contains('series')) continue;
            if (!type.contains('movie') && !url.contains('movie')) continue;

            shows.add(Show(
              id: href.hashCode,
              title: title,
              type: 'movie', // Explicitly movie
              status: 'completed', // Movies are usually completed
              genres: [],
              coverImageUrl: thumb,
              originalUrl: href,
            ));
         }
      }
      return shows;

    } catch (e) {
      debugPrint('Error scraping Samehadaku Movies: $e');
      return [];
    }
  }

  Future<List<Show>> searchSamehadaku(String query) async {
    try {
      final url = '$samehadakuBaseUrl/?s=${Uri.encodeComponent(query)}';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Show> shows = [];

      var elements = document.querySelectorAll('.animpost');
      if (elements.isEmpty) elements = document.querySelectorAll('.animposx');

      for (var element in elements) {
         final linkEl = element.querySelector('a');
         final imgEl = element.querySelector('img');
         final titleEl = element.querySelector('.title') ?? element.querySelector('h4');
         final typeEl = element.querySelector('.type');
         final scoreEl = element.querySelector('.score');

         if (linkEl != null && titleEl != null) {
            final title = titleEl.text.trim();
            final href = linkEl.attributes['href'] ?? '';
            final thumb = _extractImageUrl(imgEl);
            String typeRaw = typeEl?.text.trim().toLowerCase() ?? 'anime';
            String type = 'anime';
            if (typeRaw.contains('movie')) type = 'movie';

            String status = 'ongoing'; // Default
            // Status sometimes in .data .type or similar
            // We can try to parse from text or just default.
            // Samehadaku usually has status in details, not always on card.

            shows.add(Show(
              id: href.hashCode,
              title: title,
              type: type,
              status: status,
              rating: double.tryParse(scoreEl?.text.trim() ?? ''),
              genres: [],
              coverImageUrl: thumb,
              originalUrl: href,
            ));
         }
      }
      return shows;
    } catch (e) {
      debugPrint('Error searching Samehadaku: $e');
      return [];
    }
  }

  Future<Episode> getSamehadakuEpisodeDetails(Episode episode) async {
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

      // Detect if this is a Show Page (Info Anime) or Episode Page
      // Show page usually has .infoanime
      final isShowPage = document.querySelector('.infoanime') != null || episode.originalUrl!.contains('/anime/');

      List<Episode> allEpisodes = [];
      String? showUrl = episode.originalUrl;
      Show? updatedShowStruct;

      if (isShowPage) {
        // Parse Show Details & Episode List
        final infoBox = document.querySelector('.infoanime');
        String title = infoBox?.querySelector('.entry-title')?.text.trim() ?? episode.title ?? 'Unknown';
        String thumb = _extractImageUrl(infoBox?.querySelector('.thumb img'));
        String synopsis = infoBox?.querySelector('.desc')?.text.trim() ?? '';

        // Parse Episodes
        final epList = document.querySelectorAll('.lstepsiode.listeps ul li');
        for (var li in epList) {
           final a = li.querySelector('.epsright .eps a');
           // final date = li.querySelector('.epsleft .date')?.text.trim();
           final titleEp = li.querySelector('.epsleft .lchx a')?.text.trim(); // "Title Episode X"

           if (a != null) {
             final href = a.attributes['href'] ?? '';
             final epNumText = a.text.trim(); // "12" or "Episode 12"
             int epNum = int.tryParse(epNumText) ?? int.tryParse(epNumText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

             allEpisodes.add(Episode(
               id: href.hashCode,
               showId: episode.showId,
               episodeNumber: epNum,
               title: titleEp ?? 'Episode $epNum',
               videoUrl: '',
               originalUrl: href,
               show: null, // Will link later
             ));
           }
        }

        // Sort episodes (usually they are descending)
        allEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

        updatedShowStruct = Show(
           id: episode.showId,
           title: title,
           synopsis: synopsis,
           type: 'anime', // Or parse from genre
           status: 'ongoing', // Need to parse status field if available
           genres: [],
           coverImageUrl: thumb,
           originalUrl: showUrl,
           episodes: allEpisodes,
        );

        // If we are on Show Page, we need to return an Episode to play/display.
        // We pick the first one (lowest number) or the specific requested number?
        // Since input is "Episode", if it was a Show bookmark, epNum might be 1.

        Episode? targetEp;
        if (allEpisodes.isNotEmpty) {
           targetEp = allEpisodes.firstWhere((e) => e.episodeNumber == episode.episodeNumber, orElse: () => allEpisodes.first);

           // If we are just resolving the Show Details but need to play content, we must fetch the episode details of the target episode.
           // Recurse!
           if (targetEp.originalUrl != episode.originalUrl) {
              final deepEp = await getSamehadakuEpisodeDetails(targetEp);
              // Attach the full show info
              final fullShow = updatedShowStruct!.copyWith(episodes: allEpisodes);
              return deepEp.copyWith(show: fullShow);
           }
        }
      }

      // --- Episode Page Logic ---

      // Parse Video Player (iframe)
      final List<Map<String, String>> videoServers = [];
      String? primaryIframe;

      // Selectors based on scraping repo
      // Typically iframes are directly embedded or in tabs
      final iframes = document.querySelectorAll('iframe');
      for (var iframe in iframes) {
         final src = iframe.attributes['src'];
         if (src != null && src.isNotEmpty && !src.contains('facebook') && !src.contains('twitter')) {
            if (primaryIframe == null) primaryIframe = src;
            videoServers.add({
              'name': 'Server ${videoServers.length + 1}',
              'url': src
            });
         }
      }

      // Download Links
      final List<Map<String, String>> downloadLinks = [];
      final dlSections = document.querySelectorAll('.download-eps ul li');
      for (var li in dlSections) {
         final quality = li.querySelector('strong')?.text.trim() ?? 'Unknown';
         final links = li.querySelectorAll('a');
         for (var link in links) {
            final href = link.attributes['href'];
            final host = link.text.trim();
            if (href != null && href.isNotEmpty) {
               downloadLinks.add({
                 'name': '$quality - $host',
                 'url': href
               });
            }
         }
      }

      // Prev/Next Links
      String? prevUrl;
      String? nextUrl;

      // Usually .naveps or similar
      // final navs = document.querySelectorAll('.naveps a');
      // Or check specific classes
      for (var a in document.querySelectorAll('a[rel="prev"]')) {
         prevUrl = a.attributes['href'];
      }
      for (var a in document.querySelectorAll('a[rel="next"]')) {
         nextUrl = a.attributes['href'];
      }

      // If we are on Episode Page, we might want to populate show.episodes if missing
      // We can try to find "See all episodes" link
      if (allEpisodes.isEmpty) {
         final breadcrumbs = document.querySelectorAll('.breadcrumbs a, .breadcrumb a');
         for (var b in breadcrumbs) {
            final href = b.attributes['href'];
            if (href != null && href.contains('/anime/')) {
               showUrl = href;
               // We could fetch showUrl here to populate episodes list if critical
               // For now, let's just link it.
               break;
            }
         }

         // If we have showUrl and list is empty, fetch it?
         // User wants "Show all episodes". So yes, we should fetch it.
         if (showUrl != null && showUrl != episode.originalUrl) {
             try {
                final showResp = await http.get(Uri.parse(showUrl));
                if (showResp.statusCode == 200) {
                   final showDoc = parse(showResp.body);
                   final epList = showDoc.querySelectorAll('.lstepsiode.listeps ul li');
                   for (var li in epList) {
                       final a = li.querySelector('.epsright .eps a');
                       final titleEp = li.querySelector('.epsleft .lchx a')?.text.trim();
                       if (a != null) {
                           final href = a.attributes['href'] ?? '';
                           final epNumText = a.text.trim();
                           int epNum = int.tryParse(epNumText) ?? int.tryParse(epNumText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                           allEpisodes.add(Episode(
                               id: href.hashCode,
                               showId: episode.showId,
                               episodeNumber: epNum,
                               title: titleEp ?? 'Episode $epNum',
                               videoUrl: '',
                               originalUrl: href,
                           ));
                       }
                   }
                   allEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
                }
             } catch(e) { /* ignore */ }
         }
      }

      final currentShow = episode.show ?? Show(
        id: episode.showId,
        title: episode.title ?? 'Anime',
        type: 'anime',
        status: 'ongoing',
        genres: [],
        originalUrl: showUrl,
      );

      final updatedShow = Show(
         id: currentShow.id,
         title: currentShow.title,
         type: currentShow.type,
         status: currentShow.status,
         genres: currentShow.genres,
         originalUrl: showUrl ?? currentShow.originalUrl,
         coverImageUrl: currentShow.coverImageUrl,
         episodes: allEpisodes.isNotEmpty ? allEpisodes : currentShow.episodes,
      );

      return Episode(
        id: episode.id,
        showId: episode.showId,
        episodeNumber: episode.episodeNumber, // Should be correct from input or extracted
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
      debugPrint('Error getting Samehadaku details: $e');
      return episode;
    }
  }

  // --- Anichin Methods (Preserved) ---
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

  Future<Episode> getAnichinEpisodeDetails(Episode episode) async {
    if (episode.originalUrl == null || episode.originalUrl!.isEmpty) return episode;

    try {
      final response = await http.get(Uri.parse(episode.originalUrl!));
      if (response.statusCode != 200) return episode;

      final document = parse(response.body);

      // Extract real episode number if it was 0 (loaded from URL)
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

  // --- Stubs for deprecated methods (to keep build green until ApiService update) ---

  Future<List<Episode>> getAnoboyRecentEpisodes({int page = 1}) async => [];
  Future<List<Show>> getAnoboyAnimeList() async => [];
  Future<List<Show>> searchAnoboy(String query) async => [];
  Future<Episode> getAnoboyEpisodeDetails(Episode episode) async => episode;
}
