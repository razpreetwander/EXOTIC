import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../services/saavn_api_service.dart';
import '../theme/app_colors.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylistSongs();
  }

  Future<void> _loadPlaylistSongs() async {
    if (widget.playlist.songs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _songs = widget.playlist.songs;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      var fetched = await SaavnApiService.getPlaylistSongs(widget.playlist.id);
      if (fetched.isEmpty) {
        final albumData = await SaavnApiService.getAlbumDetails(widget.playlist.id);
        if (albumData != null && albumData['songs'] != null) {
          fetched = List<Song>.from(albumData['songs']);
        }
      }
      if (mounted) {
        setState(() {
          _songs = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading playlist songs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with Artwork & Title
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.playlist.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.playlist.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF282828),
                      child: const Icon(Icons.music_note, color: AppColors.primary, size: 64),
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
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.playlist.genreTag,
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.playlist.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_songs.length} Songs',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Play All & Shuffle Buttons Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.play_arrow, color: Colors.black, size: 24),
                    label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: _songs.isNotEmpty
                        ? () => player.playPlaylist(_songs)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: AppColors.primary, size: 26),
                    onPressed: _songs.isNotEmpty
                        ? () {
                            if (!player.isShuffle) player.toggleShuffle();
                            player.playPlaylist(_songs);
                          }
                        : null,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 22),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sharing "${widget.playlist.title}" link...')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Track List
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_songs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No tracks available in this playlist', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = _songs[index];
                    final isPlayingThis = player.currentSong?.id == song.id;
                    final isLiked = library.isLiked(song.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
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
                              width: 24,
                              child: Text(
                                '${index + 1}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isPlayingThis ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: isPlayingThis ? FontWeight.bold : FontWeight.normal,
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
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? AppColors.primary : AppColors.textSecondary,
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
                        onTap: () => player.playSong(song, contextPlaylist: _songs),
                      ),
                    );
                  },
                  childCount: _songs.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
