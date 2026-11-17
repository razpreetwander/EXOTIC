import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';

class YtMusicService {
  static final YoutubeExplode _yt = YoutubeExplode();
  static final Map<String, String> _streamCache = {};

  /// Clean video titles by removing official tags, video/audio noise
  static String cleanTitle(String raw) {
    return raw
        .replaceAll(RegExp(r'\(Official.*?\)|\[Official.*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Lyrics.*?\)|\[Lyrics.*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Audio.*?\)|\[Audio.*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Full Video.*?\)|\[Full Video.*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[4K.*?\]|\(4K.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\|.*$'), '')
        .trim();
  }

  /// 1. SEARCH ONLY SONGS (Strict filtering: no live streams, 45s - 12m)
  static Future<List<Song>> searchSongsOnly(String query, {int limit = 15}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final lower = cleanQuery.toLowerCase();
    final hasModifier = lower.contains('song') ||
        lower.contains('audio') ||
        lower.contains('remix') ||
        lower.contains('phonk') ||
        lower.contains('lofi') ||
        lower.contains('slowed');

    final searchQuery = hasModifier ? cleanQuery : '$cleanQuery song';

    try {
      final results = await _yt.search.search(searchQuery);
      final List<Song> songList = [];

      for (final video in results) {
        final sec = video.duration?.inSeconds ?? 0;
        // Strict Song Filter: No live streams, min 45s, max 12 mins (720s)
        if (video.isLive || sec < 45 || sec > 720) continue;

        final videoId = video.id.value;
        final title = cleanTitle(video.title);
        final artist = video.author.replaceAll(' - Topic', '').trim();
        final thumb = video.thumbnails.highResUrl.isNotEmpty
            ? video.thumbnails.highResUrl
            : video.thumbnails.mediumResUrl;

        songList.add(
          Song(
            id: 'yt_$videoId',
            title: title.isNotEmpty ? title : video.title,
            artist: artist.isNotEmpty ? artist : 'YouTube Music',
            album: 'YouTube Release',
            duration: video.duration ?? const Duration(minutes: 3),
            coverUrl: thumb,
            audioUrl: '', // Resolved dynamically upon playback
          ),
        );

        if (songList.length >= limit) break;
      }

      return songList;
    } catch (e) {
      debugPrint('YtMusicService searchSongsOnly error: $e');
      return [];
    }
  }

  /// 2. GET DIRECT AUDIO STREAM URL IN BACKGROUND (Zero-Video, Direct M4A/WebM)
  static Future<String> getDirectAudioStreamUrl(String rawVideoId) async {
    final videoId = rawVideoId.replaceFirst('yt_', '').trim();
    if (videoId.isEmpty) return '';

    if (_streamCache.containsKey(videoId)) {
      return _streamCache[videoId]!;
    }

    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) return '';

      final selectedStream = audioStreams.withHighestBitrate();
      final url = selectedStream.url.toString();
      _streamCache[videoId] = url;
      return url;
    } catch (e) {
      debugPrint('YtMusicService getDirectAudioStreamUrl error for $videoId: $e');
      return '';
    }
  }

  /// 3. AUTOMATIC BACKGROUND FALLBACK FOR ANY MISSING OR FAILED SONG
  static Future<String> resolveFallbackAudio(String rawTitle, String rawArtist) async {
    try {
      final cleanT = rawTitle
          .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .trim();
      final cleanA = rawArtist.split(',').first.trim();
      final query = '$cleanT $cleanA official audio';

      final results = await _yt.search.search(query);
      for (final video in results) {
        final sec = video.duration?.inSeconds ?? 0;
        if (video.isLive || sec < 45 || sec > 720) continue;

        final directUrl = await getDirectAudioStreamUrl(video.id.value);
        if (directUrl.isNotEmpty) {
          debugPrint('Resolved YouTube stream fallback for "$rawTitle": ${video.id.value}');
          return directUrl;
        }
      }
    } catch (e) {
      debugPrint('YtMusicService resolveFallbackAudio error: $e');
    }
    return '';
  }

  /// Close resources
  static void dispose() {
    _yt.close();
  }
}
