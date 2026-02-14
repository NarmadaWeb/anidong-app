// lib/data/services/api_service.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/config_service.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:flutter/material.dart';

class ApiService {
  final ScrapingService _scrapingService = ScrapingService();
  List<Show> _cachedAnimeList = [];

  // Endpoint: GET /episodes/recent
  Future<List<Episode>> getRecentEpisodes(BuildContext context, {String type = 'anime', int page = 1}) async {
    if (type == 'anime') {
      return await _scrapingService.getSamehadakuLatestEpisodes(page: page);
    } else if (type == 'donghua') {
      return await _scrapingService.getAnichinRecentEpisodes(page: page);
    } else {
      // Combined mode
      final results = await Future.wait([
        _scrapingService.getSamehadakuLatestEpisodes(page: page),
        _scrapingService.getAnichinRecentEpisodes(page: page),
      ]);
      final combined = [...results[0], ...results[1]];
      combined.shuffle();
      return combined;
    }
  }

  // Endpoint: GET /shows/top-rated (Recommendations)
  Future<List<Show>> getTopRatedShows(BuildContext context, {String type = 'combined'}) async {
    if (type == 'anime') {
      // Use Movies for Anime recommendations as requested
      return await _scrapingService.getSamehadakuMovies();
    } else if (type == 'donghua') {
      return await _scrapingService.getAnichinRecommendations();
    } else {
      // Combined mode
      final results = await Future.wait([
        _scrapingService.getSamehadakuMovies(),
        _scrapingService.getAnichinRecommendations(),
      ]);
      final samehadakuMovies = results[0];
      final anichinShows = results[1];
      final combined = [
        ...samehadakuMovies,
        ...anichinShows
      ];
      combined.shuffle();
      return combined;
    }
  }

  Future<List<Show>> getTrendingShows() async {
    return await ConfigService().fetchTrendings();
  }

  Future<List<Show>> getPopularShows(BuildContext context, {String type = 'combined'}) async {
    if (type == 'anime') {
      // Samehadaku doesn't have a clear popular section exposed in service yet, using recent as placeholder
      final eps = await _scrapingService.getSamehadakuLatestEpisodes();
      return eps.map((e) => e.show!).toList();
    } else if (type == 'donghua') {
      return await _scrapingService.getAnichinPopularToday();
    } else {
      final results = await Future.wait([
        _scrapingService.getSamehadakuLatestEpisodes(),
        _scrapingService.getAnichinPopularToday(),
      ]);
      final samehadakuEps = results[0] as List<Episode>;
      final anichinShows = results[1] as List<Show>;
      final combined = [
        ...samehadakuEps.map((e) => e.show!),
        ...anichinShows
      ];
      combined.shuffle();
      return combined;
    }
  }

  // Endpoint: GET /shows/search?q={title}
  Future<List<Show>> searchShows(BuildContext context, String query) async {
    if (query.isEmpty) return [];

    final results = await Future.wait([
      _scrapingService.searchSamehadaku(query),
      _scrapingService.searchAnichin(query),
    ]);

    return [...results[0], ...results[1]];
  }

  Future<List<Show>> getAnimeList() async {
    // Samehadaku doesn't have a single-page list API implemented.
    // Returning empty to force live search or use cached if available.
    return [];
  }

  Future<List<Show>> searchAnimeLocal(String query) async {
    // Local search deprecated in favor of live search for Samehadaku
    // But keeping method signature for compatibility
    return [];
  }

  Future<Episode> getEpisodeDetails(Episode episode) async {
    if (episode.show?.type == 'anime' || (episode.originalUrl?.contains('samehadaku') ?? false)) {
      return await _scrapingService.getSamehadakuEpisodeDetails(episode);
    } else {
      return await _scrapingService.getAnichinEpisodeDetails(episode);
    }
  }

  Future<Map<String, List<Show>>> getSchedule() async {
    return await ConfigService().fetchSchedule();
  }
}
