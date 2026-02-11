// lib/screens/history/history_screen.dart

import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/providers/local_data_provider.dart';
import 'package:anidong/screens/video_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              Provider.of<LocalDataProvider>(context, listen: false).clearHistory();
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
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
          // Konten
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Teks
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⏰ Watch History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                      const SizedBox(height: 4),
                      Text('Continue where you left off', style: TextStyle(fontSize: 14, color: AppColors.primaryText.withOpacity(0.8))),
                    ],
                  ),
                ),
                // Konten Utama
                Expanded(
                  child: Consumer<LocalDataProvider>(
                    builder: (context, localData, child) {
                      final history = localData.history;
                      if (history.isEmpty) {
                        return const Center(child: Text('No history yet.', style: TextStyle(color: AppColors.secondaryText)));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final episode = history[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildHistoryItem(context, episode),
                          );
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Episode episode) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VideoPlayerScreen(episode: episode)),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 112,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: episode.thumbnailUrl != null
                    ? Image.network(episode.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.movie))
                    : const Icon(Icons.movie),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(episode.title ?? episode.show?.title ?? 'Unknown',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText)),
                  const SizedBox(height: 4),
                  Text('Episode ${episode.episodeNumber}', style: const TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Watched', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.secondaryText),
              onPressed: () {
                Provider.of<LocalDataProvider>(context, listen: false).removeFromHistory(episode);
              },
            )
          ],
        ),
      ),
    );
  }
}
