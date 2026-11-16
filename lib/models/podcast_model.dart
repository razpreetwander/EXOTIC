import 'song_model.dart';

class Podcast {
  final String id;
  final String title;
  final String publisher;
  final String description;
  final String coverUrl;
  final String category;
  final List<Song> episodes;

  Podcast({
    required this.id,
    required this.title,
    required this.publisher,
    required this.description,
    required this.coverUrl,
    this.category = 'Podcasts',
    required this.episodes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'publisher': publisher,
      'description': description,
      'coverUrl': coverUrl,
      'category': category,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }

  factory Podcast.fromJson(Map<String, dynamic> json) {
    var epList = json['episodes'] as List? ?? [];
    List<Song> loadedEp = epList.map((e) => Song.fromJson(e)).toList();
    return Podcast(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Podcast',
      publisher: json['publisher'] ?? 'Exotic Host',
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'] ?? 'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?q=80&w=400',
      category: json['category'] ?? 'Podcasts',
      episodes: loadedEp,
    );
  }
}
