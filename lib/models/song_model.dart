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
  });

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
    );
  }
}

class LyricLine {
  final Duration timestamp;
  final String text;

  LyricLine({required this.timestamp, required this.text});
}

