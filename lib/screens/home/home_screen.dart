import 'package:anidong/screens/home/widgets/hero_slider.dart';
import 'package:anidong/screens/home/widgets/mode_switch.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentMode = 'anime';

  // Updated data structure
  static final List<Map<String, String>> _allContent = [
    {'title': 'Jujutsu Kaisen', 'mode': 'anime', 'type': 'episode'},
    {'title': 'Perfect World', 'mode': 'donghua', 'type': 'episode'},
    {'title': 'One Piece', 'mode': 'anime', 'type': 'episode'},
    {'title': 'Throne of Seal', 'mode': 'donghua', 'type': 'episode'},
    {'title': 'My Hero Academia', 'mode': 'anime', 'type': 'episode'},
    {'title': 'Apotheosis', 'mode': 'donghua', 'type': 'episode'},
    {'title': 'Attack on Titan', 'mode': 'anime', 'type': 'episode'},
    {'title': 'Swallowed Star', 'mode': 'donghua', 'type': 'episode'},
    {'title': 'Solo Leveling', 'mode': 'anime', 'type': 'recommended'},
    {'title': 'Battle Through the Heavens', 'mode': 'donghua', 'type': 'recommended'},
    {'title': 'Demon Slayer', 'mode': 'anime', 'type': 'recommended'},
  ];

  List<Map<String, String>> _filteredEpisodes = [];
  List<Map<String, String>> _filteredRecommended = [];

  @override
  void initState() {
    super.initState();
    _filterContent();
  }

  void _onModeChanged(String newMode) {
    setState(() {
      _currentMode = newMode;
      _filterContent();
    });
  }

  void _filterContent() {
    _filteredEpisodes = _allContent
        .where((item) => item['mode'] == _currentMode && item['type'] == 'episode')
        .toList();
    _filteredRecommended = _allContent
        .where((item) => item['mode'] == _currentMode && item['type'] == 'recommended')
        .toList();
  }

  // The _loadMore function is removed as it's not compatible with the new data structure.
  // A more advanced pagination logic would be needed.

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeroSlider(),
          ModeSwitch(currentMode: _currentMode, onModeChanged: _onModeChanged),
          _buildSectionTitle('New Episodes'),
          _buildNewEpisodesGrid(),
          // Load more button removed for simplicity with the new data model
          _buildSectionTitle('Recommended For You'),
          _buildRecommendedList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  // ===== KODE YANG DIPERBAIKI ADA DI SINI =====
  Widget _buildNewEpisodesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2 / 3, // Adjusted for poster-like images
      ),
      itemCount: _filteredEpisodes.length,
      itemBuilder: (context, index) {
        final episode = _filteredEpisodes[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  // TODO: Add image here later using CachedNetworkImage
                ),
                child: Center(child: Icon(Icons.image, color: AppColors.secondaryText.withOpacity(0.5))),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              episode['title']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: _isLoadingMore
            ? const CircularProgressIndicator(color: AppColors.accent)
            : OutlinedButton(
                onPressed: _loadMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: AppColors.surface.withOpacity(0.8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                ),
                child: const Text('Muat Lebih Banyak'),
              ),
      ),
    );
  }

  Widget _buildRecommendedList() {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _filteredRecommended.length,
        itemBuilder: (context, index) {
          final recommended = _filteredRecommended[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        // TODO: Add image here later
                      ),
                      child: Center(child: Icon(Icons.image, color: AppColors.secondaryText.withOpacity(0.5))),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recommended['title']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
