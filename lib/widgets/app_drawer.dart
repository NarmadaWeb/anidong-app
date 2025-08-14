import 'package:anidong/screens/explore/explore_screen.dart';
import 'package:anidong/screens/history/history_screen.dart';
import 'package:anidong/screens/my_list/my_list_screen.dart';
import 'package:anidong/screens/premium/premium_screen.dart';
import 'package:anidong/screens/settings/settings_screen.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildHeader(),
          _buildDrawerItem(
            icon: Boxicons.bxs_compass,
            text: 'Explore Genres',
            onTap: () => _navigateTo(context, const ExploreScreen()),
          ),
          _buildDrawerItem(
            icon: Boxicons.bxs_bookmark_star,
            text: 'My List',
            onTap: () => _navigateTo(context, const MyListScreen()),
          ),
          _buildDrawerItem(
            icon: Boxicons.bxs_time_five,
            text: 'Watch History',
            onTap: () => _navigateTo(context, const HistoryScreen()),
          ),
          _buildDrawerItem(
            icon: Boxicons.bxs_crown,
            text: 'Go Premium',
            onTap: () => _navigateTo(context, const PremiumScreen()),
          ),
          const Divider(color: AppColors.surface),
          _buildDrawerItem(
            icon: Boxicons.bxs_cog,
            text: 'Settings',
            onTap: () => _navigateTo(context, const SettingsScreen()),
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

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildHeader() {
    return const UserAccountsDrawerHeader(
      accountName: Text(
        'Your Name',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: AppColors.primaryText,
        ),
      ),
      accountEmail: Text(
        '@your_username',
        style: TextStyle(color: AppColors.secondaryText),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundImage: NetworkImage('https://i.pravatar.cc/80?u=user123'),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
