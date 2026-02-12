
import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/genre_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Model Tests', () {
    test('Genre.fromJson and toJson', () {
      final json = {'id': 1, 'name': 'Action'};
      final genre = Genre.fromJson(json);
      expect(genre.id, 1);
      expect(genre.name, 'Action');
      expect(genre.toJson(), json);
    });

    test('Show.fromJson and toJson', () {
      final json = {
        'id': 1,
        'title': 'Naruto',
        'synopsis': 'A ninja with a dream',
        'type': 'anime',
        'status': 'finished',
        'cover_image_url': 'https://example.com/cover.jpg',
        'banner_image_url': 'https://example.com/banner.jpg',
        'rating': 8.5,
        'release_year': 2002,
        'genres': [{'id': 1, 'name': 'Action'}],
        'created_at': '2023-01-01T00:00:00.000',
        'original_url': 'https://example.com/naruto'
      };
      final show = Show.fromJson(json);
      expect(show.id, 1);
      expect(show.title, 'Naruto');
      expect(show.genres.length, 1);
      expect(show.genres[0].name, 'Action');
      expect(show.toJson(), json);
    });

    test('Episode.fromJson and toJson', () {
      final json = {
        'id': 101,
        'show_id': 1,
        'episode_number': 1,
        'title': 'The Arrival',
        'video_url': 'https://example.com/video.mp4',
        'iframe_url': 'https://example.com/iframe',
        'original_url': 'https://example.com/ep1',
        'download_links': [{'name': 'Mega', 'link': 'https://mega.nz'}],
        'video_servers': [{'name': 'Server 1', 'link': 'https://server1.com'}],
        'thumbnail_url': 'https://example.com/thumb.jpg',
        'duration_minute': 24,
        'release_date': '2023-01-01T00:00:00.000',
        'show': {
          'id': 1,
          'title': 'Naruto',
          'synopsis': null,
          'type': 'anime',
          'status': 'ongoing',
          'cover_image_url': null,
          'banner_image_url': null,
          'rating': null,
          'release_year': null,
          'genres': [],
          'created_at': null,
          'original_url': null
        }
      };
      final episode = Episode.fromJson(json);
      expect(episode.id, 101);
      expect(episode.showId, 1);
      expect(episode.downloadLinks?.first['name'], 'Mega');
      expect(episode.show?.title, 'Naruto');
      expect(episode.toJson(), json);
    });
  });
}
