// lib/screens/my_list/my_list_screen.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/providers/local_data_provider.dart';
import 'package:anidong/screens/video_player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key});

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 3 Tabs: Ongoing, Completed, Movie
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
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
          // Konten
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Teks
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⭐ My List', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                      const SizedBox(height: 4),
                      Text('Your favorite collection', style: TextStyle(fontSize: 14, color: AppColors.primaryText.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Ongoing'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Movie'),
                  ],
                ),
                // Tab Views
                Expanded(
                  child: Consumer<LocalDataProvider>(
                    builder: (context, localData, child) {
                      // Combine all bookmarks
                      final allBookmarks = [
                        ...localData.animeBookmarks,
                        ...localData.donghuaBookmarks,
                      ];

                      // Remove duplicates if any (based on ID or URL)
                      final uniqueBookmarks = <int, Show>{};
                      for (var s in allBookmarks) {
                        uniqueBookmarks[s.id] = s;
                      }
                      final List<Show> shows = uniqueBookmarks.values.toList();

                      // Filter logic
                      final ongoing = shows.where((s) =>
                        s.type.toLowerCase() != 'movie' &&
                        !s.status.toLowerCase().contains('completed') &&
                        !s.status.toLowerCase().contains('tamat')
                      ).toList();

                      final completed = shows.where((s) =>
                        s.type.toLowerCase() != 'movie' &&
                        (s.status.toLowerCase().contains('completed') || s.status.toLowerCase().contains('tamat'))
                      ).toList();

                      final movies = shows.where((s) => s.type.toLowerCase().contains('movie')).toList();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildListItems(ongoing),
                          _buildListItems(completed),
                          _buildListItems(movies),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItems(List<Show> shows) {
    return Builder(
      builder: (context) {
        if (shows.isEmpty) {
          return Center(
            child: Text('No bookmarks in this category.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: shows.length,
          itemBuilder: (context, index) {
            final show = shows[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildListItem(show),
            );
          },
        );
      }
    );
  }

  Widget _buildListItem(Show show) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: () {
            // Navigate to VideoPlayerScreen which acts as Details Screen
            // Pass episodeNumber 1 as default, but pointing to Show URL
            // The scraping logic will detect Show URL and load full episode list
            final episode = Episode(
              id: show.id,
              showId: show.id,
              episodeNumber: 1, // Default, will be ignored if Show URL logic kicks in
              title: show.title,
              videoUrl: '',
              originalUrl: show.originalUrl,
              show: show,
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VideoPlayerScreen(episode: episode)),
            );
          },
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 70, height: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: show.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: show.coverImageUrl!,
                            width: 70,
                            height: 90,
                            fit: BoxFit.cover,
                            httpHeaders: const {
                              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                            },
                            placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
                            errorWidget: (context, url, error) => Icon(Icons.movie, color: Theme.of(context).iconTheme.color),
                          )
                        : Icon(Icons.movie, color: Theme.of(context).iconTheme.color),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(show.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(height: 4),
                      Text(show.type.toUpperCase(), style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
                      if (show.status.isNotEmpty) ...[
                         const SizedBox(height: 2),
                         Text(show.status, style: TextStyle(fontSize: 11, color: Theme.of(context).primaryColor)),
                      ]
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Play button also does the same navigation
                        final episode = Episode(
                          id: show.id,
                          showId: show.id,
                          episodeNumber: 1,
                          title: show.title,
                          videoUrl: '',
                          originalUrl: show.originalUrl,
                          show: show,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VideoPlayerScreen(episode: episode)),
                        );
                      },
                      icon: const Icon(Boxicons.bx_play_circle, color: AppColors.accent, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      onPressed: () {
                        Provider.of<LocalDataProvider>(context, listen: false).toggleBookmark(show);
                      },
                      icon: Icon(Boxicons.bx_x, color: Theme.of(context).iconTheme.color, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      }
    );
  }
}
