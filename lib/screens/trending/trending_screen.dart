import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:anidong/widgets/modern_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ModernPageHeader(
              title: '🔥 Trending Now',
              subtitle: 'Discover what everyone is watching',
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 24),
                  _buildTrendingList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return const Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                Icon(Boxicons.bxs_crown, size: 40, color: Colors.yellow),
                SizedBox(height: 8),
                Text('Top Rated', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Best shows ever', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                Icon(Boxicons.bxs_time, size: 40, color: Colors.greenAccent),
                SizedBox(height: 8),
                Text('This Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Weekly favorites', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingList() {
    final trendingItems = [
      {'rank': '#1', 'title': 'Jujutsu Kaisen Season 2', 'genre': 'Action • Supernatural', 'rating': '9.2'},
      {'rank': '#2', 'title': 'Chainsaw Man', 'genre': 'Action • Horror', 'rating': '8.9'},
      {'rank': '#3', 'title': 'One Piece', 'genre': 'Adventure • Comedy', 'rating': '9.5'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trendingItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = trendingItems[index];
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(item['rank']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent)),
              const SizedBox(width: 16),
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                // Placeholder for image
                child: const Icon(Icons.image_outlined, color: AppColors.secondaryText),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(item['genre']!, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Boxicons.bxs_star, color: Colors.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text(item['rating']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
