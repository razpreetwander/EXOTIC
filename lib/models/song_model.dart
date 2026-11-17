class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String audioUrl;
  final String coverUrl;
  final List<LyricLine> lyrics;
  final String genre;
  bool isLiked;
  final String year;
  final String language;
  final bool isIncomplete;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.audioUrl,
    required this.coverUrl,
    this.lyrics = const [],
    required this.genre,
    this.isLiked = false,
    this.year = '',
    this.language = '',
    this.isIncomplete = false,
  });

  static String clean(String? text) {
    if (text == null) return '';
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration.inMilliseconds,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'genre': genre,
      'isLiked': isLiked,
      'year': year,
      'language': language,
      'isIncomplete': isIncomplete,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      album: json['album'] ?? '',
      duration: Duration(milliseconds: json['durationMs'] ?? 0),
      audioUrl: json['audioUrl'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      genre: json['genre'] ?? 'Exotic',
      isLiked: json['isLiked'] ?? false,
      year: json['year'] ?? '',
      language: json['language'] ?? '',
      isIncomplete: json['isIncomplete'] ?? false,
    );
  }

  /// Factory: Full Song Object from JioSaavn API (/api/search/songs, /api/songs, /api/albums, /api/playlists)
  factory Song.fromSaavnJson(Map<String, dynamic> json) {
    final List images = json['image'] as List? ?? [];
    final String img500 = images.isNotEmpty ? (images.last['url'] ?? '') : '';
    final String img150 = images.length > 1
        ? (images[1]['url'] ?? '')
        : (images.isNotEmpty ? images.last['url'] ?? '' : '');
    final String cover = img500.isNotEmpty
        ? img500
        : (img150.isNotEmpty ? img150 : 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500');

    final List downloads = json['downloadUrl'] as List? ?? [];
    // Quality priority: 320kbps (last), then 160kbps, then 96kbps
    final String audio = downloads.isNotEmpty ? (downloads.last['url'] ?? '') : '';

    String artistText = 'Unknown Artist';
    if (json['artists'] != null && json['artists']['primary'] != null) {
      final List primary = json['artists']['primary'];
      if (primary.isNotEmpty) {
        artistText = primary.map((a) => a['name']).where((n) => n != null).join(', ');
      }
    } else if (json['primaryArtists'] != null) {
      artistText = json['primaryArtists'].toString();
    } else if (json['singers'] != null) {
      artistText = json['singers'].toString();
    } else if (json['artist'] != null) {
      artistText = json['artist'].toString();
    }

    String albumText = 'Single';
    if (json['album'] is Map) {
      albumText = json['album']['name'] ?? 'Single';
    } else if (json['album'] != null) {
      albumText = json['album'].toString();
    }

    int durationSec = 180;
    if (json['duration'] != null) {
      durationSec = (json['duration'] as num).toInt();
    }

    return Song(
      id: json['id'] ?? '',
      title: clean(json['name'] ?? json['title']),
      artist: clean(artistText),
      album: clean(albumText),
      duration: Duration(seconds: durationSec),
      audioUrl: audio,
      coverUrl: cover,
      genre: json['language'] ?? 'Music',
      isLiked: false,
      year: json['year']?.toString() ?? '',
      language: json['language'] ?? '',
      isIncomplete: audio.isEmpty,
    );
  }

  /// Factory: Lightweight Song Object from Global Search (/api/search)
  factory Song.fromSaavnGlobalJson(Map<String, dynamic> json) {
    final List images = json['image'] as List? ?? [];
    final String cover = images.isNotEmpty ? (images.last['url'] ?? '') : 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500';

    return Song(
      id: json['id'] ?? '',
      title: clean(json['title'] ?? json['name']),
      artist: clean(json['primaryArtists'] ?? json['singers'] ?? json['artist'] ?? 'Unknown Artist'),
      album: clean(json['album'] is Map ? json['album']['name'] : (json['album']?.toString() ?? 'Single')),
      duration: const Duration(minutes: 3, seconds: 30),
      audioUrl: '',
      coverUrl: cover,
      genre: json['language'] ?? 'Music',
      isLiked: false,
      year: json['year']?.toString() ?? '',
      language: json['language'] ?? '',
      isIncomplete: true,
    );
  }
}

class LyricLine {
  final Duration timestamp;
  final String text;

  LyricLine({required this.timestamp, required this.text});
}
