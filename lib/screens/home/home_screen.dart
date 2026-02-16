// lib/screens/home/home_screen.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/providers/home_provider.dart';
import 'package:anidong/screens/home/widgets/hero_slider.dart';
import 'package:anidong/screens/show_details_screen.dart';
import 'package:anidong/screens/video_player_screen.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        if (provider.state == HomeState.loading || provider.state == HomeState.initial) {
          // Call fetchHomePageData with context when the provider is first initialized or loading
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.state == HomeState.initial) {
              provider.fetchHomePageData(context);
            }
          });
          return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
        }

        if (provider.state == HomeState.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.errorMessage}', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchHomePageData(context),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          );
        }

        final allRecentEpisodes = provider.recentEpisodes;

        // Filter untuk rekomendasi tetap berjalan seperti biasa
        final filteredRecommended = provider.recommendedShows
            .where((show) => show.type == provider.currentMode)
            .toList();

        return RefreshIndicator(
          onRefresh: () => provider.fetchHomePageData(context),
          backgroundColor: Theme.of(context).cardColor,
          color: Theme.of(context).primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 64 + MediaQuery.of(context).viewPadding.top + 16),
                const HeroSlider(),
                _buildSectionTitle('New Episodes'),
                _buildNewEpisodesGrid(context, allRecentEpisodes, provider.currentMode, provider), // Kirim mode saat ini
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
    // Need context, but StatelessWidget methods don't have it unless passed or widget built in build.
    // _buildSectionTitle is called from build, so I need to update signature or use Builder.
    // Since this method is simple, I'll assume I can access Theme via context passed or available.
    // Wait, the caller is `_buildSectionTitle('Title')`. I need to pass context.
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
      );
    });
  }

  // --- PERBAIKAN DI SINI ---
  Widget _buildNewEpisodesGrid(BuildContext context, List<Episode> episodes, String currentMode, HomeProvider provider) {

    final filteredEpisodes = episodes.where((ep) {

      return true;
    }).toList();

    if (filteredEpisodes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        alignment: Alignment.center,
        child: Text('No new episodes available for this mode.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
      );
    }

    return Column(
      children: [
        GridView.builder(
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

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(episode: episode),
                  ),
                );
              },
              child: Column(
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
                            placeholder: (context, url) => Container(color: Theme.of(context).cardColor),
                            errorWidget: (context, url, error) => Center(child: Icon(Icons.image_not_supported, color: Theme.of(context).iconTheme.color)),
                          ),
                        ),

                        Positioned(
                          bottom: 8, left: 8, right: 8,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: provider.isLoadingMore
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
              : SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => provider.loadMoreEpisodes(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Load More Episodes'),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecommendedList(BuildContext context, List<Show> shows) {
     if (shows.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.25,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('No recommendations available for this mode.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
      );
    }

    final itemHeight = MediaQuery.of(context).size.height * 0.25;
    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: shows.length,
        itemBuilder: (context, index) {
          final show = shows[index];
          final itemWidth = itemHeight * (2 / 3);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShowDetailsScreen(show: show),
                ),
              );
            },
            child: Padding(
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
                          placeholder: (context, url) => Container(color: Theme.of(context).cardColor),
                          errorWidget: (context, url, error) => Center(child: Icon(Icons.image_not_supported, color: Theme.of(context).iconTheme.color)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      show.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
