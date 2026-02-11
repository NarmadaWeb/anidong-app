// lib/data/services/api_service.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:flutter/material.dart';

class ApiService {
  final ScrapingService _scrapingService = ScrapingService();

  // Endpoint: GET /episodes/recent
  Future<List<Episode>> getRecentEpisodes(BuildContext context, {String type = 'anime'}) async {
    if (type == 'anime') {
      return await _scrapingService.getAnoboyRecentEpisodes();
    } else if (type == 'donghua') {
      return await _scrapingService.getAnichinRecentEpisodes();
    } else {
      // Combined mode
      final results = await Future.wait([
        _scrapingService.getAnoboyRecentEpisodes(),
        _scrapingService.getAnichinRecentEpisodes(),
      ]);
      final combined = [...results[0], ...results[1]];
      combined.shuffle();
      return combined;
    }
  }

  // Endpoint: GET /shows/top-rated
  Future<List<Show>> getTopRatedShows(BuildContext context, {String type = 'anime'}) async {
    // For now, using search or a default list if scraping doesn't have top-rated
    // Or we can just return mixed results from recent as a placeholder for recommendations
    if (type == 'anime') {
      final eps = await _scrapingService.getAnoboyRecentEpisodes();
      return eps.map((e) => e.show!).toList();
    } else if (type == 'donghua') {
      final eps = await _scrapingService.getAnichinRecentEpisodes();
      return eps.map((e) => e.show!).toList();
    } else {
       final results = await Future.wait([
        _scrapingService.getAnoboyRecentEpisodes(),
        _scrapingService.getAnichinRecentEpisodes(),
      ]);
      final combined = [...results[0].map((e) => e.show!), ...results[1].map((e) => e.show!)];
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

  Future<Episode> getEpisodeDetails(Episode episode) async {
    if (episode.show?.type == 'anime') {
      return await _scrapingService.getAnoboyEpisodeDetails(episode);
    } else {
      return await _scrapingService.getAnichinEpisodeDetails(episode);
    }
  }
}
