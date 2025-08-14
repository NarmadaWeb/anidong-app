// lib/screens/explore/explore_screen.dart

import 'package:flutter/material.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN: Menggunakan Scaffold TANPA AppBar
    return Scaffold(
      backgroundColor: AppColors.background,
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
          // Konten yang bisa di-scroll
          SingleChildScrollView(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Teks
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 56.0, 16.0, 24.0), // Tambah padding atas
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🎭 Explore Genres', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                        const SizedBox(height: 4),
                        Text('Discover anime by your favorite genres', style: TextStyle(fontSize: 14, color: AppColors.primaryText.withOpacity(0.8))),
                      ],
                    ),
                  ),
                  // Konten utama halaman
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildGenreGrid(),
                        const SizedBox(height: 24),
                        _buildSubGenreGrid(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget-widget lainnya tetap sama persis seperti sebelumnya ---
  // ... (salin semua metode _build di sini)
    Widget _buildGenreGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _buildGenreCard(
          emoji: '⚔️', title: 'Action', description: 'Fast-paced adventures', count: '150+ shows',
          gradientColors: [AppColors.actionGradientStart, AppColors.actionGradientEnd],
        ),
        _buildGenreCard(
          emoji: '💖', title: 'Romance', description: 'Heart-warming stories', count: '80+ shows',
          gradientColors: [AppColors.romanceGradientStart, AppColors.romanceGradientEnd],
        ),
        _buildGenreCard(
          emoji: '🔮', title: 'Fantasy', description: 'Magical adventures', count: '120+ shows',
          gradientColors: [AppColors.fantasyGradientStart, AppColors.fantasyGradientEnd],
        ),
        _buildGenreCard(
          emoji: '😂', title: 'Comedy', description: 'Hilarious moments', count: '95+ shows',
          gradientColors: [AppColors.comedyGradientStart, AppColors.comedyGradientEnd],
        ),
      ],
    );
  }

  Widget _buildGenreCard({ required String emoji, required String title, required String description, required String count, required List<Color> gradientColors}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          Column(
            children: [
              Text(title, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(color: AppColors.primaryText.withOpacity(0.8), fontSize: 14), textAlign: TextAlign.center),
            ],
          ),
          Text(count, style: TextStyle(color: AppColors.primaryText.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSubGenreGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1 / 1.1,
      children: [
        _buildSubGenreCard(emoji: '🤖', title: 'Sci-Fi'),
        _buildSubGenreCard(emoji: '👻', title: 'Horror'),
        _buildSubGenreCard(emoji: '🏫', title: 'School'),
        _buildSubGenreCard(emoji: '🏀', title: 'Sports'),
        _buildSubGenreCard(emoji: '🎵', title: 'Music'),
        _buildSubGenreCard(emoji: '🔍', title: 'Mystery'),
      ],
    );
  }

  Widget _buildSubGenreCard({required String emoji, required String title}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
