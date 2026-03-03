// lib/data/services/scraping_service.dart

import 'dart:convert';
import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/genre_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class ScrapingService {
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

    if (thumb.startsWith('//')) {
      return 'https:$thumb';
    }
    // For Samehadaku, relative paths often need the base URL
    if (thumb.isNotEmpty && !thumb.startsWith('http')) {
       return '$samehadakuBaseUrl$thumb';
    }
    return thumb;
  }

  Future<List<Episode>> getSamehadakuRecentEpisodes({int page = 1}) async {
    try {
      final url = page > 1 ? 'https://corsproxy.io/?url=${Uri.encodeComponent('$samehadakuBaseUrl/anime-terbaru/page/$page/')}' : 'https://corsproxy.io/?url=${Uri.encodeComponent('$samehadakuBaseUrl/anime-terbaru/')}';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Episode> episodes = [];

      final elements = document.querySelectorAll('.post-show ul li');
      for (var element in elements) {
        final titleElement = element.querySelector('.entry-title a');
        final title = titleElement?.text.trim() ?? element.querySelector('img')?.attributes['title'] ?? '';

        // Use the episode link inside .lstepsiode if available, or fallback to the show link
        var url = element.querySelector('.epsright a')?.attributes['href'];
        if (url == null || url.isEmpty) {
           url = titleElement?.attributes['href'] ?? element.querySelector('a')?.attributes['href'] ?? '';
        }

        final imgElement = element.querySelector('img');

        if (title.isNotEmpty && url.isNotEmpty) {
          final thumb = _extractImageUrl(imgElement);
          int epNum = 0;

          final epAuthor = element.querySelector('author[itemprop="name"]');
          if (epAuthor != null) {
            epNum = int.tryParse(epAuthor.text.trim()) ?? 0;
          } else {
             final epMatch = RegExp(r'(?:Episode|Ep)\s+(\d+)').firstMatch(title);
             if (epMatch != null) {
               epNum = int.tryParse(epMatch.group(1)!) ?? 0;
             }
          }

          final fullTitle = '$title Episode $epNum';

          episodes.add(Episode(
            id: url.hashCode,
            showId: title.hashCode,
            episodeNumber: epNum,
            title: fullTitle,
            videoUrl: '',
            thumbnailUrl: thumb,
            originalUrl: url.startsWith('http') ? url : '$samehadakuBaseUrl$url',
            show: Show(
              id: title.hashCode,
              title: title,
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
      debugPrint('Error scraping Samehadaku: $e');
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

  Future<Show> getAnichinShowDetails(Show show) async {
    if (show.originalUrl == null || show.originalUrl!.isEmpty) return show;

    try {
      final response = await http.get(
        Uri.parse(show.originalUrl!),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return show;

      final document = parse(response.body);
      return parseAnichinShowDetailsFromDoc(document, show);
    } catch (e) {
      debugPrint('Error getting Anichin Show Details: $e');
      return show;
    }
  }

  @visibleForTesting
  String? findAnichinShowUrl(Document document) {
    String? showUrl;

    // 1. Breadcrumbs Strategy (Most reliable)
    // Structure usually: Home > Show Title > Episode Title
    final bcs = document.querySelectorAll('.breadcrumb a, .breadcrumbs a');
    if (bcs.length > 1) {
       // Index 1 is usually the Show Title
       showUrl = bcs[1].attributes['href'];
    }

    // 2. "Semua Episode" Link Strategy
    if (showUrl == null) {
       final allLinks = document.querySelectorAll('a');
       for (var link in allLinks) {
          final text = link.text.trim().toLowerCase();
          final href = link.attributes['href'];

          if (href == null || href.isEmpty || href.startsWith('#')) continue;

          // Check if link text strongly indicates "All Episodes" or "Show Detail"
          if (text == 'semua episode' ||
              text == 'all episodes' ||
              text == 'list episode' ||
              text == 'detail anime' ||
              text == 'detail donghua' ||
              text.contains('lihat semua episode')) {

             // Basic sanity check: URL should not be just "/" or the current page
             if (href.startsWith('http') || href.startsWith('/')) {
                showUrl = href;
                break;
             }
          }
       }
    }

    // 3. Fallback: Check for specific classes
    if (showUrl == null) {
       final specificLink = document.querySelector('.all-episodes a, .list-episodes a, .show-info a');
       if (specificLink != null) {
          showUrl = specificLink.attributes['href'];
       }
    }

    // 4. Fallback: Search breadcrumbs for keyword if index 1 failed or wasn't applicable
    if (showUrl == null && bcs.isNotEmpty) {
       for (var b in bcs) {
          final href = b.attributes['href'];
          if (href != null && (href.contains('/donghua/') || href.contains('/anime/'))) {
             showUrl = href;
             break;
          }
       }
    }

    return showUrl;
  }

  @visibleForTesting
  Show parseAnichinShowDetailsFromDoc(Document document, Show show) {
    // Parse details
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

    String? synopsis;
    // Enhanced Synopsis Extraction
    final synEl = document.querySelector('.entry-content[itemprop="description"] p') ??
        document.querySelector('.entry-content p') ??
        document.querySelector('.desc');

    if (synEl != null) {
      synopsis = synEl.text.trim();
    } else {
      // Fallback: Try all paragraphs in entry-content and take the longest one
      final content = document.querySelector('.entry-content');
      if (content != null) {
        final paragraphs = content.querySelectorAll('p');
        String longest = '';
        for (var p in paragraphs) {
          final text = p.text.trim();
          if (text.length > longest.length) {
            longest = text;
          }
        }
        if (longest.isNotEmpty) synopsis = longest;
      }
    }

    // Cover Image Extraction
    String? coverImage = show.coverImageUrl;
    final imgEl = document.querySelector('.thumb img') ??
                 document.querySelector('.ts-post-image') ??
                 document.querySelector('.wp-post-image') ??
                 document.querySelector('div[itemprop="image"] img');

    if (imgEl != null) {
       final extracted = _extractImageUrl(imgEl);
       if (extracted.isNotEmpty) {
         coverImage = extracted;
       }
    }

    // Parse episodes
    List<Episode> allEpisodes = [];
    var epElements = document.querySelectorAll('.eplister li a');
    if (epElements.isEmpty) epElements = document.querySelectorAll('.lstep li a');
    if (epElements.isEmpty) epElements = document.querySelectorAll('.episodelist li a');

    for (var epEl in epElements) {
      final url = epEl.attributes['href'] ?? '';
      final numText = epEl.querySelector('.epl-num')?.text.trim() ?? '';
      final title = epEl.querySelector('.epl-title')?.text.trim() ?? '';

      String? thumb = epEl.querySelector('img')?.attributes['src'];
      thumb ??= epEl.querySelector('img')?.attributes['data-src'];

      if (url.isNotEmpty) {
        allEpisodes.add(Episode(
          id: url.hashCode,
          showId: show.id,
          episodeNumber: int.tryParse(numText) ?? 0,
          title: title,
          videoUrl: '',
          originalUrl: url,
          thumbnailUrl: thumb,
          show: show,
        ));
      }
    }

    return show.copyWith(
      rating: extractedRating,
      synopsis: synopsis,
      coverImageUrl: coverImage,
      episodes: allEpisodes.isNotEmpty ? allEpisodes : null,
    );
  }

  Future<Show> getSamehadakuShowDetails(Show show) async {
    if (show.originalUrl == null || show.originalUrl!.isEmpty) return show;

    try {
      final response = await http.get(
        Uri.parse('https://corsproxy.io/?url=${Uri.encodeComponent(show.originalUrl!)}'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return show;

      final document = parse(response.body);

      // Check for breadcrumbs or table links to redirect from Episode Page to Show Page
      String? parentShowUrl = _findSamehadakuParentShowUrl(document);

      if (parentShowUrl != null && parentShowUrl != show.originalUrl) {
         try {
           final parentResponse = await http.get(
             Uri.parse('https://corsproxy.io/?url=${Uri.encodeComponent(parentShowUrl.startsWith('http') ? parentShowUrl : '$samehadakuBaseUrl$parentShowUrl')}'),
             headers: {
               'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
             },
           );
           if (parentResponse.statusCode == 200) {
             final parentDoc = parse(parentResponse.body);
             return parseSamehadakuShowDetailsFromDoc(parentDoc, show.copyWith(originalUrl: parentShowUrl));
           }
         } catch (e) {
           debugPrint('Error redirecting to Samehadaku Show Page: $e');
         }
      }

      return parseSamehadakuShowDetailsFromDoc(document, show);

    } catch (e) {
      debugPrint('Error getting Samehadaku Show Details: $e');
      return show;
    }
  }

  @visibleForTesting
  String? findSamehadakuParentShowUrl(Document document) {
    return _findSamehadakuParentShowUrl(document);
  }

  String? _findSamehadakuParentShowUrl(Document document) {
    String? parentShowUrl;

    // Samehadaku usually has breadcrumbs with "Semua Episode" or an "All Episodes" link
    final allLinks = document.querySelectorAll('a');
    for (var link in allLinks) {
      final text = link.text.trim().toLowerCase();
      if (text == 'semua episode' || text == 'all episodes' || text == 'all episode') {
        parentShowUrl = link.attributes['href'];
        break;
      }
    }

    if (parentShowUrl == null) {
      // Look for breadcrumb or `.spe span a` that points to `/anime/`
      final breadcrumbs = document.querySelectorAll('.spe span a, .infox .spe a');
      for (var b in breadcrumbs) {
        if (b.attributes['href']?.contains('/anime/') ?? false) {
          parentShowUrl = b.attributes['href'];
          break;
        }
      }
    }

    return parentShowUrl;
  }

  @visibleForTesting
  Show parseSamehadakuShowDetailsFromDoc(Document document, Show show) {
      List<Episode> allEpisodes = _parseSamehadakuEpisodesFromDoc(document, show.id, showTitle: show.title);

      allEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

      // Parse details
      double? extractedRating;
      final ratingSpan = document.querySelector('.rating span, .score');
      if (ratingSpan != null) {
        extractedRating = double.tryParse(ratingSpan.text.trim());
      }

      String? studio;
      String? source;
      String? duration;
      List<Genre> genres = [];

      final metadataSpans = document.querySelectorAll('.spe span');
      for (var span in metadataSpans) {
        final text = span.text.trim();
        if (text.contains('Studio')) {
          studio = text.replaceAll('Studio', '').trim();
        } else if (text.contains('Source')) {
          source = text.replaceAll('Source', '').trim();
        } else if (text.contains('Duration')) {
          duration = text.replaceAll('Duration', '').trim();
        }
      }

      final genreLinks = document.querySelectorAll('.genre-info a, .mta a');
      for (var a in genreLinks) {
        final name = a.text.trim();
        if (name.isNotEmpty) {
          genres.add(Genre(id: name.hashCode, name: name));
        }
      }

      String? synopsis;
      final synEl = document.querySelector('.desc p, .entry-content p, .ttls');
      if (synEl != null) {
         synopsis = synEl.text.trim();
      }

      String? coverImage = show.coverImageUrl;
      if (coverImage == null || coverImage.isEmpty) {
         final imgEl = document.querySelector('.thumb img, .infox img');
         coverImage = _extractImageUrl(imgEl);
      }

      return show.copyWith(
        rating: extractedRating,
        synopsis: synopsis,
        coverImageUrl: coverImage,
        studio: studio,
        source: source,
        duration: duration,
        genres: genres.isNotEmpty ? genres : null,
        episodes: allEpisodes.isNotEmpty ? allEpisodes : null,
      );
  }

  Future<Episode> getSamehadakuEpisodeDetails(Episode episode) async {
    if (episode.originalUrl == null || episode.originalUrl!.isEmpty) return episode;

    try {
      final response = await http.get(
        Uri.parse('https://corsproxy.io/?url=${Uri.encodeComponent(episode.originalUrl!)}'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return episode;

      final document = parse(response.body);

      int currentEpisodeNumber = episode.episodeNumber;
      if (currentEpisodeNumber == 0) {
          final titleText = document.querySelector('title')?.text ?? '';
          var match = RegExp(r'(?:Episode|Ep)\s+(\d+)', caseSensitive: false).firstMatch(titleText);
          if (match != null) {
             currentEpisodeNumber = int.tryParse(match.group(1)!) ?? 0;
          }
      }

      final hasPlayer = document.querySelector('iframe') != null || document.querySelector('.player-area') != null || document.querySelector('.east_player_option') != null;
      bool isShowPage = !hasPlayer;

      String? showUrl = _findSamehadakuParentShowUrl(document);

      if (isShowPage) {
         String coverImage = episode.thumbnailUrl ?? '';
         if (coverImage.isEmpty) {
             final imgEl = document.querySelector('.thumb img, .infox img');
             coverImage = _extractImageUrl(imgEl);
         }

         List<Episode> allEpisodes = _parseSamehadakuEpisodesFromDoc(document, episode.showId);

         if (allEpisodes.isNotEmpty) {
            final targetEp = allEpisodes.firstWhere(
               (e) => e.episodeNumber == episode.episodeNumber,
               orElse: () => allEpisodes.first,
            );

            if (targetEp.originalUrl != episode.originalUrl) {
               final detailedEp = await getSamehadakuEpisodeDetails(targetEp);
                final fullShow = detailedEp.show ?? Show(
                    id: episode.showId,
                    title: episode.title ?? 'Anime',
                    type: 'anime',
                    status: 'ongoing',
                    genres: [],
                    coverImageUrl: coverImage,
                    originalUrl: showUrl ?? episode.originalUrl,
                );

                final updatedShow = Show(
                    id: fullShow.id,
                    title: fullShow.title,
                    type: fullShow.type,
                    status: fullShow.status,
                    genres: fullShow.genres,
                    originalUrl: fullShow.originalUrl,
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

      final List<Map<String, String>> videoServers = [];
      String? primaryIframe;
      final List<Map<String, String>> downloadLinks = [];

      // Samehadaku video servers logic
      final iframeElement = document.querySelector('.player-area iframe') ?? document.querySelector('iframe[src*="youtube"]');
      if (iframeElement != null) {
          primaryIframe = iframeElement.attributes['src'];
          if (primaryIframe != null) {
            videoServers.add({
              'name': 'Primary Server',
              'url': primaryIframe
            });
          }
      }

      final serverElements = document.querySelectorAll('.east_player_option');
      for (var server in serverElements) {
         final name = server.text.trim();
         final dataPost = server.attributes['data-post'];
         final dataNume = server.attributes['data-nume'];
         final dataType = server.attributes['data-type'];

         if (dataPost != null && dataNume != null && dataType != null) {
            if (primaryIframe == null && videoServers.isEmpty) {
                 try {
                     final ajaxUrl = '$samehadakuBaseUrl/wp-admin/admin-ajax.php';
                     final postResponse = await http.post(
                         Uri.parse('https://corsproxy.io/?url=${Uri.encodeComponent(ajaxUrl)}'),
                         headers: {
                             'Content-Type': 'application/x-www-form-urlencoded',
                             'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                         },
                         body: 'action=player_ajax&post=$dataPost&nume=$dataNume&type=$dataType'
                     );

                     if (postResponse.statusCode == 200) {
                         final iframeHtml = postResponse.body;
                         final iframeDoc = parse(iframeHtml);
                         final src = iframeDoc.querySelector('iframe')?.attributes['src'];
                         if (src != null) {
                             primaryIframe = src;
                             videoServers.add({
                                'name': name.isNotEmpty ? name : 'Server 1',
                                'url': src
                             });
                         }
                     }
                 } catch (e) {
                     debugPrint('Error fetching samehadaku iframe: $e');
                 }
            } else {
                 // Provide a fallback placeholder or logic for other servers if needed
            }
         }
      }

      final dlElements = document.querySelectorAll('.download-eps ul li a');
      for (var dl in dlElements) {
          final name = dl.text.trim();
          final link = dl.attributes['href'];
          if (link != null && link.isNotEmpty && link != '#') {
            String dlName = name;
            // Try to find resolution
            final parentLi = dl.parent?.parent; // li > span > a
            if (parentLi != null && parentLi.localName == 'li') {
               final resText = parentLi.querySelector('strong')?.text.trim() ?? '';
               if (resText.isNotEmpty) {
                  dlName = '$resText $name';
               }
            }

            downloadLinks.add({
              'name': dlName,
              'url': link
            });
          }
      }

      List<Episode> allEpisodes = [];
      if (showUrl != null && showUrl != episode.originalUrl) {
           final showResponse = await http.get(
            Uri.parse('https://corsproxy.io/?url=${Uri.encodeComponent(showUrl.startsWith('http') ? showUrl : '$samehadakuBaseUrl$showUrl')}'),
            headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' },
          );
          if (showResponse.statusCode == 200) {
            final showDoc = parse(showResponse.body);
            allEpisodes = _parseSamehadakuEpisodesFromDoc(showDoc, episode.showId);
          }
      }

      double? extractedRating;
      final ratingSpan = document.querySelector('.rating span, .score');
      if (ratingSpan != null) {
        extractedRating = double.tryParse(ratingSpan.text.trim());
      }

      allEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

      final navResult = findSamehadakuNavigationLinks(document);
      String? prevEpisodeUrl = navResult['prev'];
      String? nextEpisodeUrl = navResult['next'];

      if (allEpisodes.isNotEmpty) {
         final currentIdx = allEpisodes.indexWhere((e) => e.episodeNumber == currentEpisodeNumber);
         if (currentIdx != -1) {
           if (currentIdx > 0 && prevEpisodeUrl == null) prevEpisodeUrl = allEpisodes[currentIdx - 1].originalUrl;
           if (currentIdx < allEpisodes.length - 1 && nextEpisodeUrl == null) nextEpisodeUrl = allEpisodes[currentIdx + 1].originalUrl;
         }
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
      debugPrint('Error getting Samehadaku details: $e');
      return episode;
    }
  }

  @visibleForTesting
  Map<String, String?> findSamehadakuNavigationLinks(Document document) {
    String? prevEpisodeUrl;
    String? nextEpisodeUrl;

    final navLinks = document.querySelectorAll('.naveps .nvsc a, .naveps a, .nvs a');

    for (var link in navLinks) {
      final text = link.text.trim().toLowerCase();
      final href = link.attributes['href'];
      if (href == null || href.isEmpty || href == '#') continue;

      if (text.contains('prev') || text.contains('sebelumnya') || link.querySelector('.fa-angle-left') != null || link.querySelector('.fa-chevron-left') != null) {
        prevEpisodeUrl = href.startsWith('http') ? href : '$samehadakuBaseUrl$href';
      } else if (text.contains('next') || text.contains('selanjutnya') || link.querySelector('.fa-angle-right') != null || link.querySelector('.fa-chevron-right') != null) {
        nextEpisodeUrl = href.startsWith('http') ? href : '$samehadakuBaseUrl$href';
      }
    }

    return {'prev': prevEpisodeUrl, 'next': nextEpisodeUrl};
  }

  List<Episode> _parseSamehadakuEpisodesFromDoc(dynamic document, int showId, {String? showTitle}) {
    final List<Episode> eps = [];
    final seenUrls = <String>{};

    final epElements = document.querySelectorAll('.lstepsiode ul li');
    for (var element in epElements) {
       final link = element.querySelector('.epsleft .lchx a');
       if (link == null) continue;

       final title = link.text.trim();
       final url = link.attributes['href'] ?? '';

       if (url.isEmpty || seenUrls.contains(url)) continue;

       int epNum = 0;
       final epsSpan = element.querySelector('.epsright .eps a');
       if (epsSpan != null) {
          epNum = int.tryParse(epsSpan.text.trim()) ?? 0;
       } else {
          final epMatch = RegExp(r'(?:Episode|Ep)\s+(\d+)').firstMatch(title);
          if (epMatch != null) {
            epNum = int.tryParse(epMatch.group(1)!) ?? 0;
          }
       }

       seenUrls.add(url);

       eps.add(Episode(
         id: url.hashCode,
         showId: showId,
         episodeNumber: epNum,
         title: title,
         videoUrl: '',
         originalUrl: url.startsWith('http') ? url : '$samehadakuBaseUrl$url',
       ));
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
      String? showUrl = findAnichinShowUrl(document);

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

  Future<List<Show>> searchSamehadaku(String query) async {
    try {
      final response = await http.get(
        Uri.parse('https://corsproxy.io/?url=${Uri.encodeComponent('$samehadakuBaseUrl/?s=${Uri.encodeComponent(query)}')}' ),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Show> shows = [];

      final elements = document.querySelectorAll('.animepost');
      for (var element in elements) {
        final linkElement = element.querySelector('a');
        if (linkElement == null) continue;

        final url = linkElement.attributes['href'] ?? '';

        final titleElement = element.querySelector('.entry-title') ?? element.querySelector('img');
        final title = titleElement?.text.trim().isNotEmpty == true
             ? titleElement!.text.trim()
             : (element.querySelector('img')?.attributes['title'] ?? '');

        final imgElement = element.querySelector('img');

        if (title.isNotEmpty && url.isNotEmpty) {
          final thumb = _extractImageUrl(imgElement);

          String status = 'ongoing';
          final typeText = element.querySelector('.type')?.text.trim().toLowerCase() ?? '';
          if (typeText.contains('completed') || typeText.contains('tamat') || title.toLowerCase().contains('completed') || title.toLowerCase().contains('tamat')) {
            status = 'completed';
          }

          shows.add(Show(
            id: url.hashCode,
            title: title,
            type: 'anime',
            status: status,
            coverImageUrl: thumb,
            originalUrl: url.startsWith('http') ? url : '$samehadakuBaseUrl$url',
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

  Future<List<Show>> getSamehadakuAnimeList() async {
    try {
      final response = await http.get(
        Uri.parse('https://corsproxy.io/?url=${Uri.encodeComponent('$samehadakuBaseUrl/daftar-anime-2/')}' ),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Show> shows = [];

      final links = document.querySelectorAll('.listab a, .listt a, .s_list a');

      for (var link in links) {
        final title = link.text.trim();
        final url = link.attributes['href'] ?? '';

        if (title.isEmpty || title.length < 2) continue;

        if (shows.any((s) => s.originalUrl == url)) continue;

        shows.add(Show(
          id: url.hashCode,
          title: title,
          type: 'anime',
          status: 'completed', // list typically has completed/ongoing mixed but mostly it's an index
          genres: [],
          originalUrl: url.startsWith('http') ? url : '$samehadakuBaseUrl$url',
          coverImageUrl: '',
        ));
      }

      return shows;
    } catch (e) {
      debugPrint('Error getting Samehadaku Anime List: $e');
      return [];
    }
  }

  Future<List<Show>> getSamehadakuMovies() async {
    try {
      final response = await http.get(
        Uri.parse('https://corsproxy.io/?url=${Uri.encodeComponent('$samehadakuBaseUrl/anime-movie/')}' ),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Show> shows = [];

      final elements = document.querySelectorAll('.animepost');
      for (var element in elements) {
        final linkElement = element.querySelector('a');
        if (linkElement == null) continue;

        final url = linkElement.attributes['href'] ?? '';

        final titleElement = element.querySelector('.entry-title') ?? element.querySelector('img');
        final title = titleElement?.text.trim().isNotEmpty == true
             ? titleElement!.text.trim()
             : (element.querySelector('img')?.attributes['title'] ?? '');

        final imgElement = element.querySelector('img');

        if (title.isNotEmpty && url.isNotEmpty) {
          final thumb = _extractImageUrl(imgElement);

          shows.add(Show(
            id: url.hashCode,
            title: title,
            type: 'movie',
            status: 'completed',
            coverImageUrl: thumb,
            originalUrl: url.startsWith('http') ? url : '$samehadakuBaseUrl$url',
            genres: [],
          ));
        }
      }

      final seenTitles = <String>{};
      return shows.where((s) => seenTitles.add(s.title)).toList();
    } catch (e) {
      debugPrint('Error getting Samehadaku Movies: $e');
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
