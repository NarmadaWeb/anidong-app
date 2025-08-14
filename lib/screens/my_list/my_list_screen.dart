// lib/screens/my_list/my_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';

class MyListScreen extends StatelessWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN: Menggunakan Scaffold TANPA AppBar
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 56.0, 16.0, 24.0), // Tambah padding atas
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⭐ My List', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                        const SizedBox(height: 4),
                        Text('Your favorite anime collection', style: TextStyle(fontSize: 14, color: AppColors.primaryText.withOpacity(0.8))),
                      ],
                    ),
                  ),
                  // Konten utama
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatsGrid(),
                        const SizedBox(height: 24),
                        _buildMyListItems(),
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
    Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(value: '12', label: 'Total', valueColor: AppColors.accent)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(value: '7', label: 'Watching', valueColor: AppColors.green500)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(value: '5', label: 'Completed', valueColor: AppColors.blue500)),
      ],
    );
  }

  Widget _buildStatCard({required String value, required String label, required Color valueColor}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: valueColor)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
        ],
      ),
    );
  }

  Widget _buildMyListItems() {
    return Column(
      children: [
        _buildListItem(
          title: 'Attack on Titan', episodeInfo: 'Episode 24 of 87', progress: 0.27,
        ),
        const SizedBox(height: 12),
        _buildListItem(
          title: 'Jujutsu Kaisen', episodeInfo: 'Episode 20 of 24', progress: 0.85,
        ),
      ],
    );
  }

  Widget _buildListItem({required String title, required String episodeInfo, required double progress}) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 70, height: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Icon(Icons.image_outlined, color: AppColors.secondaryText.withOpacity(0.5))),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                    child: LinearProgressIndicator(
                      value: progress, backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent), minHeight: 4,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                const SizedBox(height: 4),
                Text(episodeInfo, style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress, backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Boxicons.bx_play_circle, color: AppColors.accent, size: 28), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              IconButton(onPressed: () {}, icon: const Icon(Boxicons.bx_x, color: AppColors.secondaryText, size: 24), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          )
        ],
      ),
    );
  }
}
