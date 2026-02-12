
import 'package:anidong/data/models/show_model.dart';
import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/services/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Setup sqflite_common_ffi
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() {
      DatabaseHelper.databasePath = inMemoryDatabasePath;
      dbHelper = DatabaseHelper();
    });

    test('Insert and Get Bookmark', () async {
      final show = Show(
        id: 1,
        title: 'Test Anime',
        type: 'anime',
        status: 'ongoing',
        genres: [],
        originalUrl: 'https://example.com/test'
      );

      await dbHelper.insertBookmark(show);
      final bookmarks = await dbHelper.getBookmarks('anime');

      expect(bookmarks.length, 1);
      expect(bookmarks.first.title, 'Test Anime');

      await dbHelper.deleteBookmark(show);
      final bookmarksAfterDelete = await dbHelper.getBookmarks('anime');
      expect(bookmarksAfterDelete.length, 0);
    });

    test('Insert and Get History', () async {
      final episode = Episode(
        id: 101,
        showId: 1,
        episodeNumber: 1,
        videoUrl: 'https://example.com/video',
        originalUrl: 'https://example.com/ep1'
      );

      await dbHelper.insertHistory(episode);
      final history = await dbHelper.getHistory();

      expect(history.length, 1);
      expect(history.first.originalUrl, 'https://example.com/ep1');

      await dbHelper.clearHistory();
      final historyAfterClear = await dbHelper.getHistory();
      expect(historyAfterClear.length, 0);
    });
  });
}
