import 'package:anidong/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:anidong/utils/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan
  // TIP: Tambahkan halaman placeholder agar tidak error saat navigasi
  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    Center(child: Text('Shorts Page')), // Placeholder
    Center(child: Text('Trendings Page')), // Placeholder
    Center(child: Text('Downloads Page')), // Placeholder
    Center(child: Text('Profile Page')), // Placeholder
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  AppBar? _buildAppBar() {
    if (_selectedIndex == 1 || _selectedIndex == 4) {
      return null;
    }

    return AppBar(
      backgroundColor: AppColors.background.withOpacity(0.8),
      title: Row(
        children: [
          Icon(Boxicons.bxs_movie, color: AppColors.accent, size: 28),
          const SizedBox(width: 8),
          const Text('AniDong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Boxicons.bx_search, size: 26),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _selectedIndex == 1
            ? Colors.transparent
            : AppColors.background.withOpacity(0.9),
          border: Border(
            top: BorderSide(
              color: _selectedIndex == 1
                ? Colors.transparent
                : AppColors.surface,
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Boxicons.bxs_home_smile), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Boxicons.bxs_movie_play), label: 'Shorts'),
            BottomNavigationBarItem(icon: Icon(Boxicons.bxs_hot), label: 'Trendings'),
            BottomNavigationBarItem(icon: Icon(Boxicons.bxs_download), label: 'Downloads'),
            BottomNavigationBarItem(icon: Icon(Boxicons.bxs_user_circle), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.secondaryText,
          // --- PERUBAHAN DI SINI ---
          showUnselectedLabels: false, // <-- ATUR JADI FALSE UNTUK MENGATASI OVERFLOW
          // --------------------------
          selectedFontSize: 12, // Sedikit lebih besar agar mudah dibaca saat aktif
          unselectedFontSize: 10,
        ),
      ),
    );
  }
}
