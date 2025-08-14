// lib/data/content_repository.dart

class ContentRepository {
  // Data source utama untuk seluruh aplikasi
  static final List<Map<String, dynamic>> allContent = [
    {'id': 1, 'title': 'Jujutsu Kaisen', 'mode': 'anime', 'type': 'episode'},
    {'id': 2, 'title': 'Perfect World', 'mode': 'donghua', 'type': 'episode'},
    {'id': 3, 'title': 'One Piece', 'mode': 'anime', 'type': 'episode'},
    {'id': 4, 'title': 'Throne of Seal', 'mode': 'donghua', 'type': 'episode'},
    {'id': 5, 'title': 'My Hero Academia', 'mode': 'anime', 'type': 'episode'},
    {'id': 6, 'title': 'Apotheosis', 'mode': 'donghua', 'type': 'episode'},
    {'id': 7, 'title': 'Attack on Titan', 'mode': 'anime', 'type': 'episode'},
    {'id': 8, 'title': 'Swallowed Star', 'mode': 'donghua', 'type': 'episode'},
    {'id': 9, 'title': 'Solo Leveling', 'mode': 'anime', 'type': 'recommended'},
    {'id': 10, 'title': 'Battle Through the Heavens', 'mode': 'donghua', 'type': 'recommended'},
    {'id': 11, 'title': 'Demon Slayer', 'mode': 'anime', 'type': 'recommended'},
  ];

  // Fungsi untuk melakukan pencarian
  static List<Map<String, dynamic>> search(String query) {
    if (query.isEmpty) {
      return []; // Kembalikan daftar kosong jika query kosong
    }

    // Filter data berdasarkan judul, tidak case-sensitive
    final results = allContent
        .where((item) =>
            item['title']!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return results;
  }
}
