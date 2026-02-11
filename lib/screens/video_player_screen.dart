// lib/screens/video_player_screen.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/providers/home_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _detailedEpisode = widget.episode;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final provider = Provider.of<HomeProvider>(context, listen: false);
    final detailed = await provider.getEpisodeDetails(widget.episode);

    if (mounted) {
      setState(() {
        _detailedEpisode = detailed;
        _isDataLoading = false;

        if (_detailedEpisode.iframeUrl != null) {
          _controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(const Color(0x00000000))
            ..setNavigationDelegate(
              NavigationDelegate(
                onProgress: (int progress) {
                  // Update loading bar.
                },
                onPageStarted: (String url) {},
                onPageFinished: (String url) {
                  setState(() {
                    _isLoading = false;
                  });
                },
                onWebResourceError: (WebResourceError error) {},
              ),
            )
            ..loadRequest(Uri.parse(_detailedEpisode.iframeUrl!));
        }
      });
    }
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
      appBar: AppBar(
        title: Text(_detailedEpisode.title ?? 'Playing Video'),
        backgroundColor: AppColors.background,
      ),
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _detailedEpisode.iframeUrl != null
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detailedEpisode.title ?? 'No Title',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Episode ${_detailedEpisode.episodeNumber}',
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Download Links',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (_detailedEpisode.downloadLinks != null && _detailedEpisode.downloadLinks!.isNotEmpty)
                          ..._detailedEpisode.downloadLinks!.map((dl) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: AppColors.surface,
                                child: ListTile(
                                  title: Text(dl['name'] ?? 'Download'),
                                  trailing: const Icon(Icons.download, color: AppColors.accent),
                                  onTap: () => _launchUrl(dl['url'] ?? ''),
                                ),
                              ))
                        else
                          const Text('No download links available.', style: TextStyle(color: AppColors.secondaryText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
