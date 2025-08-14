// lib/widgets/search/search_delegate.dart

import 'package:anidong/data/content_repository.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class AnidongSearchDelegate extends SearchDelegate {

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
    return _buildSearchResults();
  }

  // UI yang ditampilkan secara real-time saat pengguna mengetik
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final searchResults = ContentRepository.search(query);

    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Search for Anime or Donghua',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
        ),
      );
    }

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
        final item = searchResults[index];
        return _buildResultItem(item);
      },
    );
  }

  Widget _buildResultItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.image_outlined, color: AppColors.secondaryText)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']!,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['mode'] == 'anime' ? 'Anime' : 'Donghua',
                    style: TextStyle(
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
    );
  }
}
