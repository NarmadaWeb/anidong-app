// lib/screens/explore/explore_screen.dart

import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/api_service.dart';
import 'package:anidong/screens/show_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    // PERBAIKAN: Menggunakan Scaffold TANPA AppBar
    return Scaffold(
      // backgroundColor: AppColors.background, // Removed to let theme handle it
      body: Stack(
        children: [
          // Background Gradien
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
          // Konten yang bisa di-scroll
          SingleChildScrollView(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Teks
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 56.0, 16.0, 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔍 Search & Explore', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Find your favorite Anime & Donghua', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search title...',
                              border: InputBorder.none,
                              icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                            ),
                            onSubmitted: _handleSearch,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTypeChip('Anime', 'anime'),
                            const SizedBox(width: 8),
                            _buildTypeChip('Donghua', 'donghua'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Results or Genres
                  if (_hasSearched)
                    _buildSearchResults()
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🎭 Genres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildGenreGrid(),
                          const SizedBox(height: 24),
                          _buildSubGenreGrid(),
                        ],
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
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
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('No results found.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final show = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
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
                    borderRadius: BorderRadius.circular(8),
                    child: show.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: show.coverImageUrl!,
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                            httpHeaders: const {
                              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                              'Referer': 'https://ww1.anoboy.boo/',
                            },
                            errorWidget: (context, url, error) => Container(color: AppColors.surface, width: 60, height: 80, child: const Icon(Icons.movie)),
                            placeholder: (context, url) => Container(color: AppColors.surface, width: 60, height: 80, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                          )
                        : Container(color: AppColors.surface, width: 60, height: 80, child: const Icon(Icons.movie)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(show.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        const SizedBox(height: 4),
                        Text(show.status, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenreGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _buildGenreCard(
          emoji: '⚔️', title: 'Action', description: 'Fast-paced adventures',
          gradientColors: [AppColors.actionGradientStart, AppColors.actionGradientEnd],
        ),
        _buildGenreCard(
          emoji: '💖', title: 'Romance', description: 'Heart-warming stories',
          gradientColors: [AppColors.romanceGradientStart, AppColors.romanceGradientEnd],
        ),
        _buildGenreCard(
          emoji: '🔮', title: 'Fantasy', description: 'Magical adventures',
          gradientColors: [AppColors.fantasyGradientStart, AppColors.fantasyGradientEnd],
        ),
        _buildGenreCard(
          emoji: '😂', title: 'Comedy', description: 'Hilarious moments',
          gradientColors: [AppColors.comedyGradientStart, AppColors.comedyGradientEnd],
        ),
      ],
    );
  }

  Widget _buildGenreCard({ required String emoji, required String title, required String description, required List<Color> gradientColors}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          Column(
            children: [
              Text(title, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(color: AppColors.primaryText.withValues(alpha: 0.8), fontSize: 14), textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubGenreGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
      ],
    );
  }

  Widget _buildSubGenreCard({required String emoji, required String title}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
