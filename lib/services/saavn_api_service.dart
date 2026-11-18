import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../models/artist_model.dart';

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

  /// Search Artists with full profile metadata
  /// Endpoint: /api/search/artists?query={name}&limit={limit}
  static Future<List<Artist>> searchArtists(String query, {int limit = 5}) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];
    try {
      final uri = Uri.parse('$baseUrl/api/search/artists?query=${Uri.encodeComponent(clean)}&limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final results = jsonDecode(res.body)['data']?['results'] as List? ?? [];
      final List<Artist> artists = [];
      for (final r in results) {
        final id = r['id']?.toString() ?? '';
        final name = Song.clean(r['name']?.toString() ?? '');
        final images = r['image'] as List? ?? [];
        String imgUrl = '';
        if (images.isNotEmpty) {
          imgUrl = images.last['url']?.toString() ?? '';
        }
        if (imgUrl.isEmpty && images.isNotEmpty) {
          imgUrl = images.first['url']?.toString() ?? '';
        }
        final role = r['role']?.toString() ?? 'Artist';
        artists.add(
          Artist(
            id: id,
            name: name,
            imageUrl: imgUrl.isNotEmpty ? imgUrl : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400',
            bio: '$name verified artist channel on EXOTIC MUSIC.',
            language: '',
            artistType: role,
            genre: 'Popular',
            isVerified: true,
          ),
        );
      }
      return artists;
    } catch (e) {
      debugPrint('SaavnApiService.searchArtists error: $e');
      return [];
    }
  }

  /// Search Albums
  /// Endpoint: /api/search/albums?query={name}&limit={limit}
  static Future<List<Map<String, dynamic>>> searchAlbums(String query, {int limit = 10}) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];
    try {
      final uri = Uri.parse('$baseUrl/api/search/albums?query=${Uri.encodeComponent(clean)}&limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final results = jsonDecode(res.body)['data']?['results'] as List? ?? [];
      final List<Map<String, dynamic>> albums = [];
      for (final a in results) {
        final images = a['image'] as List? ?? [];
        final imgUrl = images.isNotEmpty ? images.last['url']?.toString() ?? '' : '';
        albums.add({
          'id': a['id']?.toString() ?? '',
          'title': Song.clean(a['name']?.toString() ?? a['title']?.toString() ?? 'Album'),
          'artist': Song.clean(a['primaryArtists']?.toString() ?? a['artist']?.toString() ?? 'Various Artists'),
          'coverUrl': imgUrl,
          'year': a['year']?.toString() ?? '2026',
        });
      }
      return albums;
    } catch (e) {
      debugPrint('SaavnApiService.searchAlbums error: $e');
      return [];
    }
  }

  /// Search Artist ID by Name
  /// Endpoint: /api/search/artists?query={name}&limit=1
  static Future<String?> getArtistIdByName(String artistName) async {
    if (artistName.trim().isEmpty) return null;
    try {
      final uri = Uri.parse('$baseUrl/api/search/artists?query=${Uri.encodeComponent(artistName.trim())}&limit=1');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final results = jsonDecode(res.body)['data']?['results'] as List? ?? [];
      if (results.isNotEmpty) {
        return results.first['id']?.toString();
      }
    } catch (e) {
      debugPrint('SaavnApiService.getArtistIdByName error: $e');
    }
    return null;
  }

  /// 6. Artist Profile Details, Top Songs, Albums & Similar Artists
  /// Endpoint: /api/artists/{id}?songCount=20&albumCount=10
  static Future<Map<String, dynamic>?> getArtistDetails(String artistId) async {
    if (artistId.trim().isEmpty) return null;

    try {
      final uri = Uri.parse('$baseUrl/api/artists/${artistId.trim()}?songCount=25&albumCount=10');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body)['data'] ?? {};
      final List rawTopSongs = data['topSongs'] ?? [];
      final List rawSingles = data['singles'] ?? [];
      final List images = data['image'] as List? ?? [];
      final String image = images.isNotEmpty ? images.last['url'] : '';

      String bioText = '';
      if (data['bio'] is List && (data['bio'] as List).isNotEmpty) {
        bioText = (data['bio'] as List).first?['text']?.toString() ?? '';
      } else if (data['bio'] != null) {
        bioText = data['bio'].toString();
      }

      return {
        'id': data['id'],
        'name': Song.clean(data['name']),
        'imageUrl': image,
        'followerCount': data['followerCount'] ?? 0,
        'isVerified': data['isVerified'] ?? true,
        'bio': bioText,
        'topSongs': rawTopSongs.map((e) => Song.fromSaavnJson(e)).toList(),
        'singles': rawSingles.map((e) => Song.fromSaavnJson(e)).toList(),
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

  /// 8B. Get Famous Verified Songs for a Language (From Official Top Playlists)
  static Future<List<Song>> getFamousSongsForLanguage(String language, {int limit = 15}) async {
    final cleanLang = language.trim();
    final Map<String, String> playlistQueries = {
      'Punjabi': 'Punjabi Superhits',
      'Hindi': 'Hindi Superhits',
      'International': 'English Global Hits',
      'English': 'English Global Hits',
      'Telugu': 'Telugu Superhits',
      'Tamil': 'Tamil Superhits',
      'Malayalam': 'Malayalam Hits',
      'Marathi': 'Marathi Hits',
      'Gujarati': 'Gujarati Hits',
      'Bengali': 'Bengali Hits',
      'Kannada': 'Kannada Hits',
      'Haryanvi': 'Haryanvi Hits',
      'Bhojpuri': 'Bhojpuri Hits',
    };

    final query = playlistQueries[cleanLang] ?? '$cleanLang Superhits';

    try {
      final playlists = await searchPlaylists(query, limit: 3);
      if (playlists.isNotEmpty) {
        final songs = await getPlaylistSongs(playlists.first.id, limit: limit);
        if (songs.isNotEmpty) return songs;
      }
      return await searchSongs('$cleanLang Hits', limit: limit);
    } catch (e) {
      debugPrint('Error getting famous songs for $cleanLang: $e');
      return await searchSongs(cleanLang, limit: limit);
    }
  }

  static final Map<String, List<LyricLine>> _lyricsMemoryCache = {};

  /// 9. Real-Time Synced Lyrics Engine (Parallel LRCLIB + JioSaavn with Fast Cache)
  static Future<List<LyricLine>> fetchRealtimeLyrics(
    String rawTitle,
    String rawArtist, {
    int durationSeconds = 0,
    String? songId,
  }) async {
    final cacheKey = '${songId ?? ""}_${rawTitle.toLowerCase()}_${rawArtist.toLowerCase()}';
    if (_lyricsMemoryCache.containsKey(cacheKey)) {
      return _lyricsMemoryCache[cacheKey]!;
    }

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

    // Fast Parallel Execution: LRCLIB and JioSaavn at the same time (3.5s timeout)
    final lrclibFuture = () async {
      try {
        final queryParam = durationSeconds > 0 ? '&duration=$durationSeconds' : '';
        final lrcUrl = 'https://lrclib.net/api/get?track_name=${Uri.encodeComponent(title)}&artist_name=${Uri.encodeComponent(artist)}$queryParam';
        final res = await http.get(Uri.parse(lrcUrl)).timeout(const Duration(milliseconds: 3500));
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
        }
      } catch (_) {}

      // Fallback search on LRCLIB
      try {
        final searchUrl = 'https://lrclib.net/api/search?q=${Uri.encodeComponent("$title $artist")}';
        final res = await http.get(Uri.parse(searchUrl)).timeout(const Duration(milliseconds: 3500));
        if (res.statusCode == 200) {
          final List searchList = jsonDecode(res.body) as List? ?? [];
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
      } catch (_) {}
      return <LyricLine>[];
    }();

    final saavnFuture = () async {
      if (songId != null && songId.isNotEmpty) {
        try {
          final saavnLrcUrl = 'https://www.jiosaavn.com/api.php?__call=lyrics.getLyrics&ctx=web6dot0&api_version=4&_format=json&_marker=0&lyrics_id=${songId.trim()}';
          final saavnRes = await http.get(Uri.parse(saavnLrcUrl)).timeout(const Duration(milliseconds: 3500));
          if (saavnRes.statusCode == 200) {
            final data = jsonDecode(saavnRes.body);
            final String? lyricsHtml = data['lyrics'];
            if (lyricsHtml != null && lyricsHtml.isNotEmpty) {
              final plain = lyricsHtml.replaceAll('<br/>', '\n').replaceAll('<br>', '\n');
              final parsed = _parsePlain(plain, durationSeconds);
              if (parsed.isNotEmpty) return parsed;
            }
          }
        } catch (_) {}
      }
      return <LyricLine>[];
    }();

    try {
      final results = await Future.wait([lrclibFuture, saavnFuture]);
      final lrclibLyrics = results[0];
      final saavnLyrics = results[1];

      if (lrclibLyrics.isNotEmpty) {
        _lyricsMemoryCache[cacheKey] = lrclibLyrics;
        return lrclibLyrics;
      }
      if (saavnLyrics.isNotEmpty) {
        _lyricsMemoryCache[cacheKey] = saavnLyrics;
        return saavnLyrics;
      }
    } catch (e) {
      debugPrint('Error loading realtime lyrics: $e');
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
