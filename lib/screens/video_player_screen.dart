// lib/screens/video_player_screen.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/providers/home_provider.dart';
import 'package:anidong/providers/local_data_provider.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Episode episode;

  const VideoPlayerScreen({super.key, required this.episode});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  late Episode _detailedEpisode;
  bool _isDataLoading = true;
  String? _currentIframeUrl;

  @override
  void initState() {
    super.initState();
    _detailedEpisode = widget.episode;
    _fetchDetails();
  }

  Future<void> _fetchDetails([Episode? episode]) async {
    setState(() {
      _isDataLoading = true;
    });

    final targetEpisode = episode ?? widget.episode;
    final provider = Provider.of<HomeProvider>(context, listen: false);
    final detailed = await provider.getEpisodeDetails(targetEpisode);

    if (mounted) {
      setState(() {
        _detailedEpisode = detailed;
        _isDataLoading = false;
        _currentIframeUrl = _detailedEpisode.iframeUrl;

        if (_currentIframeUrl != null) {
          _initWebViewController(_currentIframeUrl!);
        }
      });

      Provider.of<LocalDataProvider>(context, listen: false).addToHistory(_detailedEpisode);
    }
  }

  void _initWebViewController(String url) {
    _isLoading = true;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() { _isLoading = false; });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _changeServer(String url) {
    setState(() {
      _currentIframeUrl = url;
      _initWebViewController(url);
    });
  }

  void _playEpisode(Episode episode) {
    _fetchDetails(episode);
  }

  void _playEpisodeFromUrl(String url) {
    final nextEp = Episode(
      id: url.hashCode,
      showId: _detailedEpisode.showId,
      episodeNumber: 0,
      title: 'Loading...',
      videoUrl: '',
      originalUrl: url,
      show: _detailedEpisode.show,
    );
    _fetchDetails(nextEp);
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: _isDataLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _currentIframeUrl != null
                        ? Stack(
                            children: [
                              WebViewWidget(controller: _controller),
                              if (_isLoading)
                                const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                            ],
                          )
                        : Container(
                            color: Colors.black,
                            child: const Center(
                              child: Text('No Video Available', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                  ),
            ),
            actions: [
              if (_detailedEpisode.show != null)
                Consumer<LocalDataProvider>(
                  builder: (context, localData, child) {
                    bool isBookmarked = localData.isBookmarked(_detailedEpisode.show!);
                    return IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? AppColors.accent : Colors.white,
                      ),
                      onPressed: () => localData.toggleBookmark(_detailedEpisode.show!),
                    );
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: _isDataLoading
                ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detailedEpisode.show?.title ?? _detailedEpisode.title ?? 'No Title',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text('Episode ${_detailedEpisode.episodeNumber}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 12),
                            Text(_detailedEpisode.show?.status ?? 'Ongoing', style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                            const Spacer(),
                            const Icon(Icons.star, color: AppColors.yellow400, size: 18),
                            const SizedBox(width: 4),
                            Text(_detailedEpisode.show?.rating?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.skip_previous),
                                label: const Text('Prev'),
                                onPressed: _detailedEpisode.prevEpisodeUrl != null
                                    ? () => _playEpisodeFromUrl(_detailedEpisode.prevEpisodeUrl!)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.surface.withValues(alpha: 0.5),
                                  disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.skip_next),
                                label: const Text('Next'),
                                onPressed: _detailedEpisode.nextEpisodeUrl != null
                                    ? () => _playEpisodeFromUrl(_detailedEpisode.nextEpisodeUrl!)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
                                  disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        if (_detailedEpisode.videoServers != null && _detailedEpisode.videoServers!.isNotEmpty) ...[
                          const Text('Select Server', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 36,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _detailedEpisode.videoServers!.length,
                              itemBuilder: (context, index) {
                                final server = _detailedEpisode.videoServers![index];
                                final isSelected = _currentIframeUrl == server['url'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(server['name'] ?? 'Server ${index + 1}'),
                                    selected: isSelected,
                                    onSelected: (selected) => _changeServer(server['url']!),
                                    selectedColor: AppColors.accent,
                                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.primaryText, fontSize: 12),
                                    backgroundColor: AppColors.surface,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (_detailedEpisode.show?.episodes != null) ...[
                          const Text('Episodes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: _detailedEpisode.show!.episodes!.length,
                            itemBuilder: (context, index) {
                              final ep = _detailedEpisode.show!.episodes![index];
                              final isCurrent = ep.episodeNumber == _detailedEpisode.episodeNumber;
                              return InkWell(
                                onTap: () => _playEpisode(ep),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isCurrent ? AppColors.accent : AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isCurrent ? AppColors.accent : Colors.white10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${ep.episodeNumber}',
                                    style: TextStyle(color: isCurrent ? Colors.white : AppColors.primaryText, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],

                        const Text('Download Section', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (_detailedEpisode.downloadLinks != null && _detailedEpisode.downloadLinks!.isNotEmpty)
                          ..._detailedEpisode.downloadLinks!.map((dl) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () => _launchUrl(dl['url'] ?? ''),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                                child: Row(
                                  children: [
                                    const Icon(Icons.download_for_offline, color: AppColors.accent),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(dl['name'] ?? 'Download', style: const TextStyle(fontWeight: FontWeight.w500))),
                                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.secondaryText),
                                  ],
                                ),
                              ),
                            ),
                          ))
                        else
                          const Text('No download links available.', style: TextStyle(color: AppColors.secondaryText)),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
