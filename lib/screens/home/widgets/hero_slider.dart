// lib/screens/home/widgets/hero_slider.dart

import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/providers/home_provider.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:provider/provider.dart';

class HeroSlider extends StatelessWidget {
  const HeroSlider({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer untuk mendapatkan data dari HomeProvider
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        // Ambil 3 item pertama dari recommendedShows untuk slider
        final slides = provider.recommendedShows.take(3).toList();

        if (slides.isEmpty) {
          // Tampilkan placeholder jika tidak ada data
          return AspectRatio(
            aspectRatio: 16 / 11,
            child: Container(
              color: AppColors.surface,
              alignment: Alignment.center,
              child: const Text('No featured shows available.', style: TextStyle(color: AppColors.secondaryText)),
            ),
          );
        }

        return AspectRatio(
          aspectRatio: 16 / 11,
          child: Swiper(
            itemCount: slides.length,
            itemBuilder: (context, index) {
              // Mengirim data 'Show' ke widget item
              return _HeroSlideItem(show: slides[index]);
            },
            autoplay: true,
            autoplayDelay: 5000,
            pagination: const SwiperPagination(
              alignment: Alignment.bottomCenter,
              margin: EdgeInsets.only(bottom: 20.0),
              builder: DotSwiperPaginationBuilder(
                color: Colors.white38,
                activeColor: AppColors.accent,
                size: 8.0,
                activeSize: 10.0,
                space: 4.0,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroSlideItem extends StatelessWidget {
  // Menerima objek Show, bukan SlideModel
  final Show show;

  const _HeroSlideItem({required this.show});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackgroundImage(),
        _buildGradientOverlay(),
        _buildSlideContent(),
      ],
    );
  }

  Widget _buildBackgroundImage() {
    return CachedNetworkImage(
      // Menggunakan bannerImageUrl dari objek Show
      imageUrl: show.bannerImageUrl ?? show.coverImageUrl ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: AppColors.surface),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.image_not_supported, color: AppColors.secondaryText),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.background,
            AppColors.background.withValues(alpha: 0.7),
            Colors.transparent
          ],
          stops: const [0.0, 0.4, 1.0],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
    );
  }

  Widget _buildSlideContent() {
    // Menggabungkan nama genre menjadi satu string
    final genreText = show.genres.map((g) => g.name).join(' • ');

    return Positioned(
      bottom: 60,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Text(
            // Menggunakan title dari objek Show
            show.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryText,
              shadows: [
                Shadow(blurRadius: 10.0, color: Colors.black54),
                Shadow(blurRadius: 20.0, color: Colors.black54),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            genreText,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
              shadows: [Shadow(blurRadius: 5.0, color: Colors.black87)],
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Boxicons.bx_play_circle, size: 22),
          label: const Text('Play'),
          // --- Perbaikan 6: Style tombol yang lebih modern ---
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryText,
            foregroundColor: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Boxicons.bx_plus, size: 22),
          label: const Text('My List'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface.withValues(alpha: 0.8),
            foregroundColor: AppColors.primaryText,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
