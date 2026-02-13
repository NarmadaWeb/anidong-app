// lib/screens/video_player_screen.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/providers/home_provider.dart';
import 'package:anidong/providers/local_data_provider.dart';
import 'package:anidong/screens/download/download_options_screen.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _detailedEpisode = widget.episode;
    _fetchDetails();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _toggleFullScreen();
      },
      child: Scaffold(
        backgroundColor: _isFullScreen ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
        body: _isFullScreen
            ? Stack(
                children: [
                  Center(child: WebViewWidget(controller: _controller)),
                  if (_isLoading)
                    Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      backgroundColor: Colors.black54,
                      onPressed: _toggleFullScreen,
                      child: const Icon(Icons.fullscreen_exit, color: Colors.white),
                    ),
                  ),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _isDataLoading
                          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                          : AspectRatio(
                              aspectRatio: 16 / 9,
                              child: _currentIframeUrl != null
                                  ? Stack(
                                      children: [
                                        WebViewWidget(controller: _controller),
                                        if (_isLoading)
                                          Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: IconButton(
                                            icon: const Icon(Icons.fullscreen, color: Colors.white, size: 30),
                                            onPressed: _toggleFullScreen,
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.black45,
                                            ),
                                          ),
                                        ),
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
                                color: isBookmarked ? Theme.of(context).primaryColor : Colors.white,
                              ),
                              onPressed: () => localData.toggleBookmark(_detailedEpisode.show!),
                            );
                          },
                        ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: _isDataLoading
                        ? SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)))
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _detailedEpisode.show?.title ?? _detailedEpisode.title ?? 'No Title',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                      child: Text('Episode ${_detailedEpisode.episodeNumber}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(_detailedEpisode.show?.status ?? 'Ongoing', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
                                    const Spacer(),
                                    StarRating(rating: _detailedEpisode.show?.rating ?? 0.0),
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
                                          backgroundColor: Theme.of(context).cardColor,
                                          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                                          disabledBackgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                                          disabledForegroundColor: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.3),
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
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
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
                                            selectedColor: Theme.of(context).primaryColor,
                                            labelStyle: TextStyle(color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12),
                                            backgroundColor: Theme.of(context).cardColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                const Text('Download Section', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: (_detailedEpisode.downloadLinks != null && _detailedEpisode.downloadLinks!.isNotEmpty)
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => DownloadOptionsScreen(
                                                  downloadLinks: _detailedEpisode.downloadLinks!,
                                                  title: _detailedEpisode.show?.title ?? 'Episode',
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    icon: const Icon(Icons.download),
                                    label: const Text('Download Episode'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).cardColor,
                                      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

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
                                            color: isCurrent ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: isCurrent ? Theme.of(context).primaryColor : Theme.of(context).dividerColor),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${ep.episodeNumber}',
                                            style: TextStyle(color: isCurrent ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
