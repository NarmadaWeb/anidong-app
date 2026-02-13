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
              color: Theme.of(context).cardColor,
              alignment: Alignment.center,
              child: Text('No featured shows available.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
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
            pagination: SwiperPagination(
              alignment: Alignment.bottomCenter,
              margin: const EdgeInsets.only(bottom: 20.0),
              builder: DotSwiperPaginationBuilder(
                color: Colors.white38,
                activeColor: Theme.of(context).primaryColor,
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
        _buildBackgroundImage(context),
        _buildGradientOverlay(context),
        _buildSlideContent(context),
      ],
    );
  }

  Widget _buildBackgroundImage(BuildContext context) {
    return CachedNetworkImage(
      // Menggunakan bannerImageUrl dari objek Show
      imageUrl: show.bannerImageUrl ?? show.coverImageUrl ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Theme.of(context).cardColor),
      errorWidget: (context, url, error) => Center(
        child: Icon(Icons.image_not_supported, color: Theme.of(context).iconTheme.color),
      ),
    );
  }

  Widget _buildGradientOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
            Colors.transparent
          ],
          stops: const [0.0, 0.4, 1.0],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
    );
  }

  Widget _buildSlideContent(BuildContext context) {
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
            show.title.length > 40 ? '${show.title.substring(0, 40)}...' : show.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    const Shadow(blurRadius: 10.0, color: Colors.black54),
                    const Shadow(blurRadius: 20.0, color: Colors.black54),
                  ],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            genreText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  shadows: const [Shadow(blurRadius: 5.0, color: Colors.black87)],
                ),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Boxicons.bx_play_circle, size: 22),
          label: const Text('Play'),
          // --- Perbaikan 6: Style tombol yang lebih modern ---
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            foregroundColor: Theme.of(context).colorScheme.surface,
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
            backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.8),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Theme.of(context).dividerColor),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
