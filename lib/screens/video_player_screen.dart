// lib/screens/video_player_screen.dart

import 'dart:async';

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/providers/home_provider.dart';
import 'package:anidong/providers/local_data_provider.dart';
import 'package:anidong/data/services/scraping_service.dart';
import 'package:anidong/screens/download/download_options_screen.dart';
import 'package:anidong/screens/show_details_screen.dart';
import 'package:anidong/widgets/star_rating.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win;

class VideoPlayerScreen extends StatefulWidget {
  final Episode episode;

  const VideoPlayerScreen({super.key, required this.episode});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late WebViewController _controller;
  final _windowsController = win.WebviewController();
  bool _isWindowsInitialized = false;
  bool _isLoading = true;
  late Episode _detailedEpisode;
  bool _isDataLoading = true;
  String? _currentIframeUrl;
  bool _isFullScreen = false;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _detailedEpisode = widget.episode;
    _fetchDetails();
    _startHideTimer();
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _windowsController.dispose();
    }
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = true;
    });
    _startHideTimer();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _showControls = true;
      _startHideTimer();
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

      Provider.of<LocalDataProvider>(context, listen: false)
          .addToHistory(_detailedEpisode);
    }
  }

  Future<void> _initWebViewController(String url) async {
    setState(() {
      _isLoading = true;
    });

    final String referer = _detailedEpisode.show?.type == 'anime'
        ? ScrapingService.anoboyBaseUrl
        : ScrapingService.anichinBaseUrl;

    if (Platform.isWindows) {
      if (!_isWindowsInitialized) {
        await _windowsController.initialize();
        await _windowsController.setBackgroundColor(Colors.transparent);
        await _windowsController.setPopupWindowPolicy(win.WebviewPopupWindowPolicy.deny);
        _isWindowsInitialized = true;
      }
      await _windowsController.loadUrl(url);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(
          Uri.parse(url),
          headers: {
            'Referer': referer,
          },
        );
    }
  }

  void _changeServer(String url) {
    setState(() {
      _currentIframeUrl = url;
      _initWebViewController(url);
    });
  }

  Future<void> _openInBrowser() async {
    if (_currentIframeUrl != null) {
      final uri = Uri.parse(_currentIframeUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
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
      child: LayoutBuilder(builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth >= 800 && !_isFullScreen;

        if (_isFullScreen) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Center(child: _buildWebView()),
                if (!_showControls)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _toggleControls,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                if (_isLoading)
                  Center(
                      child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor)),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: FloatingActionButton(
                        backgroundColor: Colors.black54,
                        onPressed: _toggleFullScreen,
                        child: const Icon(Icons.fullscreen_exit,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: isWideScreen
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side: Video Player
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: Colors.black,
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: _buildVideoPlayerSection(),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildBrowserFallbackButton(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right Side: Scrollable Info
                    Expanded(
                      flex: 2,
                      child: CustomScrollView(
                        slivers: [
                          _buildAppBarSliver(),
                          SliverToBoxAdapter(
                            child: _buildDetailsContent(),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : CustomScrollView(
                  slivers: [
                    _buildAppBarSliver(withVideo: true),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildBrowserFallbackButton(),
                          _buildDetailsContent(),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      }),
    );
  }

  Widget _buildWebView() {
    if (Platform.isWindows) {
      if (!_isWindowsInitialized) {
        return const Center(child: Text('Initializing WebView...'));
      }
      return win.Webview(_windowsController);
    }
    return WebViewWidget(controller: _controller);
  }

  Widget _buildVideoPlayerSection() {
    if (_isDataLoading) {
      return Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor));
    }

    if (_currentIframeUrl == null) {
      return const Center(
        child: Text('No Video Available', style: TextStyle(color: Colors.white)),
      );
    }

    return Stack(
      children: [
        _buildWebView(),
        if (!_showControls)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleControls,
              child: Container(color: Colors.transparent),
            ),
          ),
        if (_isLoading)
          Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor)),
        Positioned(
          bottom: 10,
          right: 10,
          child: AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white, size: 30),
                onPressed: _toggleFullScreen,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrowserFallbackButton() {
    if (_currentIframeUrl == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: OutlinedButton.icon(
        onPressed: _openInBrowser,
        icon: const Icon(Icons.open_in_browser),
        label: const Text('Buka di Browser (Jika Blank)'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).primaryColor),
          foregroundColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  SliverAppBar _buildAppBarSliver({bool withVideo = false}) {
    return SliverAppBar(
      expandedHeight: withVideo ? 220 : 0,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: withVideo
          ? FlexibleSpaceBar(
              background: _buildVideoPlayerSection(),
            )
          : null,
      actions: [
        if (_detailedEpisode.show != null)
          Consumer<LocalDataProvider>(
            builder: (context, localData, child) {
              bool isBookmarked =
                  localData.isBookmarked(_detailedEpisode.show!);
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
    );
  }

  Widget _buildDetailsContent() {
    if (_isDataLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _detailedEpisode.show?.title ??
                _detailedEpisode.title ??
                'No Title',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('Episode ${_detailedEpisode.episodeNumber}',
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Text(_detailedEpisode.show?.status ?? 'Ongoing',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 13)),
              const Spacer(),
              StarRating(rating: _detailedEpisode.show?.rating ?? 0.0),
              const SizedBox(width: 4),
              Text(_detailedEpisode.show?.rating?.toString() ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    disabledBackgroundColor:
                        Theme.of(context).cardColor.withValues(alpha: 0.5),
                    disabledForegroundColor: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withValues(alpha: 0.3),
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
                    disabledBackgroundColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('Semua Episode'),
              onPressed: _detailedEpisode.show != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ShowDetailsScreen(show: _detailedEpisode.show!),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_detailedEpisode.videoServers != null &&
              _detailedEpisode.videoServers!.isNotEmpty) ...[
            const Text('Select Server',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12),
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          const Text('Download Section',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_detailedEpisode.downloadLinks != null &&
                      _detailedEpisode.downloadLinks!.isNotEmpty)
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
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
