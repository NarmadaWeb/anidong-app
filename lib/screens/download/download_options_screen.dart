// lib/screens/download/download_options_screen.dart

import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadOptionsScreen extends StatelessWidget {
  final List<Map<String, String>> downloadLinks;
  final String title;

  const DownloadOptionsScreen({
    super.key,
    required this.downloadLinks,
    required this.title,
  });

  Future<void> _launchUrl(BuildContext context, String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
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
        title: Text('Download $title', style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.titleLarge?.color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: downloadLinks.length,
        itemBuilder: (context, index) {
          final link = downloadLinks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () => _launchUrl(context, link['url'] ?? ''),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Boxicons.bx_download, color: AppColors.accent),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        link['name'] ?? 'Download Link',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Boxicons.bx_chevron_right, color: Theme.of(context).iconTheme.color),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
