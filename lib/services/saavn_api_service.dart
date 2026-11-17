import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';
import '../models/playlist_model.dart';

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
  static Future<List<Playlist>> searchPlaylists(String query, {int limit = 10}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/search/playlists?query=${Uri.encodeComponent(query)}&limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final List results = jsonDecode(res.body)['data']?['results'] ?? [];
      return results.map((e) => Playlist.fromSaavnJson(e)).toList();
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

  /// 9. Real-Time Synced Lyrics Engine (LRCLIB + JioSaavn Fallback)
  static Future<List<LyricLine>> fetchRealtimeLyrics(
    String rawTitle,
    String rawArtist, {
    int durationSeconds = 0,
    String? songId,
  }) async {
    // Clean title and artist from suffixes like (From "Film"), [Official Video], etc.
    String title = Song.clean(rawTitle)
        .replaceAll(RegExp(r'\(.*?(from|feat|ft|official|video|audio|remix|version|deluxe|soundtrack).*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\s*-\s*Single'), '')
        .replaceAll(RegExp(r'\s*-\s*EP'), '')
        .trim();
    if (title.isEmpty) title = rawTitle.trim();

    String artist = Song.clean(rawArtist).split(',').first.trim();
    if (artist.isEmpty) artist = rawArtist.trim();

    try {
      // Step A: Exact query with duration
      String lrcUrl = 'https://lrclib.net/api/get?track_name=${Uri.encodeComponent(title)}&artist_name=${Uri.encodeComponent(artist)}';
      if (durationSeconds > 0) {
        lrcUrl += '&duration=$durationSeconds';
      }

      var res = await http.get(Uri.parse(lrcUrl)).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200 && durationSeconds > 0) {
        final retryUrl = 'https://lrclib.net/api/get?track_name=${Uri.encodeComponent(title)}&artist_name=${Uri.encodeComponent(artist)}';
        res = await http.get(Uri.parse(retryUrl)).timeout(const Duration(seconds: 6));
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final String? synced = data['syncedLyrics'];
        final String? plain = data['plainLyrics'];
        if (synced != null && synced.isNotEmpty) {
          final parsed = _parseLrc(synced);
          if (parsed.isNotEmpty) return parsed;
        }
        if (plain != null && plain.isNotEmpty) {
          final parsed = _parsePlain(plain, durationSeconds);
          if (parsed.isNotEmpty) return parsed;
        }
      } else {
        // Step B: Search query on LRCLIB
        final searchUrl = 'https://lrclib.net/api/search?q=${Uri.encodeComponent("$title $artist")}';
        final searchRes = await http.get(Uri.parse(searchUrl)).timeout(const Duration(seconds: 6));
        if (searchRes.statusCode == 200) {
          final List searchList = jsonDecode(searchRes.body) as List? ?? [];
          if (searchList.isNotEmpty) {
            final first = searchList.first;
            final String? synced = first['syncedLyrics'];
            final String? plain = first['plainLyrics'];
            if (synced != null && synced.isNotEmpty) {
              final parsed = _parseLrc(synced);
              if (parsed.isNotEmpty) return parsed;
            }
            if (plain != null && plain.isNotEmpty) {
              final parsed = _parsePlain(plain, durationSeconds);
              if (parsed.isNotEmpty) return parsed;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('SaavnApiService: LRCLIB error: $e');
    }

    // Step C: JioSaavn fallback
    if (songId != null && songId.isNotEmpty) {
      try {
        final saavnLrcUrl = 'https://www.jiosaavn.com/api.php?__call=lyrics.getLyrics&ctx=web6dot0&api_version=4&_format=json&_marker=0&lyrics_id=${songId.trim()}';
        final saavnRes = await http.get(Uri.parse(saavnLrcUrl)).timeout(const Duration(seconds: 6));
        if (saavnRes.statusCode == 200) {
          final data = jsonDecode(saavnRes.body);
          final String? lyricsHtml = data['lyrics'];
          if (lyricsHtml != null && lyricsHtml.isNotEmpty) {
            final plain = lyricsHtml.replaceAll('<br/>', '\n').replaceAll('<br>', '\n');
            final parsed = _parsePlain(plain, durationSeconds);
            if (parsed.isNotEmpty) return parsed;
          }
        }
      } catch (e) {
        debugPrint('SaavnApiService: JioSaavn lyrics fallback error: $e');
      }
    }

    return [];
  }

  static List<LyricLine> _parseLrc(String lrcContent) {
    final List<LyricLine> result = [];
    final lines = lrcContent.split('\n');
    final regex = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)');

    for (final line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        final min = int.tryParse(match.group(1) ?? '0') ?? 0;
        final sec = double.tryParse(match.group(2) ?? '0.0') ?? 0.0;
        final text = Song.clean(match.group(3) ?? '').trim();
        if (text.isNotEmpty) {
          final ms = ((min * 60 + sec) * 1000).toInt();
          result.add(LyricLine(timestamp: Duration(milliseconds: ms), text: text));
        }
      }
    }
    return result;
  }

  static List<LyricLine> _parsePlain(String plainText, int durationSeconds) {
    final List<LyricLine> result = [];
    final lines = plainText
        .split('\n')
        .map((l) => Song.clean(l).trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    final totalDurationMs = (durationSeconds > 0 ? durationSeconds : 180) * 1000;
    final intervalMs = (totalDurationMs / lines.length).toInt();

    for (int i = 0; i < lines.length; i++) {
      result.add(LyricLine(
        timestamp: Duration(milliseconds: i * intervalMs),
        text: lines[i],
      ));
    }
    return result;
  }
}
