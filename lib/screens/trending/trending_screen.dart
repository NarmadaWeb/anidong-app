// lib/screens/trending/trending_screen.dart

import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/providers/trending_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.orangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SingleChildScrollView(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔥 Trending Now', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                        const SizedBox(height: 4),
                        Text('Discover what everyone is watching', style: TextStyle(fontSize: 14, color: AppColors.primaryText.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildCategoryCards(),
                        const SizedBox(height: 24),
                        _buildTrendingList(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCards() {
    return Builder(
      builder: (context) {
        return Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Boxicons.bxs_crown, size: 40, color: AppColors.yellow400),
                    const SizedBox(height: 8),
                    Text('Top Rated', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 2),
                    Text('Best shows ever', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Boxicons.bxs_time, size: 40, color: AppColors.green500),
                    const SizedBox(height: 8),
                    Text('This Week', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 2),
                    Text('Weekly favorites', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildTrendingList() {
    return Consumer<TrendingProvider>(
      builder: (context, provider, child) {
        if (provider.state == TrendingState.loading || provider.state == TrendingState.initial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.state == TrendingState.initial) {
              provider.fetchTrendingPageData(context);
            }
          });
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }

        if (provider.state == TrendingState.error) {
          return Center(
            child: Text('Error: ${provider.errorMessage}', style: const TextStyle(color: AppColors.secondaryText)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.topRatedShows.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final show = provider.topRatedShows[index];
            return _buildTrendingItem(
              rank: index + 1,
              show: show,
            );
          },
        );
      },
    );
  }

  Widget _buildTrendingItem({required int rank, required Show show}) {
    final genreText = show.genres.map((g) => g.name).join(' • ');
    return Builder(
      builder: (context) {
        return GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('#$rank', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accent)),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: show.coverImageUrl ?? '',
                  width: 64,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Theme.of(context).cardColor),
                  errorWidget: (context, url, error) => Center(child: Icon(Icons.image_not_supported, color: Theme.of(context).iconTheme.color)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(show.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    Text(genreText, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
