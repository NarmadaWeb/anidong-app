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
      return await _scrapingService.getAnoboyRecentEpisodes(page: page);
    } else if (type == 'donghua') {
      return await _scrapingService.getAnichinRecentEpisodes(page: page);
    } else {
      // Combined mode
      final results = await Future.wait([
        _scrapingService.getAnoboyRecentEpisodes(page: page),
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
      final eps = await _scrapingService.getAnoboyRecentEpisodes();
      return eps.map((e) => e.show!).toList();
    } else if (type == 'donghua') {
      return await _scrapingService.getAnichinRecommendations();
    } else {
      // Combined mode
      final results = await Future.wait([
        _scrapingService.getAnoboyRecentEpisodes(),
        _scrapingService.getAnichinRecommendations(),
      ]);
      final anoboyEps = results[0] as List<Episode>;
      final anichinShows = results[1] as List<Show>;
      final combined = [
        ...anoboyEps.map((e) => e.show!),
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
      // Anoboy doesn't have a clear popular section, using recent as placeholder
      final eps = await _scrapingService.getAnoboyRecentEpisodes();
      return eps.map((e) => e.show!).toList();
    } else if (type == 'donghua') {
      return await _scrapingService.getAnichinPopularToday();
    } else {
      final results = await Future.wait([
        _scrapingService.getAnoboyRecentEpisodes(),
        _scrapingService.getAnichinPopularToday(),
      ]);
      final anoboyEps = results[0] as List<Episode>;
      final anichinShows = results[1] as List<Show>;
      final combined = [
        ...anoboyEps.map((e) => e.show!),
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
      _scrapingService.searchAnoboy(query),
      _scrapingService.searchAnichin(query),
    ]);

    return [...results[0], ...results[1]];
  }

  Future<List<Show>> getAnimeList() async {
    if (_cachedAnimeList.isNotEmpty) return _cachedAnimeList;
    _cachedAnimeList = await _scrapingService.getAnoboyAnimeList();
    return _cachedAnimeList;
  }

  Future<List<Show>> searchAnimeLocal(String query) async {
    if (query.isEmpty) return [];
    if (_cachedAnimeList.isEmpty) {
      await getAnimeList();
    }

    final lowerQuery = query.toLowerCase();
    return _cachedAnimeList.where((show) =>
      show.title.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  Future<Episode> getEpisodeDetails(Episode episode) async {
    if (episode.show?.type == 'anime') {
      return await _scrapingService.getAnoboyEpisodeDetails(episode);
    } else {
      return await _scrapingService.getAnichinEpisodeDetails(episode);
    }
  }

  Future<Map<String, List<Show>>> getSchedule() async {
    return await _scrapingService.getAnichinSchedule();
  }
}
