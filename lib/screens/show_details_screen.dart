import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/api_service.dart';
import 'package:anidong/screens/video_player_screen.dart';
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
  late Show _show;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _show = widget.show;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedShow = await _apiService.getShowDetails(_show);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_show.title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading && (_show.episodes == null || _show.episodes!.isEmpty)
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: _show.coverImageUrl ?? '',
                          width: 120,
                          height: 180,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context).cardColor,
                            width: 120,
                            height: 180,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context).cardColor,
                            width: 120,
                            height: 180,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _show.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_show.rating != null)
                              Row(
                                children: [
                                  StarRating(rating: _show.rating!),
                                  const SizedBox(width: 8),
                                  Text(
                                    _show.rating.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            _buildInfoRow('Status', _show.status),
                            _buildInfoRow('Type', _show.type),
                            if (_show.releaseYear != null) _buildInfoRow('Released', '${_show.releaseYear}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Metadata Table (Studio, Source, Duration, etc.)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildTableRow('Semua Episode', _show.title, isLink: true),
                        const Divider(height: 16),
                        if (_show.studio != null) ...[
                          _buildTableRow('Studio', _show.studio!),
                          const Divider(height: 16),
                        ],
                        if (_show.source != null) ...[
                          _buildTableRow('Source', _show.source!),
                          const Divider(height: 16),
                        ],
                        if (_show.duration != null) ...[
                          _buildTableRow('Durasi', _show.duration!),
                          const Divider(height: 16),
                        ],
                         if (_show.genres.isNotEmpty) ...[
                          _buildTableRow('Genre', _show.genres.map((g) => g.name).join(', ')),
                          const Divider(height: 16),
                        ],
                         if (_show.rating != null)
                          _buildTableRow('Score', _show.rating.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Synopsis
                  if (_show.synopsis != null && _show.synopsis!.isNotEmpty) ...[
                    const Text(
                      'Synopsis',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _show.synopsis!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Episodes Section
                  const Text(
                    'All Episodes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_show.episodes != null && _show.episodes!.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _show.episodes!.length,
                      itemBuilder: (context, index) {
                        final ep = _show.episodes![index];
                        return InkWell(
                          onTap: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(episode: ep),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (ep.thumbnailUrl != null && ep.thumbnailUrl!.isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: ep.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Theme.of(context).canvasColor),
                                    errorWidget: (context, url, error) => Container(
                                      color: Theme.of(context).canvasColor,
                                      child: const Icon(Icons.image_not_supported, size: 40),
                                    ),
                                  )
                                else
                                  Container(
                                    color: Theme.of(context).canvasColor,
                                    child: const Center(
                                      child: Icon(Icons.movie_creation_outlined, size: 40, color: Colors.grey),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.8),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      'Episode ${ep.episodeNumber}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        shadows: [
                                          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(0, 1)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  else if (!_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No episodes found.'),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String label, String value, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isLink ? Colors.blueAccent : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isLink ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
