import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/api_service.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedType = 'anime';
  String _selectedDay = 'Senin';
  late Future<List<Show>> _scheduleFuture;

  final List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _getCurrentDayName();
    _fetchSchedule();
  }

  String _getCurrentDayName() {
    final now = DateTime.now();
    // weekday 1 = Monday
    if (now.weekday >= 1 && now.weekday <= 7) {
      return _days[now.weekday - 1];
    }
    return 'Senin';
  }

  void _fetchSchedule() {
    setState(() {
      // API expects lowercase day
      _scheduleFuture = ApiService().getDailySchedule(
        _selectedType,
        _selectedDay.toLowerCase(),
      );
    });
  }

  void _onTypeChanged(String type) {
    if (_selectedType != type) {
      setState(() {
        _selectedType = type;
      });
      _fetchSchedule();
    }
  }

  void _onDayChanged(String day) {
    if (_selectedDay != day) {
      setState(() {
        _selectedDay = day;
      });
      _fetchSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Rilis', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Type Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeButton('Anime', 'anime'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTypeButton('Donghua', 'donghua'),
                ),
              ],
            ),
          ),

          // Day Selector
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _buildDayChip(day),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: FutureBuilder<List<Show>>(
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

                final shows = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: shows.length,
                  itemBuilder: (context, index) {
                    final show = shows[index];
                    return _buildShowCard(show);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => _onTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: AppColors.secondaryText.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.secondaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDayChip(String day) {
    final isSelected = _selectedDay == day;
    return GestureDetector(
      onTap: () => _onDayChanged(day),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: AppColors.secondaryText.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          day,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.secondaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildShowCard(Show show) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: show.coverImageUrl != null && show.coverImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: show.coverImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(color: AppColors.surface),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.error, color: AppColors.secondaryText),
                    ),
                  )
                : Container(
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(Icons.movie, color: AppColors.secondaryText, size: 40),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          show.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
