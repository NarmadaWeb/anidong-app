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
      // SafeArea memastikan seluruh konten Drawer tidak tertimpa UI sistem
      child: SafeArea(
        child: Column(
          // mainAxisAlignment: CrossAxisAlignment.stretch akan memastikan item mengisi lebar
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Grup Atas: Logo dan Menu Utama
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(), // Header dengan logo
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
              ],
            ),

            // Spacer akan mendorong grup bawah ke posisi paling bawah
            const Spacer(),

            // Grup Bawah: Settings dan Logout
            Column(
              children: [
                const Divider(color: AppColors.surface, height: 1, indent: 16, endIndent: 16),
                _buildDrawerItem(
                  icon: Boxicons.bxs_cog,
                  text: 'Settings',
                  onTap: () => onPageSelected(4),
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
          ],
        ),
      ),
    );
  }

  // Header sekarang hanya berisi logo dengan padding yang disesuaikan
  Widget _buildHeader() {
    return Padding(
      // PERBAIKAN: Padding diatur untuk jarak yang rapat
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
      child: Center(
        child: Image.asset(
          'assets/images/logo.png',
          height: 100,
          width: 120,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.movie_filter_rounded,
              size: 80,
              color: AppColors.accent,
            );
          },
        ),
      ),
    );
  }

  // _buildDrawerItem tidak perlu diubah
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
