class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final String bannerUrl;
  final String bio;
  final String language;
  final String artistType; // Rapper, Playback Singer, DJ, Indie, etc.
  final String genre;
  final int monthlyListeners;
  final bool isVerified;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.bannerUrl = '',
    required this.bio,
    required this.language,
    this.artistType = 'Playback Singer',
    required this.genre,
    this.monthlyListeners = 1250000,
    this.isVerified = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'bannerUrl': bannerUrl,
        'bio': bio,
        'language': language,
        'artistType': artistType,
        'genre': genre,
        'monthlyListeners': monthlyListeners,
        'isVerified': isVerified,
      };

  factory Artist.fromJson(Map<String, dynamic> json) => Artist(
        id: json['id'] ?? '',
        name: json['name'] ?? 'Unknown Artist',
        imageUrl: json['imageUrl'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400',
        bannerUrl: json['bannerUrl'] ?? '',
        bio: json['bio'] ?? 'Exotic Premier Verified Artist.',
        language: json['language'] ?? 'Hindi',
        artistType: json['artistType'] ?? 'Playback Singer',
        genre: json['genre'] ?? 'Pop',
        monthlyListeners: json['monthlyListeners'] ?? 1250000,
        isVerified: json['isVerified'] ?? true,
      );
}
