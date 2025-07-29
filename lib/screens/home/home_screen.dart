import 'package:anidong/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> newEpisodes = List.generate(9, (index) => 'Episode Terbaru ${index + 1}');
  bool _isLoadingMore = false;

  void _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      int currentLength = newEpisodes.length;
      newEpisodes.addAll(List.generate(9, (index) => 'Episode Tambahan ${currentLength + index + 1}'));
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBanner(context),
          _buildSectionTitle('New Episodes'),
          _buildNewEpisodesGrid(),
          _buildLoadMoreButton(),
          _buildSectionTitle('Recommended For You'),
          _buildRecommendedList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return SizedBox(
      height: 380,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: "https://imgs.search.brave.com/KDa7rfrU632SyD6Gowf1I9cCYs6MpSR04v1UHN8-HPU/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9zdGF0/aWMwLmdhbWVyYW50/aW1hZ2VzLmNvbS93/b3JkcHJlc3Mvd3At/Y29udGVudC91cGxv/YWRzLzIwMjQvMTEv/ZmVhdHVyZWQtaW1h/Z2UtZm9yLWlzZWth/aS1kb25naHVhLXJh/bmtlZC5qcGc",
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: AppColors.surface),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, AppColors.background.withOpacity(0.7), Colors.transparent],
                stops: const [0.0, 0.4, 1.0],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 20, left: 0, right: 0,
            child: Column(
              children: [
                const Text('SPY x FAMILY', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Action • Comedy • Shounen', style: TextStyle(color: AppColors.secondaryText)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Boxicons.bx_play_circle, size: 22),
                      label: const Text('Play'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Boxicons.bx_plus, size: 22),
                      label: const Text('My List'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface.withOpacity(0.8), foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  // ===== KODE YANG DIPERBAIKI ADA DI SINI =====
  Widget _buildNewEpisodesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 16 / 10,
      ),
      itemCount: newEpisodes.length,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PERBAIKAN: Menggunakan Expanded untuk mengisi ruang secara fleksibel
            // dan mencegah overflow.
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              newEpisodes[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: _isLoadingMore
            ? const CircularProgressIndicator(color: AppColors.accent)
            : OutlinedButton(
                onPressed: _loadMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: AppColors.surface.withOpacity(0.8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                ),
                child: const Text('Muat Lebih Banyak'),
              ),
      ),
    );
  }

  Widget _buildRecommendedList() {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(
              width: 120,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
