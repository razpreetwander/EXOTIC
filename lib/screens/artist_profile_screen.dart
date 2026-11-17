import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/artist_model.dart';
import '../models/song_model.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../services/saavn_api_service.dart';
import '../theme/app_colors.dart';

class ArtistProfileScreen extends StatefulWidget {
  final Artist artist;

  const ArtistProfileScreen({super.key, required this.artist});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  bool _isFollowing = false;
  List<Song> _artistSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
    _fetchRealArtistSongs();
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

  Future<void> _fetchRealArtistSongs() async {
    try {
      final songs = await SaavnApiService.searchSongs(widget.artist.name, limit: 30);
      if (mounted) {
        setState(() {
          _artistSongs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching artist tracks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
          // Flexible Header with Artist Picture Banner
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                artist.name,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    artist.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF282828),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 64),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87, AppColors.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 44,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, color: AppColors.primary, size: 18),
                            const SizedBox(width: 4),
                            const Text('Verified Artist', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                              child: Text(artist.language, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(artist.monthlyListeners / 1000000).toStringAsFixed(1)}M Monthly Listeners • 320k Lossless',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Play All & Follow Action Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text('Play Artist Radio', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _artistSongs.isNotEmpty
                        ? () => player.playPlaylist(_artistSongs)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _isFollowing ? AppColors.primary : Colors.white30),
                      foregroundColor: _isFollowing ? AppColors.primary : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: _toggleFollow,
                    child: Text(_isFollowing ? 'Following ✅' : 'Follow'),
                  ),
                ],
              ),
            ),
          ),

          // Artist Bio Card
          if (artist.bio.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('About the Artist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(
                      artist.bio,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

          // Popular Songs Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Top Tracks & Discography',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

          // Real Artist Songs List
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                fontWeight: isPlayingThis ? FontWeight.bold : FontWeight.bold,
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
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text('320k', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              song.album,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ),
                        ],
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

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
