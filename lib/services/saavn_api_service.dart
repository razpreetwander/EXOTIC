import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class SaavnApiService {
  static const String baseUrl = 'https://jiosaavn-api-lc4i.onrender.com';

  /// Call on app startup to wake up the Render service
  static Future<void> pingServer() async {
    try {
      await http.get(Uri.parse(baseUrl)).timeout(const Duration(seconds: 8));
      debugPrint('SaavnApiService: Server pinged successfully');
    } catch (e) {
      debugPrint('SaavnApiService: Server ping background: $e');
    }
  }

  /// 1. Direct Song Search (Immediate 320kbps Playable Stream)
  /// Endpoint: /api/search/songs?query={query}&page={page}&limit={limit}
  static Future<List<Song>> searchSongs(String query, {int page = 0, int limit = 20}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final uri = Uri.parse('$baseUrl/api/search/songs?query=${Uri.encodeComponent(cleanQuery)}&page=$page&limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      final List results = data['data']?['results'] ?? [];
      return results.map((e) => Song.fromSaavnJson(e)).toList();
    } catch (e) {
      debugPrint('SaavnApiService.searchSongs error: $e');
      return [];
    }
  }

  /// 2. Global Search (All categories: Songs, Albums, Artists, Playlists)
  /// Endpoint: /api/search?query={query}
  static Future<Map<String, dynamic>> globalSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return {};

    try {
      final uri = Uri.parse('$baseUrl/api/search?query=${Uri.encodeComponent(cleanQuery)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return {};

      final data = jsonDecode(res.body)['data'] ?? {};
      final songsList = (data['songs']?['results'] as List? ?? [])
          .map((e) => Song.fromSaavnGlobalJson(e))
          .toList();

      return {
        'songs': songsList,
        'albums': data['albums']?['results'] ?? [],
        'artists': data['artists']?['results'] ?? [],
        'playlists': data['playlists']?['results'] ?? [],
      };
    } catch (e) {
      debugPrint('SaavnApiService.globalSearch error: $e');
      return {};
    }
  }

  /// 3. Get Single Full Song by ID (Resolves downloadUrl for Global Search taps)
  /// Endpoint: /api/songs/{id}
  static Future<Song?> getSongById(String songId) async {
    if (songId.trim().isEmpty) return null;

    try {
      final uri = Uri.parse('$baseUrl/api/songs/${songId.trim()}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      final List list = data['data'] ?? [];
      if (list.isEmpty) return null;
      return Song.fromSaavnJson(list.first);
    } catch (e) {
      debugPrint('SaavnApiService.getSongById error: $e');
      return null;
    }
  }

  /// 4. Auto-Play / Radio Similar Song Suggestions
  /// Endpoint: /api/songs/{id}/suggestions?limit={limit}
  static Future<List<Song>> getSuggestions(String songId, {int limit = 15}) async {
    if (songId.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$baseUrl/api/songs/${songId.trim()}/suggestions?limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final List list = jsonDecode(res.body)['data'] ?? [];
      return list.map((e) => Song.fromSaavnJson(e)).toList();
    } catch (e) {
      debugPrint('SaavnApiService.getSuggestions error: $e');
      return [];
    }
  }

  /// 5. Album Details & Full Tracklist
  /// Endpoint: /api/albums?id={id}
  static Future<Map<String, dynamic>?> getAlbumDetails(String albumId) async {
    if (albumId.trim().isEmpty) return null;

    try {
      final uri = Uri.parse('$baseUrl/api/albums?id=${albumId.trim()}');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body)['data'] ?? {};
      final List rawSongs = data['songs'] ?? [];
      final List images = data['image'] as List? ?? [];
      final String cover = images.isNotEmpty ? images.last['url'] : '';

      return {
        'id': data['id'],
        'name': Song.clean(data['name']),
        'year': data['year']?.toString() ?? '',
        'coverUrl': cover,
        'songs': rawSongs.map((e) => Song.fromSaavnJson(e)).toList(),
      };
    } catch (e) {
      debugPrint('SaavnApiService.getAlbumDetails error: $e');
      return null;
    }
  }

  /// 6. Artist Profile Details, Top Songs & Albums
  /// Endpoint: /api/artists/{id}?songCount=20&albumCount=10
  static Future<Map<String, dynamic>?> getArtistDetails(String artistId) async {
    if (artistId.trim().isEmpty) return null;

    try {
      final uri = Uri.parse('$baseUrl/api/artists/${artistId.trim()}?songCount=20&albumCount=10');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body)['data'] ?? {};
      final List rawTopSongs = data['topSongs'] ?? [];
      final List images = data['image'] as List? ?? [];
      final String image = images.isNotEmpty ? images.last['url'] : '';

      return {
        'id': data['id'],
        'name': Song.clean(data['name']),
        'imageUrl': image,
        'followerCount': data['followerCount'] ?? 0,
        'topSongs': rawTopSongs.map((e) => Song.fromSaavnJson(e)).toList(),
        'topAlbums': data['topAlbums'] ?? [],
        'similarArtists': data['similarArtists'] ?? [],
      };
    } catch (e) {
      debugPrint('SaavnApiService.getArtistDetails error: $e');
      return null;
    }
  }

  /// 7. Search Playlists (For Home Screen Feed & Trending Charts)
  /// Endpoint: /api/search/playlists?query={query}&limit={limit}
  static Future<List<dynamic>> searchPlaylists(String query, {int limit = 10}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/search/playlists?query=${Uri.encodeComponent(query)}&limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      return jsonDecode(res.body)['data']?['results'] ?? [];
    } catch (e) {
      debugPrint('SaavnApiService.searchPlaylists error: $e');
      return [];
    }
  }

  /// 8. Get Playlist Songs (Directly Playable with 320kbps Streams)
  /// Endpoint: /api/playlists?id={id}&page=0&limit={limit}
  static Future<List<Song>> getPlaylistSongs(String playlistId, {int limit = 50}) async {
    if (playlistId.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$baseUrl/api/playlists?id=${playlistId.trim()}&page=0&limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];

      final List rawSongs = jsonDecode(res.body)['data']?['songs'] ?? [];
      return rawSongs.map((e) => Song.fromSaavnJson(e)).toList();
    } catch (e) {
      debugPrint('SaavnApiService.getPlaylistSongs error: $e');
      return [];
    }
  }
}
