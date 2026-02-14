// lib/screens/show_details_screen.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:anidong/screens/video_player_screen.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/star_rating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ShowDetailsScreen extends StatefulWidget {
  final Show show;

  const ShowDetailsScreen({super.key, required this.show});

  @override
  State<ShowDetailsScreen> createState() => _ShowDetailsScreenState();
}

class _ShowDetailsScreenState extends State<ShowDetailsScreen> {
  final ScrapingService _scrapingService = ScrapingService();
  late Show _show;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _show = widget.show;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    // Determine if we need to fetch specific details
    // If we came from search, we likely need to fetch the full episode list.
    // Anoboy search results often point to episodes or partial show data.

    if (_show.type == 'anime') {
      try {
        final updatedShow = await _scrapingService.getAnoboyShowDetails(_show);
        if (mounted) {
          setState(() {
            _show = updatedShow;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading details: $e')),
          );
        }
      }
    } else {
      // For Donghua (Anichin), typically we might need similar logic if the search result
      // is sparse, but let's assume for now anime is the focus as requested.
      // However, if needed, we could call getAnichinEpisodeDetails on a dummy episode
      // to get the show info, but Anichin search usually gives Show objects.
      // Since the request is specifically for Anime/Anoboy, we focus there.
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playEpisode(Episode episode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(episode: episode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Image (blurred)
          if (_show.coverImageUrl != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: CachedNetworkImage(
                  imageUrl: _show.coverImageUrl!,
                  fit: BoxFit.cover,
                   httpHeaders: const {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Referer': 'https://ww1.anoboy.boo/',
                  },
                ),
              ),
            ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section: Image and Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover Image
                      Hero(
                        tag: 'show_${_show.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _show.coverImageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: _show.coverImageUrl!,
                                  width: 120,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  httpHeaders: const {
                                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                                    'Referer': 'https://ww1.anoboy.boo/',
                                  },
                                  errorWidget: (context, url, error) => Container(color: AppColors.surface, width: 120, height: 180, child: const Icon(Icons.movie)),
                                )
                              : Container(color: AppColors.surface, width: 120, height: 180, child: const Icon(Icons.movie)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _show.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoChip(Icons.play_circle_outline, _show.type.toUpperCase(), Colors.blue),
                            const SizedBox(height: 4),
                            _buildInfoChip(Icons.info_outline, _show.status, _show.status.toLowerCase() == 'completed' ? Colors.green : Colors.orange),
                            const SizedBox(height: 8),
                            if (_show.rating != null && _show.rating! > 0)
                              Row(
                                children: [
                                  StarRating(rating: _show.rating!),
                                  const SizedBox(width: 4),
                                  Text(
                                    _show.rating!.toStringAsFixed(1),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Synopsis
                  if (_show.synopsis != null && _show.synopsis!.isNotEmpty) ...[
                    const Text('Synopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _show.synopsis!,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8), height: 1.5),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Episodes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Episodes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_show.episodes != null)
                        Text('${_show.episodes!.length} Episodes', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_show.episodes == null || _show.episodes!.isEmpty)
                     Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(Icons.movie_filter, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No episodes found.', style: TextStyle(color: Colors.grey)),
                            if (_show.type == 'anime')
                               const Padding(
                                 padding: EdgeInsets.only(top: 8.0),
                                 child: Text('Note: Search result might be an individual episode or movie.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                               ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _show.episodes!.length,
                      itemBuilder: (context, index) {
                        final ep = _show.episodes![index];
                        return InkWell(
                          onTap: () {
                             // Ensure the episode has the updated show info (including cover)
                             final fullEp = Episode(
                               id: ep.id,
                               showId: _show.id,
                               episodeNumber: ep.episodeNumber,
                               title: ep.title,
                               videoUrl: ep.videoUrl,
                               originalUrl: ep.originalUrl,
                               thumbnailUrl: ep.thumbnailUrl ?? _show.coverImageUrl,
                               show: _show, // Pass the fully populated show
                             );
                             _playEpisode(fullEp);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${ep.episodeNumber}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                   const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
