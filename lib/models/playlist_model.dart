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

  factory Playlist.fromSaavnJson(Map<String, dynamic> json) {
    final List images = json['image'] as List? ?? [];
    final String cover = images.isNotEmpty ? (images.last['url'] ?? '') : '';
    return Playlist(
      id: json['id']?.toString() ?? '',
      title: Song.clean(json['name'] ?? json['title']),
      description: Song.clean(json['description'] ?? 'JioSaavn Official Playlist • 320kbps Lossless'),
      coverUrl: cover.isNotEmpty ? cover : 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=600',
      genreTag: json['language']?.toString().toUpperCase() ?? 'TOP HITS',
      songs: [],
      isFeaturedOnHome: true,
    );
  }
}
