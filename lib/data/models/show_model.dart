// lib/data/models/show_model.dart

import 'package:anidong/data/models/genre_model.dart';
import 'package:anidong/data/models/episode_model.dart';

class Show {
  final int id;
  final String title;
  final String? synopsis;
  final String type;
  final String status;
  final String? coverImageUrl;
  final String? bannerImageUrl;
  final double? rating;
  final int? releaseYear;
  final String? studio;
  final String? source;
  final String? duration;
  final List<Genre> genres;
  final DateTime? createdAt;
  final String? originalUrl;
  final List<Episode>? episodes;

  Show({
    required this.id,
    required this.title,
    this.synopsis,
    required this.type,
    required this.status,
    this.coverImageUrl,
    this.bannerImageUrl,
    this.rating,
    this.releaseYear,
    this.studio,
    this.source,
    this.duration,
    required this.genres,
    this.createdAt,
    this.originalUrl,
    this.episodes,
  });

  Show copyWith({
    int? id,
    String? title,
    String? synopsis,
    String? type,
    String? status,
    String? coverImageUrl,
    String? bannerImageUrl,
    double? rating,
    int? releaseYear,
    String? studio,
    String? source,
    String? duration,
    List<Genre>? genres,
    DateTime? createdAt,
    String? originalUrl,
    List<Episode>? episodes,
  }) {
    return Show(
      id: id ?? this.id,
      title: title ?? this.title,
      synopsis: synopsis ?? this.synopsis,
      type: type ?? this.type,
      status: status ?? this.status,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      rating: rating ?? this.rating,
      releaseYear: releaseYear ?? this.releaseYear,
      studio: studio ?? this.studio,
      source: source ?? this.source,
      duration: duration ?? this.duration,
      genres: genres ?? this.genres,
      createdAt: createdAt ?? this.createdAt,
      originalUrl: originalUrl ?? this.originalUrl,
      episodes: episodes ?? this.episodes,
    );
  }

  factory Show.fromJson(Map<String, dynamic> json) {
    var genreList = <Genre>[];
    if (json['genres'] != null) {
      genreList = (json['genres'] as List)
          .map((g) => Genre.fromJson(g))
          .toList();
    }

    var epList = <Episode>[];
    if (json['episodes'] != null) {
      epList = (json['episodes'] as List)
          .map((e) => Episode.fromJson(e))
          .toList();
    }

    return Show(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No Title',
      synopsis: json['synopsis'],
      type: json['type'] ?? 'anime',
      status: json['status'] ?? 'ongoing',
      coverImageUrl: json['cover_image_url'],
      bannerImageUrl: json['banner_image_url'],
      rating: (json['rating'] as num?)?.toDouble(),
      releaseYear: json['release_year'],
      studio: json['studio'],
      source: json['source'],
      duration: json['duration'],
      genres: genreList,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      originalUrl: json['original_url'],
      episodes: epList.isNotEmpty ? epList : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'synopsis': synopsis,
      'type': type,
      'status': status,
      'cover_image_url': coverImageUrl,
      'banner_image_url': bannerImageUrl,
      'rating': rating,
      'release_year': releaseYear,
      'studio': studio,
      'source': source,
      'duration': duration,
      'genres': genres.map((g) => g.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'original_url': originalUrl,
      'episodes': episodes?.map((e) => e.toJson()).toList(),
    };
  }
}
