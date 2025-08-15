// lib/screens/home/widgets/hero_slider.dart

import 'package:anidong/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

// --- Perbaikan 1: Membuat Model Data ---
// Menggunakan class membuat kode lebih aman dari typo dan lebih mudah dibaca.
class SlideModel {
  final String imageUrl;
  final String title;
  final String genre;

  const SlideModel({
    required this.imageUrl,
    required this.title,
    required this.genre,
  });
}

class HeroSlider extends StatelessWidget {
  const HeroSlider({super.key});

  // --- Perbaikan 2: Data dipisahkan dari UI ---
  // Data sekarang menggunakan SlideModel.
  static final List<SlideModel> _slides = [
    const SlideModel(
      imageUrl: "https://image.tmdb.org/t/p/w780/hTP1DtLGFamjG9sz1w6qCg2xVcN.jpg",
      title: "SPY x FAMILY",
      genre: "Action • Comedy • Shounen",
    ),
    const SlideModel(
      imageUrl: "https://image.tmdb.org/t/p/w780/9VUJS3PA69I42Ke8iBSt3bFvflg.jpg",
      title: "Jujutsu Kaisen",
      genre: "Action • Dark Fantasy • Supernatural",
    ),
    const SlideModel(
      imageUrl: "https://image.tmdb.org/t/p/w780/yDHYTfA3R0jFYba16jBB1ef8oIt.jpg",
      title: "Demon Slayer",
      genre: "Action • Historical • Supernatural",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Menggunakan AspectRatio agar ukuran slider responsif terhadap lebar layar.
    return AspectRatio(
      aspectRatio: 16 / 11, // Rasio yang baik untuk hero banner
      child: Swiper(
        itemCount: _slides.length,
        itemBuilder: (context, index) {
          // Mengirim model data ke metode build
          return _HeroSlideItem(slide: _slides[index]);
        },
        autoplay: true,
        autoplayDelay: 5000,
        // --- Perbaikan 3: Pagination yang lebih stylish ---
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
  }
}

// --- Perbaikan 4: Memisahkan item slide menjadi widget tersendiri ---
// Ini membuat kode lebih bersih dan dapat digunakan kembali.
class _HeroSlideItem extends StatelessWidget {
  final SlideModel slide;

  const _HeroSlideItem({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gambar Background
        _buildBackgroundImage(),
        // Gradient Overlay
        _buildGradientOverlay(),
        // Konten Teks dan Tombol
        _buildSlideContent(),
      ],
    );
  }

  Widget _buildBackgroundImage() {
    return CachedNetworkImage(
      imageUrl: slide.imageUrl,
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
            AppColors.background.withOpacity(0.7),
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
    return Positioned(
      bottom: 60, // Memberi ruang lebih untuk pagination
      left: 16,
      right: 16,
      child: Column(
        children: [
          // --- Perbaikan 5: Menambahkan shadow pada teks agar lebih terbaca ---
          Text(
            slide.title,
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
            slide.genre,
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
            backgroundColor: AppColors.surface.withOpacity(0.8),
            foregroundColor: AppColors.primaryText,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
