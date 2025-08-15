// lib/screens/home/home_screen.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/providers/home_provider.dart';
import 'package:anidong/screens/home/widgets/hero_slider.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onModeChanged;

  const HomeScreen({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        if (provider.state == HomeState.loading || provider.state == HomeState.initial) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }

        if (provider.state == HomeState.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.errorMessage}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.secondaryText)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchHomePageData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primaryText
                    ),
                  )
                ],
              ),
            ),
          );
        }

        // --- PERBAIKAN DI SINI ---
        // Karena /episodes/recent tidak punya data 'Show', kita tidak bisa memfilternya di sini.
        // Kita akan memfilter di dalam `_buildNewEpisodesGrid` jika data Show tersedia di sana.
        // Untuk sekarang, kita asumsikan /episodes/recent MUNGKIN tidak memiliki info 'Show'
        final allRecentEpisodes = provider.recentEpisodes;

        // Filter untuk rekomendasi tetap berjalan seperti biasa
        final filteredRecommended = provider.recommendedShows
            .where((show) => show.type == currentMode)
            .toList();

        return RefreshIndicator(
          onRefresh: () => provider.fetchHomePageData(),
          backgroundColor: AppColors.surface,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeroSlider(),
                _buildSectionTitle('New Episodes'),
                _buildNewEpisodesGrid(allRecentEpisodes, currentMode), // Kirim mode saat ini
                _buildSectionTitle('Recommended For You'),
                _buildRecommendedList(context, filteredRecommended),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
    );
  }

  // --- PERBAIKAN DI SINI ---
  Widget _buildNewEpisodesGrid(List<Episode> episodes, String currentMode) {
    // Lakukan filter di sini. Jika episode.show adalah null, kita butuh fallback.
    // Solusi terbaik adalah backend mengirim data Show.
    // Solusi sementara: Tampilkan saja, atau filter jika ada data Show.
    final filteredEpisodes = episodes.where((ep) {
      // Jika backend Anda DIPERBAIKI (solusi ideal), baris ini akan berfungsi:
      // return ep.show?.type == currentMode;

      // SOLUSI SEMENTARA: karena backend belum mengirim data `show` di `/episodes/recent`,
      // kita tidak bisa memfilter. Untuk menampilkan sesuatu, kita hilangkan filter untuk sementara.
      // Jika Anda ingin tetap filter, perbaiki backend Anda.
      return true;
    }).toList();

    if (filteredEpisodes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        alignment: Alignment.center,
        child: const Text('No new episodes available for this mode.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.secondaryText)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 16, childAspectRatio: 0.6,
      ),
      itemCount: filteredEpisodes.length,
      itemBuilder: (context, index) {
        final episode = filteredEpisodes[index];
        // Judul sekarang diambil dari episode itu sendiri jika ada, jika tidak, dari Show.
        final displayTitle = episode.title ?? episode.show?.title ?? 'Unknown Episode';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: episode.thumbnailUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.surface),
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.image_not_supported, color: AppColors.secondaryText)),
                    ),
                  ),
                  // ... (overlay lainnya)
                  Positioned(
                    bottom: 8, left: 8, right: 8,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
                          child: Text('Ep ${episode.episodeNumber}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.yellow400, borderRadius: BorderRadius.circular(4)),
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
              displayTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.primaryText, fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendedList(BuildContext context, List<Show> shows) {
     if (shows.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.25,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Text('No recommendations available for this mode.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.secondaryText)),
      );
    }

    final itemHeight = MediaQuery.of(context).size.height * 0.25;
    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        // ... (kode ini sudah benar dan tidak perlu diubah)
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: shows.length,
        itemBuilder: (context, index) {
          final show = shows[index];
          final itemWidth = itemHeight * (2 / 3);
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(
              width: itemWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: show.coverImageUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppColors.surface),
                        errorWidget: (context, url, error) => const Center(child: Icon(Icons.image_not_supported, color: AppColors.secondaryText)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    show.title,
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
