import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/services/api_service.dart';
import 'package:anidong/screens/video_player_screen.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _searchAndNavigate() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if it's a URL
      if (query.startsWith('http')) {
        // Assume it's a direct link to an episode or show
        final dummyEpisode = Episode(
          id: query.hashCode,
          showId: 0,
          episodeNumber: 1, // Default
          title: 'Loading...',
          videoUrl: '',
          originalUrl: query,
        );
        if (mounted) {
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(episode: dummyEpisode),
            ),
          );
        }
      } else {
        // Search for show
        final results = await _apiService.searchShows(context, query);
        if (mounted) {
          if (results.isNotEmpty) {
            final show = results.first;
            // Create a dummy episode to open the detail view
            // Assuming VideoPlayerScreen handles Show URL or we need to pass a show object
            // VideoPlayerScreen takes 'episode'.
            // We'll create an episode that points to the show's original URL.
            final dummyEpisode = Episode(
              id: show.id,
              showId: show.id,
              episodeNumber: 1,
              title: show.title,
              videoUrl: '',
              originalUrl: show.originalUrl ?? '',
              show: show,
            );

             Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(episode: dummyEpisode),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No results found')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Boxicons.bx_arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Input Manual', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter Code, URL, or Title',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Boxicons.bx_search, color: AppColors.accent),
                  onPressed: _isLoading ? null : _searchAndNavigate,
                ),
              ),
              onSubmitted: (_) => _searchAndNavigate(),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator(color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
