import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class LocalMusicService {
  static const String _prefFavLocalKey = 'favorite_local_song_ids';
  static const MethodChannel _channel = MethodChannel('com.global.exotic/device_audio');

  /// Requests storage permission via native Android MethodChannel
  static Future<bool> requestStoragePermission() async {
    try {
      final res = await _channel.invokeMethod('requestPermission');
      return res == true;
    } catch (e) {
      debugPrint('requestStoragePermission error: $e');
      return false;
    }
  }

  /// Checks if storage permission is currently granted
  static Future<bool> checkStoragePermission() async {
    try {
      final res = await _channel.invokeMethod('checkPermission');
      return res == true;
    } catch (e) {
      debugPrint('checkStoragePermission error: $e');
      return false;
    }
  }

  /// Scans device storage for all audio files (MediaStore Native + Filesystem BFS fallback)
  static Future<List<Song>> scanDeviceAudioFiles() async {
    final List<Song> foundSongs = [];
    final Set<String> processedPaths = {};

    // 1. Native MediaStore Content Query (Android 5 to Android 15+)
    try {
      final hasPerm = await checkStoragePermission();
      if (!hasPerm) {
        await requestStoragePermission();
      }

      final rawList = await _channel.invokeMethod('getDeviceAudioFiles');
      if (rawList is List && rawList.isNotEmpty) {
        for (final item in rawList) {
          try {
            final map = Map<String, dynamic>.from(item as Map);
            final path = map['path']?.toString() ?? '';
            if (path.isEmpty || processedPaths.contains(path)) continue;
            processedPaths.add(path);

            final int durationMs = (map['durationMs'] as num?)?.toInt() ?? 0;
            final title = map['title']?.toString().trim() ?? 'Local Track';
            final artist = map['artist']?.toString().trim() ?? 'Unknown Artist';
            final album = map['album']?.toString().trim() ?? 'Device Storage';

            foundSongs.add(
              Song(
                id: map['id']?.toString() ?? 'local_${path.hashCode}',
                title: title.isNotEmpty ? title : 'Local Track',
                artist: artist.isNotEmpty ? artist : 'Unknown Artist',
                album: album.isNotEmpty ? album : 'Device Storage',
                duration: Duration(milliseconds: durationMs > 0 ? durationMs : 180000),
                coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400',
                audioUrl: path,
                genre: '',
                language: 'local',
              ),
            );
          } catch (e) {
            debugPrint('Error parsing MediaStore song: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Native MediaStore query error: $e');
    }

    if (foundSongs.isNotEmpty) {
      foundSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      return foundSongs;
    }

    // 2. Fallback: Safe BFS Filesystem Directory Traversal
    final List<String> candidatePaths = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Podcasts',
      '/storage/emulated/0/Audiobooks',
      '/storage/emulated/0/Recordings',
      '/sdcard/Music',
      '/sdcard/Download',
    ];

    final audioExtensions = {'.mp3', '.m4a', '.wav', '.aac', '.flac', '.ogg', '.opus'};

    for (final pathStr in candidatePaths) {
      try {
        final dir = Directory(pathStr);
        if (await dir.exists()) {
          final list = dir.listSync(recursive: false, followLinks: false);
          for (final entity in list) {
            if (entity is File) {
              final lowerPath = entity.path.toLowerCase();
              final ext = audioExtensions.firstWhere(
                (e) => lowerPath.endsWith(e),
                orElse: () => '',
              );

              if (ext.isNotEmpty && !processedPaths.contains(entity.path)) {
                processedPaths.add(entity.path);
                final song = _parseFileToSong(entity);
                if (song != null) {
                  foundSongs.add(song);
                }
              }
            } else if (entity is Directory) {
              try {
                final subEntries = entity.listSync(recursive: false, followLinks: false);
                for (final sub in subEntries) {
                  if (sub is File) {
                    final lowerPath = sub.path.toLowerCase();
                    final ext = audioExtensions.firstWhere(
                      (e) => lowerPath.endsWith(e),
                      orElse: () => '',
                    );
                    if (ext.isNotEmpty && !processedPaths.contains(sub.path)) {
                      processedPaths.add(sub.path);
                      final song = _parseFileToSong(sub);
                      if (song != null) foundSongs.add(song);
                    }
                  }
                }
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning dir $pathStr: $e');
      }
    }

    foundSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return foundSongs;
  }

  /// Parses file name and path into a structured Song object
  static Song? _parseFileToSong(File file) {
    try {
      final fileName = file.uri.pathSegments.last;
      final nameWithoutExt = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').trim();

      String title = nameWithoutExt;
      String artist = 'Device Artist';
      final parentDir = file.parent.uri.pathSegments.reversed.skip(1).isNotEmpty
          ? file.parent.uri.pathSegments.reversed.skip(1).first
          : 'Local Music';
      String album = parentDir.isNotEmpty ? parentDir : 'Local Files';

      // Parse common "Artist - Title" filename format
      if (nameWithoutExt.contains(' - ')) {
        final parts = nameWithoutExt.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts.sublist(1).join(' - ').trim();
        }
      }

      // Estimate duration based on file size if unknown (~1MB ≈ 1 min of 128-192kbps audio)
      int durationSec = 180;
      try {
        final length = file.lengthSync();
        durationSec = (length / (1024 * 160)).clamp(30, 900).round();
      } catch (_) {}

      return Song(
        id: 'local_${file.path.hashCode}',
        title: title.isNotEmpty ? title : 'Local Track',
        artist: artist.isNotEmpty ? artist : 'Unknown Artist',
        album: album.isNotEmpty ? album : 'Device Storage',
        duration: Duration(seconds: durationSec),
        coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400',
        audioUrl: file.path, // Direct file path for DeviceFileSource
        genre: '',
        language: 'local',
      );
    } catch (e) {
      debugPrint('Error parsing file ${file.path}: $e');
      return null;
    }
  }

  /// Groups songs by Artist
  static Map<String, List<Song>> groupSongsByArtist(List<Song> songs) {
    final Map<String, List<Song>> map = {};
    for (final s in songs) {
      final a = s.artist.trim();
      final key = a.isNotEmpty ? a : 'Unknown Artist';
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  /// Groups songs by Album
  static Map<String, List<Song>> groupSongsByAlbum(List<Song> songs) {
    final Map<String, List<Song>> map = {};
    for (final s in songs) {
      final alb = s.album.trim();
      final key = alb.isNotEmpty ? alb : 'Unknown Album';
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  /// Load Favorite Local Song IDs
  static Future<Set<String>> getFavoriteLocalSongIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefFavLocalKey) ?? [];
    return list.toSet();
  }

  /// Toggle Favorite Local Song
  static Future<bool> toggleFavoriteLocalSong(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefFavLocalKey) ?? [];
    final set = list.toSet();
    bool isNowFav;
    if (set.contains(songId)) {
      set.remove(songId);
      isNowFav = false;
    } else {
      set.add(songId);
      isNowFav = true;
    }
    await prefs.setStringList(_prefFavLocalKey, set.toList());
    return isNowFav;
  }
}
