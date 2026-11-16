import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class DriveEngineService {
  /// Live Official Google Drive REST API Key
  static const String driveApiKey = 'AIzaSyAsnrQhFjzUpBnQel1aCcFiWMebMkXxcwU';

  /// Extracts Google Drive File ID from any shareable link, view link, or direct CDN URL
  static String? extractFileId(String inputUrl) {
    final String clean = inputUrl.trim();
    if (clean.isEmpty) return null;

    // Pattern 1: /d/FILE_ID
    final RegExp dRegex = RegExp(r'\/d\/([a-zA-Z0-9_-]+)');
    final dMatch = dRegex.firstMatch(clean);
    if (dMatch != null && dMatch.groupCount >= 1) {
      return dMatch.group(1);
    }

    // Pattern 2: query parameter id=FILE_ID
    final Uri? uri = Uri.tryParse(clean);
    if (uri != null && uri.queryParameters.containsKey('id')) {
      return uri.queryParameters['id'];
    }

    // Pattern 3: /files/FILE_ID
    final RegExp filesRegex = RegExp(r'\/files\/([a-zA-Z0-9_-]+)');
    final filesMatch = filesRegex.firstMatch(clean);
    if (filesMatch != null && filesMatch.groupCount >= 1) {
      return filesMatch.group(1);
    }

    // Pattern 4: raw file ID string
    if (!clean.startsWith('http') && clean.length > 20) {
      return clean;
    }

    return null;
  }

  /// Converts any Google Drive link into direct playable media URL using Google Drive v3 REST API (Matches google-drive-music-engine.html!)
  static String convertDriveLinkToDirectStream(String inputUrl) {
    final String clean = inputUrl.trim();
    if (clean.isEmpty) return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

    final String? fileId = extractFileId(clean);
    if (fileId != null && fileId.isNotEmpty) {
      // Official Google Drive REST API v3 Direct Stream URL (exact formula from google-drive-music-engine.html)
      return 'https://www.googleapis.com/drive/v3/files/$fileId?alt=media&key=$driveApiKey';
    }

    return clean;
  }

  /// Get alternative fallback stream URLs for a Google Drive file ID
  static List<String> getStreamUrlCandidates(String rawUrl) {
    final String clean = rawUrl.trim();
    final String? fileId = extractFileId(clean);

    if (fileId != null && fileId.isNotEmpty) {
      return [
        'https://www.googleapis.com/drive/v3/files/$fileId?alt=media&key=$driveApiKey',
        'https://drive.usercontent.google.com/download?id=$fileId&export=download',
        'https://docs.google.com/uc?export=download&id=$fileId',
        'https://lh3.googleusercontent.com/d/$fileId',
      ];
    }

    return [clean];
  }

  /// Extract Folder ID from Google Drive Folder Link (`/folders/FOLDER_ID`)
  static String? extractFolderId(String inputUrl) {
    final String clean = inputUrl.trim();
    final RegExp folderIdRegex = RegExp(r'\/folders\/([a-zA-Z0-9_-]+)');
    final match = folderIdRegex.firstMatch(clean);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    if (!clean.startsWith('http') && clean.length > 15) {
      return clean;
    }
    return null;
  }

  /// Fetches all audio files directly from a Google Drive Folder via Google Drive v3 REST API
  /// using the Live Drive API Key `AIzaSyAsnrQhFjzUpBnQel1aCcFiWMebMkXxcwU`.
  static Future<List<Song>> fetchFolderSongsFromDriveApi({
    required String folderUrlOrId,
    required String hostedCoverUrl,
    required String artistName,
    required String albumName,
    required String genre,
  }) async {
    List<Song> songs = [];
    final String sanitizedCover = hostedCoverUrl.trim().isEmpty
        ? 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400'
        : hostedCoverUrl.trim();
    final String sanitizedAlbum = albumName.trim().isEmpty ? 'Exotic Collection' : albumName.trim();
    final String sanitizedArtist = artistName.trim().isEmpty ? 'Various Artists' : artistName.trim();

    final String? folderId = extractFolderId(folderUrlOrId);

    if (folderId != null) {
      try {
        final Uri apiUri = Uri.parse(
          'https://www.googleapis.com/drive/v3/files?q=%27$folderId%27+in+parents+and+trashed%3Dfalse&fields=files(id,name,mimeType,size)&key=$driveApiKey',
        );

        final response = await http.get(apiUri).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          if (data.containsKey('files')) {
            final List<dynamic> files = data['files'];
            int trackIndex = 1;
            for (var f in files) {
              final String fileId = f['id'] ?? '';
              final String rawFileName = f['name'] ?? 'Track $trackIndex';

              // Clean title (remove .mp3, .wav, .m4a extension)
              String trackTitle = rawFileName.replaceAll(RegExp(r'\.(mp3|wav|m4a|aac|flac)$', caseSensitive: false), '');
              if (trackTitle.isEmpty) trackTitle = '$sanitizedAlbum - Track $trackIndex';

              final String streamUrl = 'https://www.googleapis.com/drive/v3/files/$fileId?alt=media&key=$driveApiKey';

              songs.add(Song(
                id: 'drive_api_${DateTime.now().millisecondsSinceEpoch}_$trackIndex',
                title: trackTitle,
                artist: sanitizedArtist,
                album: sanitizedAlbum,
                duration: const Duration(minutes: 3, seconds: 30),
                audioUrl: streamUrl,
                coverUrl: sanitizedCover,
                genre: genre,
              ));
              trackIndex++;
            }
            if (songs.isNotEmpty) return songs;
          }
        }
      } catch (e) {
        debugPrint('Google Drive REST API fetch warning: $e');
      }
    }

    // Fallback: Parse multi-line links, JSON arrays, or comma-separated URLs
    return parseDriveFolderSongsFallback(
      folderUrlOrData: folderUrlOrId,
      hostedCoverUrl: sanitizedCover,
      artistName: sanitizedArtist,
      albumName: sanitizedAlbum,
      genre: genre,
    );
  }

  /// Fallback parser for multi-line text blocks or raw URL inputs
  static List<Song> parseDriveFolderSongsFallback({
    required String folderUrlOrData,
    required String hostedCoverUrl,
    required String artistName,
    required String albumName,
    required String genre,
  }) {
    List<Song> songs = [];
    final String sanitizedCover = hostedCoverUrl.trim().isEmpty
        ? 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400'
        : hostedCoverUrl.trim();
    final String sanitizedAlbum = albumName.trim().isEmpty ? 'Exotic Album' : albumName.trim();
    final String sanitizedArtist = artistName.trim().isEmpty ? 'Various Artists' : artistName.trim();

    final String input = folderUrlOrData.trim();

    // 1. JSON Array input
    if (input.startsWith('[') && input.endsWith(']')) {
      try {
        final List<dynamic> list = jsonDecode(input);
        for (int i = 0; i < list.length; i++) {
          final item = list[i];
          final String title = item['title'] ?? '$sanitizedAlbum - Track ${i + 1}';
          final String rawUrl = item['url'] ?? item['link'] ?? item['stream'] ?? '';
          final String directUrl = convertDriveLinkToDirectStream(rawUrl);

          songs.add(Song(
            id: 'drive_album_${DateTime.now().millisecondsSinceEpoch}_$i',
            title: title,
            artist: sanitizedArtist,
            album: sanitizedAlbum,
            duration: const Duration(minutes: 3, seconds: 40),
            audioUrl: directUrl,
            coverUrl: sanitizedCover,
            genre: genre,
          ));
        }
        if (songs.isNotEmpty) return songs;
      } catch (e) {
        debugPrint('Error parsing JSON drive folder input: $e');
      }
    }

    // 2. Multi-line or comma-separated URL extraction
    final RegExp urlRegex = RegExp(r'https?:\/\/[^\s,]+');
    final Iterable<Match> matches = urlRegex.allMatches(input);

    if (matches.isNotEmpty) {
      int index = 1;
      for (final match in matches) {
        final String rawUrl = match.group(0)!;
        final String directUrl = convertDriveLinkToDirectStream(rawUrl);

        songs.add(Song(
          id: 'drive_album_${DateTime.now().millisecondsSinceEpoch}_$index',
          title: '$sanitizedAlbum - Track $index',
          artist: sanitizedArtist,
          album: sanitizedAlbum,
          duration: const Duration(minutes: 3, seconds: 35),
          audioUrl: directUrl,
          coverUrl: sanitizedCover,
          genre: genre,
        ));
        index++;
      }
      if (songs.isNotEmpty) return songs;
    }

    // 3. Line split fallback
    final List<String> lines = input.split(RegExp(r'[\n,]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    for (int i = 0; i < lines.length; i++) {
      final String directUrl = convertDriveLinkToDirectStream(lines[i]);
      songs.add(Song(
        id: 'drive_track_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: '$sanitizedAlbum - Track ${i + 1}',
        artist: sanitizedArtist,
        album: sanitizedAlbum,
        duration: const Duration(minutes: 3, seconds: 30),
        audioUrl: directUrl,
        coverUrl: sanitizedCover,
        genre: genre,
      ));
    }

    return songs;
  }
}
