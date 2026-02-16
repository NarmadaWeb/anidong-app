import 'package:anidong/data/services/scraping_service.dart';
import 'package:flutter/material.dart';

void main() async {
  print('Fetching Anichin episodes...');
  final service = ScrapingService();
  final episodes = await service.getAnichinRecentEpisodes();
  print('Episodes found: ${episodes.length}');
  if (episodes.isNotEmpty) {
    print('First episode: ${episodes.first.title}');
  } else {
    print('No episodes found. Scraping likely broken.');
  }
}
