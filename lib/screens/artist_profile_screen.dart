import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/artist_model.dart';
import '../providers/admin_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../theme/app_colors.dart';

class ArtistProfileScreen extends StatefulWidget {
  final Artist artist;

  const ArtistProfileScreen({super.key, required this.artist});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final artist = widget.artist;

    final artistSongs = adminProvider.allAppSongs
        .where((s) => s.artist.toLowerCase().contains(artist.name.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Flexible Header with Artist Picture Banner
          SliverAppBar(
            expandedHeight: 260,
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
                          '${(artist.monthlyListeners / 1000000).toStringAsFixed(1)}M Monthly Listeners',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Play All Floating Action Row
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
                    onPressed: () {
                      if (artistSongs.isNotEmpty) {
                        playerProvider.playPlaylist(artistSongs);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _isFollowing ? AppColors.primary : Colors.white30),
                      foregroundColor: _isFollowing ? AppColors.primary : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () {
                      setState(() {
                        _isFollowing = !_isFollowing;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_isFollowing ? 'Now following ${artist.name}!' : 'Unfollowed ${artist.name}')),
                      );
                    },
                    child: Text(_isFollowing ? 'Following ✅' : 'Follow'),
                  ),
                ],
              ),
            ),
          ),

          // Artist Bio Card
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

          // Artist Albums & EPs Section
          if (adminProvider.albumsCatalog.any((a) => a.artist.toLowerCase().contains(artist.name.toLowerCase()))) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Discography & Albums', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: adminProvider.albumsCatalog.where((a) => a.artist.toLowerCase().contains(artist.name.toLowerCase())).length,
                  itemBuilder: (context, idx) {
                    final album = adminProvider.albumsCatalog.where((a) => a.artist.toLowerCase().contains(artist.name.toLowerCase())).toList()[idx];
                    return GestureDetector(
                      onTap: () {
                        if (album.songs.isNotEmpty) {
                          playerProvider.playPlaylist(album.songs);
                        }
                      },
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(album.coverUrl, width: 120, height: 110, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 6),
                            Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Popular Songs Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Popular Tracks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),

          // Artist Songs List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = artistSongs[index];
                return ListTile(
                  leading: Text('${index + 1}', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                  title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(song.album, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  trailing: IconButton(
                    icon: Icon(
                      song.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: song.isLiked ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => libraryProvider.toggleLikeSong(song),
                  ),
                  onTap: () {
                    playerProvider.playSong(song, contextPlaylist: artistSongs);
                  },
                );
              },
              childCount: artistSongs.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
