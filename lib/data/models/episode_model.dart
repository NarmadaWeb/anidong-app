// lib/data/models/episode_model.dart

import 'package:anidong/data/models/show_model.dart';

class Episode {
  final int id;
  final int showId;
  final int episodeNumber;
  final String? title;
  final String videoUrl;
  final String? iframeUrl;
  final String? originalUrl;
  final List<Map<String, String>>? downloadLinks;
  final List<Map<String, String>>? videoServers;
  final String? thumbnailUrl;
  final int? durationMinute;
  final DateTime? releaseDate;
  final Show? show;
  final String? prevEpisodeUrl;
  final String? nextEpisodeUrl;

  Episode({
    required this.id,
    required this.showId,
    required this.episodeNumber,
    this.title,
    required this.videoUrl,
    this.iframeUrl,
    this.originalUrl,
    this.downloadLinks,
    this.videoServers,
    this.thumbnailUrl,
    this.durationMinute,
    this.releaseDate,
    this.show,
    this.prevEpisodeUrl,
    this.nextEpisodeUrl,
  });

  Episode copyWith({
    int? id,
    int? showId,
    int? episodeNumber,
    String? title,
    String? videoUrl,
    String? iframeUrl,
    String? originalUrl,
    List<Map<String, String>>? downloadLinks,
    List<Map<String, String>>? videoServers,
    String? thumbnailUrl,
    int? durationMinute,
    DateTime? releaseDate,
    Show? show,
    String? prevEpisodeUrl,
    String? nextEpisodeUrl,
  }) {
    return Episode(
      id: id ?? this.id,
      showId: showId ?? this.showId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      iframeUrl: iframeUrl ?? this.iframeUrl,
      originalUrl: originalUrl ?? this.originalUrl,
      downloadLinks: downloadLinks ?? this.downloadLinks,
      videoServers: videoServers ?? this.videoServers,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationMinute: durationMinute ?? this.durationMinute,
      releaseDate: releaseDate ?? this.releaseDate,
      show: show ?? this.show,
      prevEpisodeUrl: prevEpisodeUrl ?? this.prevEpisodeUrl,
      nextEpisodeUrl: nextEpisodeUrl ?? this.nextEpisodeUrl,
    );
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? 0,
      showId: json['show_id'] ?? 0,
      episodeNumber: json['episode_number'] ?? 0,
      title: json['title'],
      videoUrl: json['video_url'] ?? '',
      iframeUrl: json['iframe_url'],
      originalUrl: json['original_url'],
      downloadLinks: json['download_links'] != null
          ? List<Map<String, String>>.from((json['download_links'] as List)
              .map((item) => Map<String, String>.from(item)))
          : null,
      videoServers: json['video_servers'] != null
          ? List<Map<String, String>>.from((json['video_servers'] as List)
              .map((item) => Map<String, String>.from(item)))
          : null,
      thumbnailUrl: json['thumbnail_url'],
      durationMinute: json['duration_minute'],
      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'])
          : null,
      // Secara aman membuat objek Show jika datanya ada
      show: json['show'] != null ? Show.fromJson(json['show']) : null,
      prevEpisodeUrl: json['prev_episode_url'],
      nextEpisodeUrl: json['next_episode_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'show_id': showId,
      'episode_number': episodeNumber,
      'title': title,
      'video_url': videoUrl,
      'iframe_url': iframeUrl,
      'original_url': originalUrl,
      'download_links': downloadLinks,
      'video_servers': videoServers,
      'thumbnail_url': thumbnailUrl,
      'duration_minute': durationMinute,
      'release_date': releaseDate?.toIso8601String(),
      'show': show?.toJson(),
      'prev_episode_url': prevEpisodeUrl,
      'next_episode_url': nextEpisodeUrl,
    };
  }
}
