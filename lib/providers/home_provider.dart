// lib/providers/home_provider.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/api_service.dart';
import 'package:flutter/material.dart';

// Enum untuk merepresentasikan state dari halaman utama
enum HomeState { initial, loading, loaded, error }

class HomeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Properti privat untuk menyimpan data dan state
  List<Episode> _recentEpisodes = [];
  List<Show> _recommendedShows = [];
  List<Show> _popularToday = [];
  HomeState _state = HomeState.initial;
  String _errorMessage = '';
  String _currentMode = 'anime';

  // Getter publik agar UI bisa mengakses data tanpa bisa mengubahnya langsung
  List<Episode> get recentEpisodes => _recentEpisodes;
  List<Show> get recommendedShows => _recommendedShows;
  List<Show> get popularToday => _popularToday;
  HomeState get state => _state;
  String get errorMessage => _errorMessage;
  String get currentMode => _currentMode;

  // Constructor ini akan langsung memanggil API saat provider pertama kali dibuat
  HomeProvider(); // No longer calls fetchHomePageData directly

  Future<void> changeMode(BuildContext context, String newMode) async {
    if (_currentMode == newMode) return;
    _currentMode = newMode;
    notifyListeners();
    await fetchHomePageData(context);
  }

  // Metode utama untuk mengambil semua data yang dibutuhkan oleh halaman utama
  Future<void> fetchHomePageData(BuildContext context) async {
    // Set state ke loading dan beri tahu UI untuk update (menampilkan spinner)
    _state = HomeState.loading;
    notifyListeners();

    try {
      // Panggil API secara bersamaan untuk efisiensi
      final results = await Future.wait([
        _apiService.getRecentEpisodes(context, type: _currentMode),
        _apiService.getTopRatedShows(context, type: _currentMode), // Recommendations
        _apiService.getPopularShows(context, type: _currentMode),
      ]);

      // Simpan hasil ke properti privat
      _recentEpisodes = results[0] as List<Episode>;
      _recommendedShows = results[1] as List<Show>;
      _popularToday = results[2] as List<Show>;

      // --- PRINT UNTUK DEBUGGING ---
      // Ini akan muncul di Debug Console Anda saat aplikasi berjalan
      debugPrint("=========================================");
      debugPrint("======= DEBUGGING: HomeProvider =======");
      debugPrint("=========================================");
      debugPrint("=> Mode Saat Ini: $_currentMode");
      debugPrint("=> Jumlah Episode Terbaru Diterima: ${_recentEpisodes.length}");
      debugPrint("=> Jumlah Top Rated Diterima: ${_recommendedShows.length}");

      // Periksa konten dari list Top Rated jika tidak kosong
      if (_recommendedShows.isNotEmpty) {
        debugPrint("\n--- Detail Top Rated Shows ---");
        for (var show in _recommendedShows) {
          debugPrint("  - ID: ${show.id}, Judul: ${show.title}, Tipe: ${show.type}");
        }
      } else {
        debugPrint("  - Tidak ada data Top Rated yang diterima atau diparsing.");
      }
      debugPrint("=========================================\n");
      // --- AKHIR DARI PRINT UNTUK DEBUGGING ---

      // Set state ke loaded karena data sudah siap
      _state = HomeState.loaded;

    } catch (e) {
      // Jika terjadi error, simpan pesan error dan set state ke error
      _errorMessage = e.toString().replaceFirst("Exception: ", ""); // Membersihkan pesan error
      _state = HomeState.error;

      // --- PRINT ERROR UNTUK DEBUGGING ---
      debugPrint("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      debugPrint("!!!! ERROR di HomeProvider: $e !!!!");
      debugPrint("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    }

    // Beri tahu UI sekali lagi untuk update (menampilkan data atau pesan error)
    notifyListeners();
  }

  Future<Episode> getEpisodeDetails(Episode episode) async {
    return await _apiService.getEpisodeDetails(episode);
  }
}
