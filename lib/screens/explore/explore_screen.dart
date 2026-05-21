// lib/screens/explore/explore_screen.dart

import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/api_service.dart';
import 'package:anidong/screens/show_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:anidong/data/services/scraping_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  String _searchType = 'anime'; // 'anime' or 'donghua'
  List<Show> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Preload anime list for faster local search
    _apiService.getAnimeList();
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // Use live search for both to ensure images are present
      // We search all and filter by type
      final allResults = await _apiService.searchShows(context, query);
      List<Show> results = [];

      if (_searchType == 'anime') {
        results = allResults.where((s) => s.type == 'anime').toList();
      } else {
        results = allResults.where((s) => s.type == 'donghua').toList();
      }

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Gradient Background
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.orangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Scrollable Content with Slivers
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header & Search Bar
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🔍 Search & Explore',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5)),
                            const SizedBox(height: 8),
                            Text('Find your favorite Anime & Donghua',
                                style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Colors.white.withValues(alpha: 0.9))),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search title...',
                                  border: InputBorder.none,
                                  icon: Icon(Icons.search,
                                      color: Theme.of(context).primaryColor),
                                ),
                                onSubmitted: _handleSearch,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTypeChip('Anime', 'anime'),
                                const SizedBox(width: 12),
                                _buildTypeChip('Donghua', 'donghua'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                // Results or Genres
                if (_hasSearched)
                  _buildSearchResultsSliver()
                else ...[
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Text('🎭 Main Genres',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  _buildGenreGridSliver(),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Text('🏷️ More Categories',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  _buildSubGenreGridSliver(),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String type) {
    bool isSelected = _searchType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchType = type;
        });
        if (_searchController.text.isNotEmpty) {
          _handleSearch(_searchController.text);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsSliver() {
    if (_isSearching) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(64.0),
            child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(64.0),
            child: Text('No results found.',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final show = _searchResults[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShowDetailsScreen(show: show),
                    ),
                  );
                },
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: show.coverImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: show.coverImageUrl!,
                                width: 70,
                                height: 90,
                                fit: BoxFit.cover,
                                memCacheWidth: 200,
                                httpHeaders: ScrapingService.getAnoboyHeaders(),
                                errorWidget: (context, url, error) => Container(
                                    color: AppColors.surface,
                                    width: 70,
                                    height: 90,
                                    child: const Icon(Icons.movie)),
                                placeholder: (context, url) => Container(
                                    color: AppColors.surface,
                                    width: 70,
                                    height: 90,
                                    child: const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))),
                              )
                            : Container(
                                color: AppColors.surface,
                                width: 70,
                                height: 90,
                                child: const Icon(Icons.movie)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(show.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(show.status,
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Theme.of(context).iconTheme.color),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildGenreGridSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
        children: [
          _buildGenreCard(
            emoji: '⚔️',
            title: 'Action',
            description: 'Fast-paced adventures',
            gradientColors: [
              AppColors.actionGradientStart,
              AppColors.actionGradientEnd
            ],
          ),
          _buildGenreCard(
            emoji: '💖',
            title: 'Romance',
            description: 'Heart-warming stories',
            gradientColors: [
              AppColors.romanceGradientStart,
              AppColors.romanceGradientEnd
            ],
          ),
          _buildGenreCard(
            emoji: '🔮',
            title: 'Fantasy',
            description: 'Magical adventures',
            gradientColors: [
              AppColors.fantasyGradientStart,
              AppColors.fantasyGradientEnd
            ],
          ),
          _buildGenreCard(
            emoji: '😂',
            title: 'Comedy',
            description: 'Hilarious moments',
            gradientColors: [
              AppColors.comedyGradientStart,
              AppColors.comedyGradientEnd
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenreCard(
      {required String emoji,
      required String title,
      required String description,
      required List<Color> gradientColors}) {
    return InkWell(
      onTap: () {
        _searchController.text = title;
        _handleSearch(title);
      },
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(16.0),
        gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            const SizedBox(height: 4),
            Text(description,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSubGenreGridSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.count(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1 / 1.1,
        children: [
          _buildSubGenreCard(emoji: '🤖', title: 'Sci-Fi'),
          _buildSubGenreCard(emoji: '👻', title: 'Horror'),
          _buildSubGenreCard(emoji: '🏫', title: 'School'),
          _buildSubGenreCard(emoji: '🏀', title: 'Sports'),
          _buildSubGenreCard(emoji: '🎵', title: 'Music'),
          _buildSubGenreCard(emoji: '🔍', title: 'Mystery'),
          _buildSubGenreCard(emoji: '🌋', title: 'Adventure'),
          _buildSubGenreCard(emoji: '🎭', title: 'Drama'),
          _buildSubGenreCard(emoji: '🍃', title: 'Slice of Life'),
          _buildSubGenreCard(emoji: '✨', title: 'Supernatural'),
          _buildSubGenreCard(emoji: '🪄', title: 'Magic'),
          _buildSubGenreCard(emoji: '🦾', title: 'Mecha'),
          _buildSubGenreCard(emoji: '🧠', title: 'Psychological'),
          _buildSubGenreCard(emoji: '🔪', title: 'Thriller'),
          _buildSubGenreCard(emoji: '📜', title: 'Historical'),
        ],
      ),
    );
  }

  Widget _buildSubGenreCard({required String emoji, required String title}) {
    return InkWell(
      onTap: () {
        _searchController.text = title;
        _handleSearch(title);
      },
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
