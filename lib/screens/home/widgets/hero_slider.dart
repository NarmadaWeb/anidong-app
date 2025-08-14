import 'package:anidong/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class HeroSlider extends StatefulWidget {
  const HeroSlider({super.key});

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider> {
  int _current = 0;
  final CarouselController _controller = CarouselController();

  static final List<Map<String, String>> _slides = [
    {
      "image": "https://image.tmdb.org/t/p/w780/hTP1DtLGFamjG9sz1w6qCg2xVcN.jpg",
      "title": "SPY x FAMILY",
      "genre": "Action • Comedy • Shounen",
    },
    {
      "image": "https://image.tmdb.org/t/p/w780/9VUJS3PA69I42Ke8iBSt3bFvflg.jpg",
      "title": "Jujutsu Kaisen",
      "genre": "Action • Dark Fantasy • Supernatural",
    },
    {
      "image": "https://image.tmdb.org/t/p/w780/yDHYTfA3R0jFYba16jBB1ef8oIt.jpg",
      "title": "Demon Slayer",
      "genre": "Action • Historical • Supernatural",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider.builder(
          carouselController: _controller,
          itemCount: _slides.length,
          itemBuilder: (context, index, realIndex) {
            final slide = _slides[index];
            return _buildSlide(context, slide);
          },
          options: CarouselOptions(
            height: 380,
            autoPlay: true,
            viewportFraction: 1.0,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
        ),
        Positioned(
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _slides.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _controller.animateToPage(entry.key),
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                        .withOpacity(_current == entry.key ? 0.9 : 0.4),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSlide(BuildContext context, Map<String, String> slide) {
    return SizedBox(
      height: 380,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: slide['image']!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: AppColors.surface),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, AppColors.background.withOpacity(0.7), Colors.transparent],
                stops: const [0.0, 0.4, 1.0],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  slide['title']!,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primaryText),
                ),
                const SizedBox(height: 8),
                Text(
                  slide['genre']!,
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Boxicons.bx_play_circle, size: 22),
                      label: const Text('Play'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Boxicons.bx_plus, size: 22),
                      label: const Text('My List'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
