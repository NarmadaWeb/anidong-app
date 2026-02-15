// lib/screens/main_screen.dart

import 'dart:ui';
import 'package:anidong/widgets/search/search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/app_drawer.dart';
import 'package:anidong/widgets/mode_switch.dart';
import 'package:provider/provider.dart';
import 'package:anidong/providers/home_provider.dart';

import 'package:anidong/screens/schedule/schedule_screen.dart';
import 'package:anidong/screens/explore/explore_screen.dart';
import 'package:anidong/screens/history/history_screen.dart';
import 'package:anidong/screens/home/home_screen.dart';
import 'package:anidong/screens/my_list/my_list_screen.dart';
import 'package:anidong/screens/scan/scan_screen.dart';
import 'package:anidong/screens/settings/settings_screen.dart';
import 'package:anidong/screens/trending/trending_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentPageIndex = 0;
  int _bottomNavIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(), // 0
      const TrendingScreen(), // 1
      const HistoryScreen(),  // 2
      const ScheduleScreen(), // 3
      const SettingsScreen(), // 4
      const ExploreScreen(),  // 5
      const MyListScreen(),   // 6
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentPageIndex = index;
      _bottomNavIndex = index;
    });
  }

  void _navigateToPageFromDrawer(int index) {
    Navigator.pop(context);
    setState(() {
      _currentPageIndex = index;
      if (index >= 0 && index <= 4) {
        _bottomNavIndex = index;
      } else {
        _bottomNavIndex = -1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Set<int> noAppBarPages = {
      1, 2, 3, 4
    };

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: noAppBarPages.contains(_currentPageIndex)
          ? null
          : AppBar(
              toolbarHeight: 64,
              backgroundColor: AppColors.background.withValues(alpha: 0.8),
              elevation: 0,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Boxicons.bx_menu, size: 24, color: AppColors.secondaryText),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Consumer<HomeProvider>(
                builder: (context, provider, child) {
                  return ModeSwitch(
                    currentMode: provider.currentMode,
                    onModeChanged: (newMode) {
                      provider.changeMode(context, newMode);
                    },
                  );
                },
              ),
              centerTitle: true,
              actions: [
                // Aksi untuk tombol pencarian
                IconButton(
                  onPressed: () {
                    // Menampilkan layar pencarian
                    showSearch(
                      context: context,
                      delegate: AnidongSearchDelegate(),
                    );
                  },
                  icon: const Icon(Boxicons.bx_search, size: 24, color: AppColors.secondaryText),
                ),
                const SizedBox(width: 8),
              ],
            ),
      drawer: AppDrawer(
        onPageSelected: _navigateToPageFromDrawer,
      ),
      body: IndexedStack(
        index: _currentPageIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanScreen()),
          );
        },
        backgroundColor: AppColors.accent,
        elevation: 4,
        child: const Icon(Boxicons.bx_qr_scan, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.8),
          border: Border(top: BorderSide(color: AppColors.surface.withValues(alpha: 0.5), width: 1.0)),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Boxicons.bxs_home_smile), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Boxicons.bxs_hot), label: 'Trendings'),
                BottomNavigationBarItem(icon: Icon(Boxicons.bxs_time_five), label: 'History'),
                BottomNavigationBarItem(icon: Icon(Boxicons.bx_calendar_event), label: 'Jadwal'),
                BottomNavigationBarItem(icon: Icon(Boxicons.bx_cog), label: 'Settings'),
              ],
              currentIndex: _bottomNavIndex == -1 ? 0 : _bottomNavIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: _bottomNavIndex == -1 ? AppColors.secondaryText : AppColors.accent,
              unselectedItemColor: AppColors.secondaryText,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }
}
