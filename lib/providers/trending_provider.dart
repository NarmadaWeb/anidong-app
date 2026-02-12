import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/api_service.dart';
import 'package:flutter/material.dart';

enum TrendingState { initial, loading, loaded, error }

class TrendingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Show> _topRatedShows = [];
  TrendingState _state = TrendingState.initial;
  String _errorMessage = '';

  List<Show> get topRatedShows => _topRatedShows;
  TrendingState get state => _state;
  String get errorMessage => _errorMessage;

  TrendingProvider(); // No longer calls fetchTrendingPageData directly

  Future<void> fetchTrendingPageData(BuildContext context) async {
    _state = TrendingState.loading;
    notifyListeners();

    try {
      _topRatedShows = await _apiService.getPopularShows(context, type: 'combined');
      _state = TrendingState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _state = TrendingState.error;
    }

    notifyListeners();
  }
}
