// lib/data/services/api_service.dart

import 'dart:convert';
import 'package:anidong/data/models/episode_model.dart';
import 'package:anidong/data/models/show_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Emulator Android: 'http://10.0.2.2:8000/api/v1'
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1';

  final String _authToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoyLCJyb2xlIjoidXNlciIsImV4cCI6MTc1NTI2NTU2OSwiaWF0IjoxNzU1MTc5MTY5fQ.6GgIL8b-cU-FQaSRGlv8hD9svfxk81TEfF0hM8y4h_8";

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_authToken',
  };

  // Helper function yang sudah benar
  List<T> _parseResponseToList<T>({
    required http.Response response,
    required String dataKey, // Ini adalah kunci yang akan kita gunakan
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);

      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
        final dataObject = decodedBody['data'];

        if (dataObject is Map<String, dynamic> && dataObject.containsKey(dataKey)) {
          final dataList = dataObject[dataKey];

          if (dataList is List) {
            return dataList.map((item) => fromJson(item as Map<String, dynamic>)).toList();
          }
        }
      }

      return [];

    } else {
      try {
        final error = json.decode(response.body)['error_message'] ?? 'Failed to load data (status code: ${response.statusCode})';
        throw Exception(error);
      } catch (e) {
        throw Exception('Failed to parse error response (status code: ${response.statusCode})');
      }
    }
  }

  // Endpoint: GET /episodes/recent
  Future<List<Episode>> getRecentEpisodes() async {
    final response = await http.get(Uri.parse('$_baseUrl/episodes/recent'), headers: _headers);
    return _parseResponseToList<Episode>(
      response: response,
      dataKey: 'episodes', // <- Benar, mencari kunci "episodes"
      fromJson: (json) => Episode.fromJson(json),
    );
  }

  // Endpoint: GET /shows/top-rated
  Future<List<Show>> getTopRatedShows() async {
    final response = await http.get(Uri.parse('$_baseUrl/shows/top-rated'), headers: _headers);
    return _parseResponseToList<Show>(
      response: response,
      dataKey: 'shows', // <- Benar, mencari kunci "shows"
      fromJson: (json) => Show.fromJson(json),
    );
  }

  // Endpoint: GET /shows/search?q={title}
  Future<List<Show>> searchShows(String query) async {
    if (query.isEmpty) return [];

    final response = await http.get(
      Uri.parse('$_baseUrl/shows/search?q=${Uri.encodeComponent(query)}'),
      headers: _headers,
    );
    // Asumsi endpoint search juga mengembalikan { "data": { "shows": [...] } }
    return _parseResponseToList<Show>(
      response: response,
      dataKey: 'shows', // <- Benar, mencari kunci "shows"
      fromJson: (json) => Show.fromJson(json),
    );
  }
}
