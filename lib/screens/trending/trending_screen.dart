// lib/screens/trending/trending_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradien
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.orangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Konten
          SingleChildScrollView(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Teks
                  // PERBAIKAN: Menghapus 'const' karena memanggil MediaQuery di atas
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔥 Trending Now', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                        const SizedBox(height: 4),
                        Text('Discover what everyone is watching', style: TextStyle(fontSize: 14, color: AppColors.primaryText.withOpacity(0.8))),
                      ],
                    ),
                  ),
                  // Konten Utama
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildCategoryCards(),
                        const SizedBox(height: 24),
                        _buildTrendingList(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCards() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(Boxicons.bxs_crown, size: 40, color: AppColors.yellow400),
                const SizedBox(height: 8),
                const Text('Top Rated', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                const SizedBox(height: 2),
                Text('Best shows ever', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(Boxicons.bxs_time, size: 40, color: AppColors.green500),
                const SizedBox(height: 8),
                const Text('This Week', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                const SizedBox(height: 2),
                Text('Weekly favorites', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingList() {
    return Column(
      children: [
        _buildTrendingItem(rank: 1, title: 'Jujutsu Kaisen Season 2', genre: 'Action • Supernatural', rating: '9.2'),
        const SizedBox(height: 12),
        _buildTrendingItem(rank: 2, title: 'Chainsaw Man', genre: 'Action • Horror', rating: '8.9'),
        const SizedBox(height: 12),
        _buildTrendingItem(rank: 3, title: 'One Piece', genre: 'Adventure • Comedy', rating: '9.5'),
      ],
    );
  }

  Widget _buildTrendingItem({required int rank, required String title, required String genre, required String rating}) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('#$rank', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accent)),
          ),
          Container(width: 64, height: 80, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                Text(genre, style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Boxicons.bxs_star, color: AppColors.yellow400, size: 16),
                    const SizedBox(width: 4),
                    Text(rating, style: const TextStyle(fontSize: 14, color: AppColors.primaryText)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
