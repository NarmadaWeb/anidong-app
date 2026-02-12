
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/services/database_helper.dart';
import 'package:anidong/providers/local_data_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Setup sqflite_common_ffi
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('LocalDataProvider Tests', () {
    late LocalDataProvider provider;

    setUp(() {
      DatabaseHelper.databasePath = inMemoryDatabasePath;
      provider = LocalDataProvider();
    });

    test('Toggle bookmark updates state', () async {
      final show = Show(
        id: 1,
        title: 'Test Anime',
        type: 'anime',
        status: 'ongoing',
        genres: [],
        originalUrl: 'https://example.com/test'
      );

      // Initial state
      expect(provider.isBookmarked(show), false);

      // Toggle on
      await provider.toggleBookmark(show);
      expect(provider.isBookmarked(show), true);
      expect(provider.animeBookmarks.length, 1);

      // Toggle off
      await provider.toggleBookmark(show);
      expect(provider.isBookmarked(show), false);
      expect(provider.animeBookmarks.length, 0);
    });
  });
}
