import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';
import '../models/artist_model.dart';

class YtMusicService {
  static final YoutubeExplode _yt = YoutubeExplode();
  static final Map<String, String> _streamCache = {};
  static final Map<String, String> _artistDpCache = {};

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
      final results = await _yt.search.search(searchQuery).timeout(const Duration(seconds: 6));
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
            genre: '',
            language: '',
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

  /// 2. GET DIRECT AUDIO STREAM URL IN BACKGROUND (Fastest AAC/m4a with ytClients)
  static Future<String> getDirectAudioStreamUrl(String rawVideoId) async {
    final videoId = rawVideoId.replaceFirst('yt_', '').trim();
    if (videoId.isEmpty) return '';

    if (_streamCache.containsKey(videoId)) {
      return _streamCache[videoId]!;
    }

    try {
      StreamManifest? manifest;

      // Try with multi-client bypass first for lightning-fast cipher extraction
      try {
        manifest = await _yt.videos.streamsClient.getManifest(
          videoId,
          ytClients: [
            YoutubeApiClient.ios,
            YoutubeApiClient.androidVr,
            YoutubeApiClient.safari,
          ],
        ).timeout(const Duration(seconds: 4));
      } catch (_) {
        // Fallback to standard client
        manifest = await _yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 4));
      }

      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) return '';

      // Prefer AAC/mp4 streams for instant native Android MediaPlayer playback
      final mp4Streams = audioStreams.where((s) => s.container.name.toLowerCase() == 'mp4' || s.codec.mimeType.contains('mp4')).toList();
      final selectedStream = mp4Streams.isNotEmpty
          ? mp4Streams.withHighestBitrate()
          : audioStreams.withHighestBitrate();

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

      final results = await _yt.search.search(query).timeout(const Duration(seconds: 5));
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

  /// 4. DYNAMIC ARTIST DP (Fetches real YouTube Channel Profile Picture)
  static Future<String> getArtistProfilePic(String artistName) async {
    final clean = artistName.trim();
    if (clean.isEmpty) return '';
    final cacheKey = clean.toLowerCase();
    if (_artistDpCache.containsKey(cacheKey)) {
      return _artistDpCache[cacheKey]!;
    }

    try {
      final results = await _yt.search.search('$clean official channel').timeout(const Duration(seconds: 5));
      for (final video in results) {
        if (video.channelId.value.isNotEmpty) {
          try {
            final channel = await _yt.channels.get(video.channelId).timeout(const Duration(seconds: 4));
            if (channel.logoUrl.isNotEmpty) {
              _artistDpCache[cacheKey] = channel.logoUrl;
              return channel.logoUrl;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error getting artist DP for $artistName: $e');
    }

    return 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400';
  }

  /// 5. DYNAMIC ARTIST SONGS (Full Discography)
  static Future<List<Song>> getArtistSongs(String artistName, {int limit = 25}) async {
    final clean = artistName.trim();
    if (clean.isEmpty) return [];
    try {
      final results = await _yt.search.search('$clean official audio').timeout(const Duration(seconds: 6));
      final List<Song> list = [];
      for (final video in results) {
        final sec = video.duration?.inSeconds ?? 0;
        if (video.isLive || sec < 45 || sec > 720) continue;
        final videoId = video.id.value;
        final thumb = video.thumbnails.highResUrl.isNotEmpty
            ? video.thumbnails.highResUrl
            : video.thumbnails.mediumResUrl;

        list.add(
          Song(
            id: 'yt_$videoId',
            title: cleanTitle(video.title),
            artist: video.author.replaceAll(' - Topic', '').trim(),
            album: '$clean Singles',
            duration: video.duration ?? const Duration(minutes: 3),
            coverUrl: thumb,
            audioUrl: '',
            genre: 'Popular',
            language: '',
          ),
        );
        if (list.length >= limit) break;
      }
      return list;
    } catch (e) {
      debugPrint('Error fetching artist songs from YT: $e');
      return [];
    }
  }

  /// 6. SEARCH ARTIST CHANNELS (For Search Screen Header)
  static Future<List<Artist>> searchArtists(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    try {
      final results = await _yt.search.search('$clean official audio').timeout(const Duration(seconds: 5));
      final Set<String> seenArtists = {};
      final List<Artist> artists = [];

      for (final video in results) {
        final rawAuthor = video.author.replaceAll(' - Topic', '').trim();
        if (rawAuthor.isEmpty || seenArtists.contains(rawAuthor.toLowerCase())) continue;
        seenArtists.add(rawAuthor.toLowerCase());

        String dp = video.thumbnails.highResUrl.isNotEmpty
            ? video.thumbnails.highResUrl
            : video.thumbnails.mediumResUrl;

        artists.add(
          Artist(
            id: 'yt_artist_${video.channelId.value}',
            name: rawAuthor,
            imageUrl: dp,
            bio: '$rawAuthor Official Music Channel on EXOTIC.',
            language: '',
            artistType: 'Artist Channel',
            genre: 'Music',
            isVerified: true,
          ),
        );

        if (artists.length >= 2) break;
      }
      return artists;
    } catch (e) {
      debugPrint('Error searching artists on YT: $e');
      return [];
    }
  }

  /// Close resources
  static void dispose() {
    _yt.close();
  }
}
