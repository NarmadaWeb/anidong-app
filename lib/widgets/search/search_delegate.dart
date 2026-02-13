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
    final theme = Theme.of(context);
    return theme.copyWith(
      scaffoldBackgroundColor: theme.scaffoldBackgroundColor,
      appBarTheme: theme.appBarTheme.copyWith(
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  // Tombol 'clear' (X) di sebelah kanan search bar
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
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
      icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
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
      return Center(
        child: Text(
          'Search for Anime or Donghua',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
        ),
      );
    }

    return FutureBuilder<List<Show>>(
      future: Future.wait([
        _apiService.searchAnimeLocal(query),
        _apiService.searchShows(context, query),
      ]).then((results) {
        final animeResults = results[0];
        final donghuaResults = results[1].where((s) => s.type == 'donghua').toList();
        return [...animeResults, ...donghuaResults];
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          );
        }

        final searchResults = snapshot.data ?? [];

        if (searchResults.isEmpty) {
          return Center(
            child: Text(
              'No results found for "$query"',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
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
                    color: Theme.of(context).cardColor,
                    child: Icon(Icons.image_outlined, color: Theme.of(context).iconTheme.color),
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
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      show.type.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Boxicons.bx_chevron_right, color: Theme.of(context).iconTheme.color),
            ],
          ),
        ),
      ),
    );
  }
}
