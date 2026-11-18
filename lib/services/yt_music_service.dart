import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';
import '../models/artist_model.dart';
import 'saavn_api_service.dart';

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

  /// 2. CACHE YOUTUBE AUDIO LOCALLY (100% immune to Android 403 Forbidden)
  static Future<String> downloadAudioToCache(String rawVideoId) async {
    final videoId = rawVideoId.replaceFirst('yt_', '').trim();
    if (videoId.isEmpty) return '';

    try {
      final tempDir = Directory.systemTemp;
      final targetFile = File('${tempDir.path}/exotic_yt_$videoId.m4a');
      if (await targetFile.exists() && (await targetFile.length()) > 50000) {
        return targetFile.path;
      }

      StreamManifest manifest;
      try {
        manifest = await _yt.videos.streamsClient.getManifest(
          videoId,
          ytClients: [
            YoutubeApiClient.androidVr,
            YoutubeApiClient.ios,
          ],
        ).timeout(const Duration(seconds: 4));
      } catch (_) {
        manifest = await _yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 4));
      }

      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) return '';

      // Pick AAC/mp4 audio stream sorted by bitrate for fastest piping (<1s)
      final mp4Streams = audioStreams.where((s) => s.container.name.toLowerCase() == 'mp4' || s.codec.mimeType.contains('mp4')).toList();
      final streamInfo = mp4Streams.isNotEmpty ? mp4Streams.sortByBitrate().first : audioStreams.sortByBitrate().first;

      final stream = _yt.videos.streamsClient.get(streamInfo);
      final sink = targetFile.openWrite();
      await stream.pipe(sink);
      await sink.flush();
      await sink.close();

      if (await targetFile.exists() && (await targetFile.length()) > 10000) {
        return targetFile.path;
      }
    } catch (e) {
      debugPrint('Error caching YouTube audio ($rawVideoId): $e');
    }
    return '';
  }

  /// 3. PIPED PROXY AUDIO STREAM (Zero 403, plays directly via HTTP)
  static Future<String> getPipedAudioStreamUrl(String rawVideoId) async {
    final videoId = rawVideoId.replaceFirst('yt_', '').trim();
    if (videoId.isEmpty) return '';

    final instances = [
      'https://pipedapi.kavin.rocks',
      'https://api.piped.private.coffee',
      'https://pipedapi.tokhmi.xyz',
    ];

    for (final base in instances) {
      try {
        final res = await http.get(Uri.parse('$base/streams/$videoId')).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final streams = data['audioStreams'] as List? ?? [];
          for (final s in streams) {
            final url = s['url']?.toString() ?? '';
            if (url.isNotEmpty && url.startsWith('http')) {
              return url;
            }
          }
        }
      } catch (_) {}
    }
    return '';
  }

  static HttpServer? _proxyServer;
  static int? _proxyPort;

  /// Starts a local in-app loopback HTTP proxy server to stream YouTube audio directly to ExoPlayer without 403 Forbidden
  static Future<int> _ensureProxyServerStarted() async {
    if (_proxyServer != null && _proxyPort != null) return _proxyPort!;
    try {
      _proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _proxyPort = _proxyServer!.port;
      debugPrint('Local YouTube Audio Proxy Server started on 127.0.0.1:$_proxyPort');

      _proxyServer!.listen((HttpRequest request) async {
        try {
          final videoId = request.uri.queryParameters['v'] ?? '';
          if (videoId.isEmpty) {
            request.response.statusCode = HttpStatus.badRequest;
            await request.response.close();
            return;
          }

          final tempDir = Directory.systemTemp;
          final cachedFile = File('${tempDir.path}/exotic_yt_$videoId.m4a');

          // If fully cached on disk, stream directly from disk
          if (await cachedFile.exists() && (await cachedFile.length()) > 40000) {
            request.response.headers.contentType = ContentType('audio', 'mp4');
            request.response.headers.set('Accept-Ranges', 'bytes');
            await request.response.addStream(cachedFile.openRead());
            await request.response.close();
            return;
          }

          StreamManifest manifest;
          try {
            manifest = await _yt.videos.streamsClient.getManifest(
              videoId,
              ytClients: [
                YoutubeApiClient.ios,
                YoutubeApiClient.androidVr,
              ],
            ).timeout(const Duration(seconds: 5));
          } catch (_) {
            manifest = await _yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 5));
          }

          final audioStreams = manifest.audioOnly;
          if (audioStreams.isEmpty) {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
            return;
          }

          final mp4Streams = audioStreams.where((s) => s.container.name.toLowerCase() == 'mp4' || s.codec.mimeType.contains('mp4')).toList();
          final streamInfo = mp4Streams.isNotEmpty ? mp4Streams.sortByBitrate().first : audioStreams.sortByBitrate().first;

          request.response.headers.contentType = ContentType('audio', 'mp4');
          request.response.headers.set('Accept-Ranges', 'bytes');
          if (streamInfo.size.totalBytes > 0) {
            request.response.headers.contentLength = streamInfo.size.totalBytes;
          }

          final audioStream = _yt.videos.streamsClient.get(streamInfo);
          final cacheSink = cachedFile.openWrite();

          await for (final chunk in audioStream) {
            request.response.add(chunk);
            cacheSink.add(chunk);
          }

          await request.response.close();
          await cacheSink.flush();
          await cacheSink.close();
        } catch (e) {
          debugPrint('Proxy stream error ($e)');
          try {
            await request.response.close();
          } catch (_) {}
        }
      });

      return _proxyPort!;
    } catch (e) {
      debugPrint('Error starting local proxy server: $e');
      return 0;
    }
  }

  /// 3B. VISIONOS DIRECT AUDIO STREAM (Bypasses PoToken & 403, returns direct playable HTTP 206 URL)
  static Future<String> getVisionOSAudioStreamUrl(String rawVideoId) async {
    final videoId = rawVideoId.replaceFirst('yt_', '').trim();
    if (videoId.isEmpty) return '';

    if (_streamCache.containsKey(videoId)) {
      return _streamCache[videoId]!;
    }

    try {
      final payload = {
        'context': {
          'client': {
            'clientName': 'VISIONOS',
            'clientVersion': '1.02',
            'deviceMake': 'Apple',
            'deviceModel': 'RealityDevice17,1',
            'userAgent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
            'osName': 'visionOS',
            'osVersion': '26.5.23O471',
            'hl': 'en',
            'timeZone': 'UTC',
            'utcOffsetMinutes': 0,
          }
        },
        'videoId': videoId,
      };

      final response = await http.post(
        Uri.parse('https://www.youtube.com/youtubei/v1/player?prettyPrint=false'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streamingData = data['streamingData'] as Map<String, dynamic>?;
        if (streamingData != null) {
          final formats = streamingData['adaptiveFormats'] as List? ?? [];
          final audioFormats = formats.where((f) {
            final mime = f['mimeType']?.toString().toLowerCase() ?? '';
            return mime.startsWith('audio/') && f['url'] != null && f['url'].toString().startsWith('http');
          }).toList();

          if (audioFormats.isNotEmpty) {
            audioFormats.sort((a, b) => ((b['bitrate'] as int?) ?? 0).compareTo((a['bitrate'] as int?) ?? 0));
            final selectedUrl = audioFormats.first['url'].toString();
            _streamCache[videoId] = selectedUrl;
            debugPrint('Resolved YouTube visionOS audio stream: $videoId');
            return selectedUrl;
          }
        }
      }
    } catch (e) {
      debugPrint('visionOS audio stream error ($videoId): $e');
    }
    return '';
  }

  /// 4. MULTI-LAYER AUDIO RESOLUTION (JioSaavn 320kbps CDN -> visionOS Direct Stream -> Local Cache -> Fast Download)
  static Future<String> resolvePlayableAudio(String rawVideoId, {String? title, String? artist}) async {
    final videoId = rawVideoId.replaceFirst('yt_', '').trim();
    if (videoId.isEmpty) return '';

    // Step A: Instant JioSaavn 320kbps CDN Match if song title/artist available
    if (title != null && title.trim().isNotEmpty) {
      String cleanT = cleanTitle(title);
      String cleanA = (artist ?? '').replaceAll(' - Topic', '').trim();

      if (cleanT.contains(' - ')) {
        final parts = cleanT.split(' - ');
        if (parts.length >= 2) {
          cleanA = parts[0].trim();
          cleanT = parts.sublist(1).join(' - ').trim();
        }
      }

      try {
        final matches = await SaavnApiService.searchSongs('$cleanT $cleanA', limit: 2);
        if (matches.isNotEmpty && matches.first.audioUrl.isNotEmpty && matches.first.audioUrl.startsWith('http')) {
          debugPrint('Fast recovered YouTube track with JioSaavn 320kbps CDN: $cleanT');
          return matches.first.audioUrl;
        }
      } catch (_) {}
    }

    // Step B: Direct Instant visionOS Stream URL (Bypasses PoToken & 403 Forbidden, instant <0.5s playback)
    try {
      final visionUrl = await getVisionOSAudioStreamUrl(videoId);
      if (visionUrl.isNotEmpty && visionUrl.startsWith('http')) {
        debugPrint('Serving YouTube track via visionOS Direct Stream: $videoId');
        return visionUrl;
      }
    } catch (e) {
      debugPrint('visionOS resolution error: $e');
    }

    // Step C: Direct Local File Cache if already downloaded
    try {
      final tempDir = Directory.systemTemp;
      final cachedFile = File('${tempDir.path}/exotic_yt_$videoId.m4a');
      if (await cachedFile.exists() && (await cachedFile.length()) > 30000) {
        debugPrint('Serving YouTube track from local cache: ${cachedFile.path}');
        return cachedFile.path;
      }
    } catch (_) {}

    // Step D: Fast direct buffer download to local file fallback
    try {
      final cachedPath = await downloadAudioToCache(videoId);
      if (cachedPath.isNotEmpty && File(cachedPath).existsSync()) {
        debugPrint('Serving YouTube track via newly cached local file: $cachedPath');
        return cachedPath;
      }
    } catch (e) {
      debugPrint('Error in downloadAudioToCache: $e');
    }

    // Step E: Direct Stream Manifest URL fallback
    final direct = await getDirectAudioStreamUrl(videoId);
    if (direct.isNotEmpty) return direct;

    return '';
  }

  /// 5. GET DIRECT AUDIO STREAM URL (Fallback)
  static Future<String> getDirectAudioStreamUrl(String rawVideoId) async {
    final videoId = rawVideoId.replaceFirst('yt_', '').trim();
    if (videoId.isEmpty) return '';

    if (_streamCache.containsKey(videoId)) {
      return _streamCache[videoId]!;
    }

    try {
      StreamManifest? manifest;

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
        manifest = await _yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 4));
      }

      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) return '';

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

  /// 6. AUTOMATIC BACKGROUND FALLBACK FOR ANY MISSING OR FAILED SONG
  static Future<String> resolveFallbackAudio(String rawTitle, String rawArtist) async {
    try {
      final cleanT = rawTitle
          .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .trim();
      final cleanA = rawArtist.split(',').first.trim();
      final query = '$cleanT $cleanA';

      // 1. Try instant JioSaavn match
      final saavnMatches = await SaavnApiService.searchSongs(query, limit: 2);
      if (saavnMatches.isNotEmpty && saavnMatches.first.audioUrl.isNotEmpty && saavnMatches.first.audioUrl.startsWith('http')) {
        return saavnMatches.first.audioUrl;
      }

      // 2. Search on YouTube
      final results = await _yt.search.search('$query official audio').timeout(const Duration(seconds: 5));
      for (final video in results) {
        final sec = video.duration?.inSeconds ?? 0;
        if (video.isLive || sec < 45 || sec > 720) continue;

        final directUrl = await resolvePlayableAudio(video.id.value, title: rawTitle, artist: rawArtist);
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

  /// 4. DYNAMIC ARTIST DP (Fetches real 500x500 Portrait or Official Channel Logo - ZERO unsplash)
  static Future<String> getArtistProfilePic(String artistName) async {
    final clean = artistName.trim();
    if (clean.isEmpty) return '';
    final cacheKey = clean.toLowerCase();
    if (_artistDpCache.containsKey(cacheKey)) {
      return _artistDpCache[cacheKey]!;
    }

    // Step 1: Official JioSaavn 500x500 Studio Portrait Photo (High Definition)
    try {
      final saavnPic = await SaavnApiService.getArtistProfilePic(clean);
      if (saavnPic.isNotEmpty) {
        _artistDpCache[cacheKey] = saavnPic;
        return saavnPic;
      }
    } catch (_) {}

    // Step 2: Official YouTube Channel Logo (Circular Avatar)
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

    return '';
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

  /// 7. SEARCH ARTIST CHANNELS (Real Photos from JioSaavn & YouTube Channel Avatars)
  static Future<List<Artist>> searchArtists(String query, {int limit = 6}) async {
    String clean = query.trim();
    if (clean.isEmpty) return [];
    if (clean.toLowerCase() == 'international') {
      clean = 'English Pop';
    }

    // Step 1: Search via JioSaavn for verified artist portraits
    try {
      final saavnArtists = await SaavnApiService.searchArtists(clean, limit: limit);
      if (saavnArtists.isNotEmpty) {
        return saavnArtists;
      }
    } catch (_) {}

    // Step 2: Search via YouTube channel logo (NOT video thumbnails)
    try {
      final results = await _yt.search.search('$clean official channel').timeout(const Duration(seconds: 5));
      final Set<String> seenArtists = {};
      final List<Artist> artists = [];

      for (final video in results) {
        final rawAuthor = video.author.replaceAll(' - Topic', '').trim();
        if (rawAuthor.isEmpty || seenArtists.contains(rawAuthor.toLowerCase())) continue;
        seenArtists.add(rawAuthor.toLowerCase());

        final dp = await getArtistProfilePic(rawAuthor);

        artists.add(
          Artist(
            id: 'yt_artist_${video.channelId.value.isNotEmpty ? video.channelId.value : rawAuthor.toLowerCase().replaceAll(' ', '_')}',
            name: rawAuthor,
            imageUrl: dp,
            bio: '$rawAuthor Official Music Channel on EXOTIC.',
            language: '',
            artistType: 'Artist Channel',
            genre: 'Music',
            isVerified: true,
          ),
        );

        if (artists.length >= limit) break;
      }
      return artists;
    } catch (e) {
      debugPrint('Error searching artists on YT: $e');
      return [];
    }
  }

  /// Close resources
  static void dispose() {
    _proxyServer?.close(force: true);
    _yt.close();
  }
}
