import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/artist_model.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../models/album_model.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../providers/admin_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import 'admin_panel_screen.dart';
import 'artist_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All'; // 'All', 'Music', 'Podcasts'

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);

    final allAppSongs = adminProvider.allAppSongs;
    final playlists = adminProvider.playlistsCatalog;
    final artists = adminProvider.artistsCatalog;
    final albums = adminProvider.albumsCatalog;
    final sections = adminProvider.homeSectionsList;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Bar Header: Avatar A + Filter Chips (All, Music, Podcasts) + Secret Bell Icon (Screenshot 1)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Builder(
                      builder: (btnCtx) => GestureDetector(
                        onTap: () => Scaffold.of(btnCtx).openDrawer(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: adminProvider.themeAccentColor.withValues(alpha: 0.6), width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Filter Chips: All, Music, Podcasts
                    _buildFilterChip('All', adminProvider.themeAccentColor),
                    const SizedBox(width: 8),
                    _buildFilterChip('Music', adminProvider.themeAccentColor),
                    const SizedBox(width: 8),
                    _buildFilterChip('Podcasts', adminProvider.themeAccentColor),

                    const Spacer(),

                    // Secret 9-Click Admin Bell Trigger Icon
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                      onPressed: () {
                        final clicks = adminProvider.registerBellClick();
                        if (clicks >= 9) {
                          _showAdminAuthDialog(context, adminProvider);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Announcement Banner if configured by Admin
            if (adminProvider.announcementMessage.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00FF87).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign, color: Color(0xFF00FF87), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          adminProvider.announcementMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 6-Card Recent Quick Picks Grid (Screenshot 1 Top Grid)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.0,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildListDelegate([
                  _buildQuickTile(
                    title: 'Liked Songs',
                    imageUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=400',
                    onTap: () {
                      if (libraryProvider.likedSongs.isNotEmpty) {
                        playerProvider.playPlaylist(libraryProvider.likedSongs);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No liked songs yet!')));
                      }
                    },
                  ),
                  _buildQuickTile(
                    title: playlists.isNotEmpty ? playlists.first.title : 'Exotic Mix',
                    imageUrl: playlists.isNotEmpty ? playlists.first.coverUrl : 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400',
                    onTap: () {
                      if (playlists.isNotEmpty && playlists.first.songs.isNotEmpty) {
                        playerProvider.playPlaylist(playlists.first.songs);
                      }
                    },
                  ),
                ]),
              ),
            ),

            // Hero Featured Banner Carousel (Screenshot 1)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FF87), Color(0xFF00DFD8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                            child: Text(adminProvider.heroBanners.isNotEmpty ? adminProvider.heroBanners.first['title']! : 'FEATURED CAROUSEL', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          const SizedBox(height: 8),
                          Text(adminProvider.heroBanners.isNotEmpty ? adminProvider.heroBanners.first['subtitle']! : 'Tested in 2026', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
                          const SizedBox(height: 4),
                          const Text('Live Google Cloud Music Stream', style: TextStyle(color: Colors.black87, fontSize: 12)),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        adminProvider.heroBanners.isNotEmpty ? adminProvider.heroBanners.first['imageUrl']! : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.black26, width: 90, height: 90, child: const Icon(Icons.music_note, color: Colors.black)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dynamically Render Every Home Section One Below the Other (Managed via Admin Panel)
            ...sections.expand((sectionTitle) => [
              _buildSectionHeader(sectionTitle),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: sectionTitle.toLowerCase().contains('artist') ? 160 : 180,
                  child: _buildSectionContent(
                    sectionTitle: sectionTitle,
                    artists: artists,
                    allAppSongs: allAppSongs,
                    playlists: playlists,
                    albums: albums,
                    playerProvider: playerProvider,
                  ),
                ),
              ),
            ]),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent({
    required String sectionTitle,
    required List<Artist> artists,
    required List<Song> allAppSongs,
    required List<Playlist> playlists,
    required List<Album> albums,
    required AudioPlayerProvider playerProvider,
  }) {
    final lower = sectionTitle.toLowerCase();

    if (lower.contains('artist')) {
      // Artist Avatars Carousel
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ArtistProfileScreen(artist: artist)));
            },
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundImage: NetworkImage(artist.imageUrl),
                  ),
                  const SizedBox(height: 6),
                  Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const Text('Artist', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      );
    } else if (lower.contains('album') || lower.contains('single')) {
      // Album Cards Carousel
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final alb = albums[index];
          return GestureDetector(
            onTap: () {
              if (alb.songs.isNotEmpty) playerProvider.playPlaylist(alb.songs);
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(alb.coverUrl, width: 130, height: 120, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                  Text(alb.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(alb.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      );
    } else if (lower.contains('recommendation') || lower.contains('hit list') || lower.contains('playlist') || lower.contains('chart')) {
      // Playlist Cards Carousel
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final pl = playlists[index];
          return GestureDetector(
            onTap: () {
              if (pl.songs.isNotEmpty) playerProvider.playPlaylist(pl.songs);
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(pl.coverUrl, width: 130, height: 120, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                  Text(pl.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(pl.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // General Songs Carousel
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allAppSongs.length,
        itemBuilder: (context, index) {
          final song = allAppSongs[index];
          return GestureDetector(
            onTap: () => playerProvider.playSong(song, contextPlaylist: allAppSongs),
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(song.coverUrl, width: 130, height: 120, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                  Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildFilterChip(String label, Color themeAccent) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? themeAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.white30) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (themeAccent == const Color(0xFFFFFFFF) || themeAccent == const Color(0xE6FFFFFF) ? Colors.black : Colors.white) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTile({required String title, required String imageUrl, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
              child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }

  void _showAdminAuthDialog(BuildContext context, AdminProvider adminProvider) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Admin Password Verification', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter Admin Password',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black),
            onPressed: () {
              if (adminProvider.verifyAdminPassword(passCtrl.text.trim())) {
                Navigator.pop(dialogCtx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Admin Password!')));
              }
            },
            child: const Text('Unlock Panel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
