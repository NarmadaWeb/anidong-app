// lib/widgets/search/search_delegate.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/api_service.dart';
import 'package:anidong/screens/video_player_screen.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class AnidongSearchDelegate extends SearchDelegate {
  final ApiService _apiService = ApiService();

  // Mengubah tampilan tema agar sesuai dengan aplikasi
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.secondaryText),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.primaryText, fontSize: 18),
      ),
    );
  }

  // Tombol 'clear' (X) di sebelah kanan search bar
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: AppColors.secondaryText),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  // Tombol 'kembali' di sebelah kiri search bar
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.secondaryText),
      onPressed: () {
        close(context, null);
      },
    );
  }

  // UI yang ditampilkan saat pengguna menekan 'enter' atau tombol search
  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  // UI yang ditampilkan secara real-time saat pengguna mengetik
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Search for Anime or Donghua',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
        ),
      );
    }

    return FutureBuilder<List<Show>>(
      future: _apiService.searchShows(context, query), // ApiService search doesn't really use context now
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          );
        }

        final searchResults = snapshot.data ?? [];

        if (searchResults.isEmpty) {
          return Center(
            child: Text(
              'No results found for "$query"',
              style: const TextStyle(color: AppColors.secondaryText, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            final show = searchResults[index];
            return _buildResultItem(context, show);
          },
        );
      },
    );
  }

  Widget _buildResultItem(BuildContext context, Show show) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          final episode = Episode(
            id: show.id,
            showId: show.id,
            episodeNumber: 1,
            title: show.title,
            videoUrl: '',
            originalUrl: show.originalUrl,
            show: show,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(episode: episode),
            ),
          );
        },
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: show.coverImageUrl ?? '',
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 80,
                    color: AppColors.surface,
                    child: const Icon(Icons.image_outlined, color: AppColors.secondaryText),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      show.title,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      show.type.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Boxicons.bx_chevron_right, color: AppColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
