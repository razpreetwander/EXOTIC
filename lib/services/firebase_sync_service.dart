import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';
import '../models/artist_model.dart';
import '../models/playlist_model.dart';

class FirebaseSyncService {
  /// Official New Firebase Realtime Database URL
  static const String databaseUrl = 'https://exoticglobalmusic-default-rtdb.firebaseio.com';

  /// Save all custom songs to Firebase Realtime Database
  static Future<bool> saveSongsToFirebase(List<Song> songs) async {
    try {
      final Uri uri = Uri.parse('$databaseUrl/songs.json');
      final List<Map<String, dynamic>> payload = songs.map((s) => s.toJson()).toList();
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('SUCCESS: Saved ${songs.length} songs to Firebase Realtime Database!');
        return true;
      }
    } catch (e) {
      debugPrint('Firebase Sync Error (Songs): $e');
    }
    return false;
  }

  /// Fetch all songs from Firebase Realtime Database
  static Future<List<Song>> fetchSongsFromFirebase() async {
    try {
      final Uri uri = Uri.parse('$databaseUrl/songs.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) => Song.fromJson(Map<String, dynamic>.from(item))).toList();
        } else if (data is Map) {
          List<Song> list = [];
          data.forEach((k, v) {
            if (v != null && v is Map) {
              list.add(Song.fromJson(Map<String, dynamic>.from(v)));
            }
          });
          return list;
        }
      }
    } catch (e) {
      debugPrint('Firebase Fetch Error (Songs): $e');
    }
    return [];
  }

  /// Save all artists to Firebase Realtime Database
  static Future<bool> saveArtistsToFirebase(List<Artist> artists) async {
    try {
      final Uri uri = Uri.parse('$databaseUrl/artists.json');
      final List<Map<String, dynamic>> payload = artists.map((a) => a.toJson()).toList();
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Firebase Sync Error (Artists): $e');
      return false;
    }
  }

  /// Fetch all artists from Firebase Realtime Database
  static Future<List<Artist>> fetchArtistsFromFirebase() async {
    try {
      final Uri uri = Uri.parse('$databaseUrl/artists.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) => Artist.fromJson(Map<String, dynamic>.from(item))).toList();
        } else if (data is Map) {
          List<Artist> list = [];
          data.forEach((k, v) {
            if (v != null && v is Map) {
              list.add(Artist.fromJson(Map<String, dynamic>.from(v)));
            }
          });
          return list;
        }
      }
    } catch (e) {
      debugPrint('Firebase Fetch Error (Artists): $e');
    }
    return [];
  }

  /// Save all playlists to Firebase Realtime Database
  static Future<bool> savePlaylistsToFirebase(List<Playlist> playlists) async {
    try {
      final Uri uri = Uri.parse('$databaseUrl/playlists.json');
      final List<Map<String, dynamic>> payload = playlists.map((p) => p.toJson()).toList();
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Firebase Sync Error (Playlists): $e');
      return false;
    }
  }

  /// Save all Hero Banners to Firebase Realtime Database
  static Future<bool> saveHeroBannersToFirebase(List<Map<String, String>> banners) async {
    try {
      final Uri uri = Uri.parse('$databaseUrl/heroBanners.json');
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(banners),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Firebase Sync Error (HeroBanners): $e');
      return false;
    }
  }

  /// Save all Genres to Firebase Realtime Database
  static Future<bool> saveGenresToFirebase(List<Map<String, String>> genres) async {
    try {
      final Uri uri = Uri.parse('$databaseUrl/genres.json');
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(genres),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Firebase Sync Error (Genres): $e');
      return false;
    }
  }

  /// Save announcement to Firebase Realtime Database
  static Future<bool> saveAnnouncementToFirebase(String announcement) async {
    try {
      final Uri uri = Uri.parse('$databaseUrl/announcement.json');
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(announcement),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Firebase Sync Error (Announcement): $e');
      return false;
    }
  }

  /// Fetch announcement from Firebase Realtime Database
  static Future<String?> fetchAnnouncementFromFirebase() async {
    try {
      final Uri uri = Uri.parse('$databaseUrl/announcement.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.body != 'null') {
        return jsonDecode(response.body) as String?;
      }
    } catch (e) {
      debugPrint('Firebase Fetch Error (Announcement): $e');
    }
    return null;
  }
}
