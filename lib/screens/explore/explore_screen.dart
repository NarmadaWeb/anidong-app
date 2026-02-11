// lib/screens/explore/explore_screen.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/api_service.dart';
import 'package:anidong/screens/video_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';

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
      // In a real app, we might want to filter by type in ApiService
      // but searchShows currently returns both. We can filter here.
      final results = await _apiService.searchShows(context, query);
      setState(() {
        _searchResults = results.where((s) => s.type == _searchType).toList();
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
      backgroundColor: AppColors.background,
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
                        const Text('🔍 Search & Explore', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                        const SizedBox(height: 4),
                        Text('Find your favorite Anime & Donghua', style: TextStyle(fontSize: 14, color: AppColors.primaryText.withValues(alpha: 0.8))),
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
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search title...',
                              border: InputBorder.none,
                              icon: Icon(Icons.search, color: AppColors.secondaryText),
                            ),
                            onSubmitted: _handleSearch,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
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
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.secondaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No results found.', style: TextStyle(color: AppColors.secondaryText)),
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
              // Convert Show to a placeholder Episode for the player screen
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
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(episode: episode),
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
                        ? Image.network(show.coverImageUrl!, width: 60, height: 80, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: AppColors.surface, width: 60, height: 80, child: const Icon(Icons.movie)),
                          )
                        : Container(color: AppColors.surface, width: 60, height: 80, child: const Icon(Icons.movie)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(show.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(show.status, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.secondaryText),
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
          emoji: '⚔️', title: 'Action', description: 'Fast-paced adventures', count: '150+ shows',
          gradientColors: [AppColors.actionGradientStart, AppColors.actionGradientEnd],
        ),
        _buildGenreCard(
          emoji: '💖', title: 'Romance', description: 'Heart-warming stories', count: '80+ shows',
          gradientColors: [AppColors.romanceGradientStart, AppColors.romanceGradientEnd],
        ),
        _buildGenreCard(
          emoji: '🔮', title: 'Fantasy', description: 'Magical adventures', count: '120+ shows',
          gradientColors: [AppColors.fantasyGradientStart, AppColors.fantasyGradientEnd],
        ),
        _buildGenreCard(
          emoji: '😂', title: 'Comedy', description: 'Hilarious moments', count: '95+ shows',
          gradientColors: [AppColors.comedyGradientStart, AppColors.comedyGradientEnd],
        ),
      ],
    );
  }

  Widget _buildGenreCard({ required String emoji, required String title, required String description, required String count, required List<Color> gradientColors}) {
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
          Text(count, style: TextStyle(color: AppColors.primaryText.withValues(alpha: 0.7), fontSize: 12)),
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
          Text(title, style: const TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
