import 'song_model.dart';

class Album {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String releaseYear;
  final List<Song> songs;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    this.releaseYear = '2026',
    required this.songs,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'coverUrl': coverUrl,
        'releaseYear': releaseYear,
        'songs': songs.map((s) => s.id).toList(),
      };
}
