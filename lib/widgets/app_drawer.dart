// lib/widgets/app_drawer.dart

import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class AppDrawer extends StatelessWidget {
  final ValueChanged<int> onPageSelected;

  const AppDrawer({super.key, required this.onPageSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Header sekarang akan menampilkan logo
          _buildHeader(),
          _buildDrawerItem(
            icon: Boxicons.bxs_compass,
            text: 'Explore Genres',
            onTap: () => onPageSelected(5),
          ),
          _buildDrawerItem(
            icon: Boxicons.bxs_bookmark_star,
            text: 'My List',
            onTap: () => onPageSelected(6),
          ),
          _buildDrawerItem(
            icon: Boxicons.bxs_time_five,
            text: 'Watch History',
            onTap: () => onPageSelected(2),
          ),
          _buildDrawerItem(
            icon: Boxicons.bxs_crown,
            text: 'Go Premium',
            onTap: () => onPageSelected(8),
          ),
          const Divider(color: AppColors.surface, height: 1),
          _buildDrawerItem(
            icon: Boxicons.bxs_cog,
            text: 'Settings',
            onTap: () => onPageSelected(7),
            iconColor: AppColors.secondaryText,
          ),
          _buildDrawerItem(
            icon: Boxicons.bxs_log_out,
            text: 'Logout',
            onTap: () {
              // Placeholder for logout logic
              Navigator.pop(context);
            },
            iconColor: AppColors.secondaryText,
          ),
        ],
      ),
    );
  }

  // --- PERBAIKAN UTAMA DI SINI ---
  // Metode _buildHeader() diubah total untuk menampilkan logo.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      width: double.infinity,
      child: Column(
        children: [
          // Widget untuk menampilkan gambar logo dari folder assets
          Image.asset(
            'assets/images/logo.png', // Pastikan path ini sesuai dengan nama file Anda
            height: 80,
            // Fallback jika gambar gagal dimuat
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.movie_filter_rounded,
                size: 80,
                color: AppColors.accent,
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'AniDong', // Nama aplikasi Anda
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: AppColors.primaryText,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.accent, size: 26),
      title: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}
