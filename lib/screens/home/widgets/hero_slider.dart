// lib/screens/home/widgets/hero_slider.dart

import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/providers/home_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HeroSlider extends StatelessWidget {
  const HeroSlider({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer untuk mendapatkan data dari HomeProvider
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        // Ambil data slider dari provider
        final slides = provider.heroSlides;

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
        ],
      ),
    );
  }
}
