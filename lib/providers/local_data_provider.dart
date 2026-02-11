// lib/providers/local_data_provider.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/database_helper.dart';
import 'package:flutter/material.dart';

class LocalDataProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

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
    _animeBookmarks = await _dbHelper.getBookmarks('anime');
    _donghuaBookmarks = await _dbHelper.getBookmarks('donghua');
    _history = await _dbHelper.getHistory();
    notifyListeners();
  }

  // Bookmarks
  bool isBookmarked(Show show) {
    if (show.type == 'anime') {
      return _animeBookmarks.any((item) => item.originalUrl == show.originalUrl);
    } else {
      return _donghuaBookmarks.any((item) => item.originalUrl == show.originalUrl);
    }
  }

  Future<void> toggleBookmark(Show show) async {
    if (isBookmarked(show)) {
      await _dbHelper.deleteBookmark(show);
      if (show.type == 'anime') {
        _animeBookmarks.removeWhere((item) => item.originalUrl == show.originalUrl);
      } else {
        _donghuaBookmarks.removeWhere((item) => item.originalUrl == show.originalUrl);
      }
    } else {
      await _dbHelper.insertBookmark(show);
      if (show.type == 'anime') {
        _animeBookmarks.add(show);
      } else {
        _donghuaBookmarks.add(show);
      }
    }
    notifyListeners();
  }

  // History
  Future<void> addToHistory(Episode episode) async {
    await _dbHelper.insertHistory(episode);

    // Refresh local list
    _history = await _dbHelper.getHistory();
    notifyListeners();
  }

  Future<void> removeFromHistory(Episode episode) async {
    if (episode.originalUrl != null) {
      await _dbHelper.deleteHistoryItem(episode.originalUrl!);
      _history.removeWhere((item) => item.originalUrl == episode.originalUrl);
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    await _dbHelper.clearHistory();
    _history.clear();
    notifyListeners();
  }
}
