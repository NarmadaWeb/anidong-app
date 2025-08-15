// lib/data/models/episode_model.dart

import 'package:anidong/data/models/show_model.dart';

class Episode {
  final int id;
  final int showId;
  final int episodeNumber;
  final String? title;
  final String videoUrl;
  final String? thumbnailUrl;
  final int? durationMinute;
  final DateTime? releaseDate;
  final Show? show;

  Episode({
    required this.id,
    required this.showId,
    required this.episodeNumber,
    this.title,
    required this.videoUrl,
    this.thumbnailUrl,
    this.durationMinute,
    this.releaseDate,
    this.show,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? 0,
      showId: json['show_id'] ?? 0,
      episodeNumber: json['episode_number'] ?? 0,
      title: json['title'],
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      durationMinute: json['duration_minute'],
      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'])
          : null,
      // Secara aman membuat objek Show jika datanya ada
      show: json['show'] != null ? Show.fromJson(json['show']) : null,
    );
  }
}
