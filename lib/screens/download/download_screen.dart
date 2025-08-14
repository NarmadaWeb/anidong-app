// lib/screens/download/download_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

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
                  // PERBAIKAN: Menghapus 'const'
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📥 My Downloads', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                        const SizedBox(height: 4),
                        Text('Watch offline anytime, anywhere', style: TextStyle(fontSize: 14, color: AppColors.primaryText.withOpacity(0.8))),
                      ],
                    ),
                  ),
                  // Konten Utama
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildStorageCard(),
                        const SizedBox(height: 24),
                        _buildDownloadedList(),
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

  Widget _buildStorageCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Storage Used', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              TextButton(
                onPressed: () {},
                child: const Text('Manage Storage', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            child: LinearProgressIndicator(
              value: 0.65, // 65%
              minHeight: 8,
              backgroundColor: AppColors.darkSurface,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('6.5 GB used', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              Text('10 GB total', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedList() {
    return Column(
      children: [
        _buildDownloadItem(title: 'Jujutsu Kaisen', details: 'Episode 24 • 1080p • 350 MB'),
        const SizedBox(height: 12),
        // Tambahkan item lain di sini
      ],
    );
  }

  Widget _buildDownloadItem({required String title, required String details}) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 56,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Icon(Boxicons.bxs_check_circle, color: AppColors.green500, size: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                const SizedBox(height: 2),
                Text(details, style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: AppColors.green500),
                    SizedBox(width: 6),
                    Text('Downloaded', style: TextStyle(fontSize: 12, color: AppColors.green500)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Boxicons.bx_play_circle, color: AppColors.accent, size: 28)),
          IconButton(onPressed: () {}, icon: const Icon(Boxicons.bx_trash, color: AppColors.secondaryText, size: 24)),
        ],
      ),
    );
  }
}
