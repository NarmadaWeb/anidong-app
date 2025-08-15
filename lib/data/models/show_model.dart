// lib/data/models/show_model.dart

import 'package:anidong/data/models/genre_model.dart';

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
  final List<Genre> genres;
  final DateTime? createdAt; // <-- TAMBAHKAN INI

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
    required this.genres,
    this.createdAt, // <-- TAMBAHKAN INI
  });

  factory Show.fromJson(Map<String, dynamic> json) {
    var genreList = <Genre>[];
    if (json['genres'] != null) {
      genreList = (json['genres'] as List)
          .map((g) => Genre.fromJson(g))
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
      genres: genreList,
      // <-- TAMBAHKAN INI
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
