import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/artist_model.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../services/saavn_api_service.dart';
import '../theme/app_colors.dart';
import 'playlist_detail_screen.dart';

class ArtistProfileScreen extends StatefulWidget {
  final Artist artist;

  const ArtistProfileScreen({super.key, required this.artist});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  bool _isFollowing = false;
  List<Song> _artistSongs = [];
  List<dynamic> _topAlbums = [];
  List<Song> _singles = [];
  List<dynamic> _similarArtists = [];
  String _imageUrl = '';
  String _bio = '';
  int _followerCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.artist.imageUrl;
    _bio = widget.artist.bio;
    _followerCount = widget.artist.monthlyListeners;
    _loadFollowStatus();
    _fetchFullArtistProfile();
  }

  Future<void> _loadFollowStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final followed = prefs.getStringList('followed_artists') ?? [];
    if (mounted) {
      setState(() {
        _isFollowing = followed.contains(widget.artist.name);
      });
    }
  }

  Future<void> _toggleFollow() async {
    final prefs = await SharedPreferences.getInstance();
    final followed = prefs.getStringList('followed_artists') ?? [];
    setState(() {
      _isFollowing = !_isFollowing;
    });

    if (_isFollowing) {
      if (!followed.contains(widget.artist.name)) followed.add(widget.artist.name);
    } else {
      followed.remove(widget.artist.name);
    }
    await prefs.setStringList('followed_artists', followed);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFollowing ? 'Now following ${widget.artist.name}!' : 'Unfollowed ${widget.artist.name}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _fetchFullArtistProfile() async {
    try {
      String? artistId;
      // 1. If artist.id is numeric, use it directly
      if (int.tryParse(widget.artist.id) != null) {
        artistId = widget.artist.id;
      } else {
        // 2. Search artist ID by name
        artistId = await SaavnApiService.getArtistIdByName(widget.artist.name);
      }

      if (artistId != null && artistId.isNotEmpty) {
        final details = await SaavnApiService.getArtistDetails(artistId);
        if (details != null && mounted) {
          setState(() {
            if (details['topSongs'] != null && (details['topSongs'] as List).isNotEmpty) {
              _artistSongs = List<Song>.from(details['topSongs']);
            }
            _topAlbums = List<dynamic>.from(details['topAlbums'] ?? []);
            _singles = List<Song>.from(details['singles'] ?? []);
            _similarArtists = List<dynamic>.from(details['similarArtists'] ?? []);
            if ((details['imageUrl'] as String?)?.isNotEmpty == true) {
              _imageUrl = details['imageUrl'];
            }
            if (details['followerCount'] != null && (details['followerCount'] as num) > 0) {
              _followerCount = (details['followerCount'] as num).toInt();
            }
            if ((details['bio'] as String?)?.isNotEmpty == true) {
              _bio = details['bio'];
            }
            _isLoading = false;
          });
          return;
        }
      }

      // Fallback: search songs directly by artist name
      final songs = await SaavnApiService.searchSongs(widget.artist.name, limit: 30);
      if (mounted) {
        setState(() {
          _artistSongs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching artist details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<AudioPlayerProvider>(context);
    final library = Provider.of<MusicLibraryProvider>(context);
    final artist = widget.artist;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Flexible Header with Artist Picture Banner
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                artist.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black87, blurRadius: 10),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _imageUrl.isNotEmpty ? _imageUrl : artist.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF282828),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 80),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black45,
                          Colors.black87,
                          AppColors.background,
                        ],
                        stops: [0.0, 0.5, 0.8, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 46,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, color: AppColors.primary, size: 18),
                            const SizedBox(width: 5),
                            const Text(
                              'Verified Artist',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                artist.language.toUpperCase(),
                                style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatNumber(_followerCount)} Monthly Listeners',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Play All, Shuffle & Follow Action Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // Play Artist Radio Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 24, color: Colors.black),
                    label: const Text(
                      'Play Artist Radio',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: _artistSongs.isNotEmpty
                        ? () => player.playPlaylist(_artistSongs)
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // Shuffle Button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.shuffle, color: AppColors.primary, size: 22),
                      onPressed: () {
                        if (_artistSongs.isNotEmpty) {
                          final shuffled = List<Song>.from(_artistSongs)..shuffle();
                          player.playPlaylist(shuffled);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Follow / Following Button
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isFollowing ? AppColors.primary : Colors.white38,
                        width: 1.2,
                      ),
                      foregroundColor: _isFollowing ? AppColors.primary : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: _toggleFollow,
                    child: Text(
                      _isFollowing ? 'Following ✓' : 'Follow',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Popular Tracks Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Tracks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  if (_artistSongs.isNotEmpty)
                    Text(
                      '${_artistSongs.length} songs',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),

          // 4. Real Artist Songs List (Top Songs)
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_artistSongs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No tracks available for this artist', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _artistSongs[index];
                  final isPlayingThis = player.currentSong?.id == song.id;
                  final isLiked = library.isLiked(song.id);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPlayingThis ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${index + 1}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isPlayingThis ? AppColors.primary : AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              song.coverUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                color: const Color(0xFF282828),
                                child: const Icon(Icons.music_note, color: Colors.white54, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPlayingThis ? AppColors.primary : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        song.album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? AppColors.primary : AppColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () => library.toggleLike(song),
                          ),
                          Text(
                            _formatDuration(song.duration),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      onTap: () => player.playSong(song, contextPlaylist: _artistSongs),
                    ),
                  );
                },
                childCount: _artistSongs.length,
              ),
            ),

          // 5. Discography & Top Albums Carousel
          if (_topAlbums.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 26, 16, 12),
                child: Text(
                  'Albums & Discography',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 195,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _topAlbums.length,
                  itemBuilder: (context, idx) {
                    final album = _topAlbums[idx];
                    final String title = album['name'] ?? 'Album';
                    final String year = album['year']?.toString() ?? '';
                    final List images = album['image'] as List? ?? [];
                    final String cover = images.isNotEmpty ? images.last['url'] : '';

                    return GestureDetector(
                      onTap: () {
                        final albumPlaylist = Playlist(
                          id: album['id']?.toString() ?? '',
                          title: title,
                          description: 'Album by ${artist.name} ($year)',
                          coverUrl: cover,
                          genreTag: 'ALBUM',
                          songs: [],
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(playlist: albumPlaylist),
                          ),
                        );
                      },
                      child: Container(
                        width: 135,
                        margin: const EdgeInsets.only(right: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                cover,
                                width: 135,
                                height: 135,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 135,
                                  height: 135,
                                  color: const Color(0xFF242424),
                                  child: const Icon(Icons.album, color: Colors.white30, size: 40),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              year.isNotEmpty ? '$year • Album' : 'Album',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // 6. Singles & EPs Carousel
          if (_singles.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 26, 16, 12),
                child: Text(
                  'Singles & Releases',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 195,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _singles.length,
                  itemBuilder: (context, idx) {
                    final single = _singles[idx];
                    return GestureDetector(
                      onTap: () => player.playSong(single, contextPlaylist: _singles),
                      child: Container(
                        width: 135,
                        margin: const EdgeInsets.only(right: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                single.coverUrl,
                                width: 135,
                                height: 135,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 135,
                                  height: 135,
                                  color: const Color(0xFF242424),
                                  child: const Icon(Icons.music_note, color: Colors.white30, size: 40),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              single.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Single',
                              style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // 7. Fans Also Like (Similar Artists)
          if (_similarArtists.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 26, 16, 12),
                child: Text(
                  'Fans Also Like',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _similarArtists.length,
                  itemBuilder: (context, idx) {
                    final item = _similarArtists[idx];
                    final String name = item['name'] ?? 'Artist';
                    final List images = item['image'] as List? ?? [];
                    final String imgUrl = images.isNotEmpty ? images.last['url'] : '';

                    return GestureDetector(
                      onTap: () {
                        final nextArtist = Artist(
                          id: item['id']?.toString() ?? '',
                          name: name,
                          imageUrl: imgUrl,
                          bio: 'Exotic Premier Verified Artist.',
                          language: artist.language,
                          genre: artist.genre,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtistProfileScreen(artist: nextArtist),
                          ),
                        );
                      },
                      child: Container(
                        width: 95,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF282828),
                              backgroundImage: imgUrl.isNotEmpty ? NetworkImage(imgUrl) : null,
                              child: imgUrl.isEmpty
                                  ? const Icon(Icons.person, color: AppColors.primary, size: 36)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('Artist', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // 8. About the Artist Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 26, 16, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'About the Artist',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Verified', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _bio.isNotEmpty ? _bio : '${artist.name} is one of the premier verified trending music creators on Exotic Music.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatNumber(_followerCount),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          const Text('Monthly Listeners', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Verified',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          Text('Artist Status', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
