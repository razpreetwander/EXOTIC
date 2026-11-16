import 'song_model.dart';

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String genreTag;
  final List<Song> songs;
  final bool isFeaturedOnHome;

  Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    this.genreTag = 'Pop / Trending',
    required this.songs,
    this.isFeaturedOnHome = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'coverUrl': coverUrl,
        'genreTag': genreTag,
        'songs': songs.map((s) => s.id).toList(),
        'isFeaturedOnHome': isFeaturedOnHome,
      };
}
