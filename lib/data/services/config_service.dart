import 'dart:convert';
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();

  factory ConfigService() {
    return _instance;
  }

  ConfigService._internal();

  Future<void> fetchApiConfig() async {
    try {
      final response = await http.get(Uri.parse('https://raw.githubusercontent.com/rajasunrise/anidong/main/api.json'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        if (jsonList.isNotEmpty) {
          final Map<String, dynamic> config = jsonList[0];
          final String animeUrl = config['anime'] ?? '';
          final String donghuaUrl = config['donghua'] ?? '';

          ScrapingService.updateBaseUrls(animeUrl, donghuaUrl);
          debugPrint('Updated base URLs: Anime: $animeUrl, Donghua: $donghuaUrl');
        }
      } else {
        debugPrint('Failed to load API config: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching API config: $e');
    }
  }

  Future<List<Show>> fetchTrendings() async {
    try {
      final response = await http.get(Uri.parse('https://raw.githubusercontent.com/rajasunrise/anidong/main/trendings.json'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<Show> shows = [];

        for (var item in jsonList) {
          shows.add(Show(
            id: item['no'] ?? 0,
            title: item['nama'] ?? 'Unknown',
            type: 'donghua', // Defaulting to donghua
            status: 'Ongoing',
            coverImageUrl: item['imageurl'],
            originalUrl: '', // Not provided
            genres: [],
          ));
        }
        return shows;
      } else {
        debugPrint('Failed to load trendings: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching trendings: $e');
      return [];
    }
  }

  Future<Map<String, List<Show>>> fetchSchedule() async {
    try {
      final response = await http.get(Uri.parse('https://raw.githubusercontent.com/rajasunrise/anidong/main/jadwal.json'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final Map<String, List<Show>> schedule = {};

        for (var dayObj in jsonList) {
          final String day = dayObj['hari'] ?? '';
          if (day.isEmpty) continue;

          final List<dynamic> items = dayObj['items'] ?? [];
          final List<Show> shows = [];

          for (var item in items) {
            shows.add(Show(
              id: item['no'] ?? 0,
              title: item['nama'] ?? 'Unknown',
              type: 'donghua',
              status: 'ongoing',
              coverImageUrl: null,
              originalUrl: '', // Intentionally empty as source doesn't provide it
              genres: [],
            ));
          }
          if (shows.isNotEmpty) {
            schedule[day] = shows;
          }
        }
        return schedule;
      } else {
        debugPrint('Failed to load schedule: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      return {};
    }
  }

  Future<List<Show>> fetchSlider(String type) async {
    String url;
    if (type == 'anime') {
      url = 'https://raw.githubusercontent.com/rajasunrise/anidong/main/anime-slider.json';
    } else {
      url = 'https://raw.githubusercontent.com/rajasunrise/anidong/main/donghua-slider.json';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<Show> shows = [];

        for (var item in jsonList) {
          shows.add(Show(
            id: item['no'] ?? 0,
            title: item['nama'] ?? 'Unknown',
            type: type,
            status: 'Ongoing',
            coverImageUrl: item['imageurl'],
            bannerImageUrl: item['imageurl'],
            originalUrl: '',
            genres: [],
          ));
        }
        return shows;
      } else {
        debugPrint('Failed to load slider for $type: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching slider for $type: $e');
      return [];
    }
  }
}
