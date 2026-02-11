// lib/providers/local_data_provider.dart

import 'dart:convert';
import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataProvider with ChangeNotifier {
  static const String _keyAnimeBookmarks = 'anime_bookmarks';
  static const String _keyDonghuaBookmarks = 'donghua_bookmarks';
  static const String _keyHistory = 'watch_history';

  List<Show> _animeBookmarks = [];
  List<Show> _donghuaBookmarks = [];
  List<Episode> _history = [];

  List<Show> get animeBookmarks => _animeBookmarks;
  List<Show> get donghuaBookmarks => _donghuaBookmarks;
  List<Episode> get history => _history;

  LocalDataProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final animeJson = prefs.getStringList(_keyAnimeBookmarks) ?? [];
    _animeBookmarks = animeJson
        .map((item) => Show.fromJson(jsonDecode(item)))
        .toList();

    final donghuaJson = prefs.getStringList(_keyDonghuaBookmarks) ?? [];
    _donghuaBookmarks = donghuaJson
        .map((item) => Show.fromJson(jsonDecode(item)))
        .toList();

    final historyJson = prefs.getStringList(_keyHistory) ?? [];
    _history = historyJson
        .map((item) => Episode.fromJson(jsonDecode(item)))
        .toList();

    notifyListeners();
  }

  // Bookmarks
  bool isBookmarked(Show show) {
    if (show.type == 'anime') {
      return _animeBookmarks.any((item) => item.id == show.id || item.originalUrl == show.originalUrl);
    } else {
      return _donghuaBookmarks.any((item) => item.id == show.id || item.originalUrl == show.originalUrl);
    }
  }

  Future<void> toggleBookmark(Show show) async {
    final prefs = await SharedPreferences.getInstance();
    if (show.type == 'anime') {
      if (isBookmarked(show)) {
        _animeBookmarks.removeWhere((item) => item.id == show.id || item.originalUrl == show.originalUrl);
      } else {
        _animeBookmarks.add(show);
      }
      await prefs.setStringList(_keyAnimeBookmarks, _animeBookmarks.map((item) => jsonEncode(item.toJson())).toList());
    } else {
      if (isBookmarked(show)) {
        _donghuaBookmarks.removeWhere((item) => item.id == show.id || item.originalUrl == show.originalUrl);
      } else {
        _donghuaBookmarks.add(show);
      }
      await prefs.setStringList(_keyDonghuaBookmarks, _donghuaBookmarks.map((item) => jsonEncode(item.toJson())).toList());
    }
    notifyListeners();
  }

  // History
  Future<void> addToHistory(Episode episode) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove if exists (to move it to top)
    _history.removeWhere((item) => item.originalUrl == episode.originalUrl);

    // Add to top
    _history.insert(0, episode);

    // Keep only last 50 items
    if (_history.length > 50) {
      _history = _history.sublist(0, 50);
    }

    await prefs.setStringList(_keyHistory, _history.map((item) => jsonEncode(item.toJson())).toList());
    notifyListeners();
  }

  Future<void> removeFromHistory(Episode episode) async {
    final prefs = await SharedPreferences.getInstance();
    _history.removeWhere((item) => item.originalUrl == episode.originalUrl);
    await prefs.setStringList(_keyHistory, _history.map((item) => jsonEncode(item.toJson())).toList());
    notifyListeners();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _history.clear();
    await prefs.remove(_keyHistory);
    notifyListeners();
  }
}
