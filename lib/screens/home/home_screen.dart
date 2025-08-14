// lib/screens/home/home_screen.dart

import 'package:anidong/data/content_repository.dart'; // Import repository
import 'package:anidong/screens/home/widgets/hero_slider.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class HomeScreen extends StatefulWidget {
  final String currentMode;
  final ValueChanged<String> onModeChanged;

  const HomeScreen({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Data konten tidak lagi didefinisikan di sini

  List<Map<String, dynamic>> _filteredEpisodes = [];
  List<Map<String, dynamic>> _filteredRecommended = [];

  @override
  void initState() {
    super.initState();
    _filterContent();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMode != oldWidget.currentMode) {
      _filterContent();
    }
  }

  void _filterContent() {
    setState(() {
      // Mengambil data dari ContentRepository yang terpusat
      _filteredEpisodes = ContentRepository.allContent
          .where((item) => item['mode'] == widget.currentMode && item['type'] == 'episode')
          .toList();
      _filteredRecommended = ContentRepository.allContent
          .where((item) => item['mode'] == widget.currentMode && item['type'] == 'recommended')
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeroSlider(),
          _buildSectionTitle('New Episodes'),
          _buildNewEpisodesGrid(),
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
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
    );
  }

  Widget _buildNewEpisodesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.6,
      ),
      itemCount: _filteredEpisodes.length,
      itemBuilder: (context, index) {
        final episode = _filteredEpisodes[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Icon(Icons.image_outlined, color: AppColors.secondaryText, size: 40)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                  const Center(child: Icon(Boxicons.bx_play_circle, color: Colors.white70, size: 50)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.currentMode == 'anime' ? "Anime" : "Donghua",
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Ep ${episode['id']}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.yellow400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Sub', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              episode['title']!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.primaryText, fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendedList() {
    final screenHeight = MediaQuery.of(context).size.height;
    final itemHeight = screenHeight * 0.25;

    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _filteredRecommended.length,
        itemBuilder: (context, index) {
          final recommended = _filteredRecommended[index];
          final itemWidth = itemHeight * (2 / 3);
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(
              width: itemWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: Icon(Icons.image, color: AppColors.secondaryText)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommended['title']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText),
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
