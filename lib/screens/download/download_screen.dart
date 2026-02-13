// lib/screens/download/download_screen.dart

import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/api_service.dart';
import 'package:anidong/screens/video_player_screen.dart';
import 'package:anidong/data/models/episode_model.dart';
import 'package:flutter/material.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  late Future<Map<String, List<Show>>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = ApiService().getSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
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
          SingleChildScrollView(
            child: SafeArea(
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
                        const Text('🗓️ Jadwal Donghua', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                        const SizedBox(height: 4),
                        Text('Jadwal rilis episode terbaru', style: TextStyle(fontSize: 14, color: AppColors.primaryText.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  // Konten Utama
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FutureBuilder<Map<String, List<Show>>>(
                      future: _scheduleFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.secondaryText)));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No schedule available.', style: TextStyle(color: AppColors.secondaryText)));
                        }

                        final schedule = snapshot.data!;
                        final List<String> daysOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

                        return Column(
                          children: daysOrder
                              .where((day) => schedule.containsKey(day))
                              .map((day) => _buildDaySection(context, day, schedule[day]!))
                              .toList() +
                              [const SizedBox(height: 100)],
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(BuildContext context, String day, List<Show> shows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 12.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ),
        ...shows.map((show) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
               // Similar logic to Explore Screen
               final episode = Episode(
                id: show.id,
                showId: show.id,
                episodeNumber: 1, // Placeholder
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
                    child: show.coverImageUrl != null && show.coverImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: show.coverImageUrl!,
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppColors.surface),
                            errorWidget: (context, url, error) => const Icon(Icons.movie, color: AppColors.secondaryText),
                          )
                        : Container(color: AppColors.surface, width: 50, height: 70, child: const Icon(Icons.movie)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      show.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }
}
