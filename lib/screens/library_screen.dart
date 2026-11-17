import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../providers/admin_provider.dart';
import '../theme/app_colors.dart';
import 'artist_profile_screen.dart';
import 'playlist_detail_screen.dart';
import '../models/playlist_model.dart';
import '../widgets/create_playlist_dialog.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const LibraryScreen({super.key, this.onOpenDrawer});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedFilter = 'All'; // 'All', 'Playlists', 'Artists'
  bool _isGridView = false;
  String _sortBy = 'Recents';

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);

    final likedSongs = libraryProvider.likedSongs;
    final artists = adminProvider.artistsCatalog;
    final playlists = adminProvider.playlistsCatalog;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Avatar + "Your Library" + Search + Plus (+)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        'A',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Your Library',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.textPrimary, size: 26),
                    onPressed: () => _showLibrarySearchDialog(context, libraryProvider),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 28),
                    onPressed: () => _showPlusMenuModal(context),
                  ),
                ],
              ),
            ),

            // Filter Chips: Playlists, Artists
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip('Playlists'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Artists'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Sort Bar: ⇅ Recents (left) + Grid View toggle icon ⊞ (right)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showSortOrderSheet(context),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_vert, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 6),
                        Text('$_sortBy', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: AppColors.textSecondary, size: 20),
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Vertical Content List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 1. Liked Songs Pinned Item (Matching Screenshot 2)
                  if (_selectedFilter == 'All' || _selectedFilter == 'Playlists')
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFE91E63)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 26),
                      ),
                      title: const Row(
                        children: [
                          Text('Liked Songs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.push_pin, color: AppColors.primary, size: 12),
                          const SizedBox(width: 4),
                          Text('Playlist • (${likedSongs.length} songs)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(
                              playlist: Playlist(
                                id: 'liked_songs',
                                title: 'Liked Songs',
                                description: 'Your personal collection of favorite tracks',
                                coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=600',
                                genreTag: 'FAVORITES',
                                songs: likedSongs,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // 2. User Created Custom Playlists
                  if (_selectedFilter == 'All' || _selectedFilter == 'Playlists')
                    ...libraryProvider.userPlaylists.map((userPl) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              userPl.coverUrl,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: AppColors.surface, child: const Icon(Icons.queue_music, color: AppColors.primary)),
                            ),
                          ),
                          title: Text(userPl.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text('Custom Playlist • (${userPl.songs.length} songs)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailScreen(playlist: userPl),
                              ),
                            );
                          },
                        )),

                  // 3. Featured Playlists Catalog
                  if (_selectedFilter == 'All' || _selectedFilter == 'Playlists')
                    ...playlists.map((playlist) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              playlist.coverUrl,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: AppColors.surface, child: const Icon(Icons.music_note, color: Colors.white)),
                            ),
                          ),
                          title: Text(playlist.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text('Playlist • (${playlist.songs.length} songs)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailScreen(playlist: playlist),
                              ),
                            );
                          },
                        )),

                  // 3. Artists List (Round Avatars matching Screenshot 2)
                  if (_selectedFilter == 'All' || _selectedFilter == 'Artists')
                    ...artists.map((artist) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 27,
                            backgroundImage: NetworkImage(artist.imageUrl),
                          ),
                          title: Text(artist.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: const Text('Artist', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ArtistProfileScreen(artist: artist)),
                            );
                          },
                        )),

                  const SizedBox(height: 16),

                  // 4. Bottom Action Tiles with WORKING ACTION CALLBACKS!
                  _buildBottomActionTile(Icons.add, 'Add artists', () => _showAddArtistsDialog(context, adminProvider)),
                  _buildBottomActionTile(Icons.add, 'Add podcasts', () => _showAddPodcastsDialog(context, adminProvider, playerProvider)),
                  _buildBottomActionTile(Icons.add, 'Add events and venues', () => _showAddEventsDialog(context)),
                  _buildBottomActionTile(Icons.move_to_inbox_outlined, 'Import your music', () {
                    showDialog(context: context, builder: (_) => const CreatePlaylistDialog());
                  }),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = isSelected ? 'All' : label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 24),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      onTap: onTap,
    );
  }

  void _showSortOrderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1F24),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort by', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Recents', style: TextStyle(color: Colors.white)),
              trailing: _sortBy == 'Recents' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _sortBy = 'Recents');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Recently Added', style: TextStyle(color: Colors.white)),
              trailing: _sortBy == 'Recently Added' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _sortBy = 'Recently Added');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Alphabetical (A-Z)', style: TextStyle(color: Colors.white)),
              trailing: _sortBy == 'Alphabetical' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _sortBy = 'Alphabetical');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLibrarySearchDialog(BuildContext context, MusicLibraryProvider lib) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Search in Library', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          onChanged: (val) => lib.setSearchQuery(val),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Filter playlists, artists, tracks...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  void _showAddArtistsDialog(BuildContext context, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Follow Premier Artists', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 250,
          child: ListView.builder(
            itemCount: admin.artistsCatalog.length,
            itemBuilder: (c, i) {
              final artist = admin.artistsCatalog[i];
              return ListTile(
                dense: true,
                leading: CircleAvatar(radius: 18, backgroundImage: NetworkImage(artist.imageUrl)),
                title: Text(artist.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Following ${artist.name}!')));
                  },
                  child: const Text('Follow', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showAddPodcastsDialog(BuildContext context, AdminProvider admin, AudioPlayerProvider player) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Podcasts & Shows Catalog', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: admin.podcastsCatalog.isEmpty
              ? const Center(child: Text('No podcasts published yet. Admin can add podcasts in Admin Panel!', style: TextStyle(color: Colors.white54, fontSize: 12)))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: admin.podcastsCatalog.length,
                  itemBuilder: (c, i) {
                    final pod = admin.podcastsCatalog[i];
                    return ListTile(
                      dense: true,
                      leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(pod.coverUrl, width: 36, height: 36, fit: BoxFit.cover)),
                      title: Text(pod.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${pod.publisher} • ${pod.episodes.length} episodes', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 28),
                        onPressed: () {
                          if (pod.episodes.isNotEmpty) {
                            player.playPlaylist(pod.episodes);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playing Podcast "${pod.title}" episodes!')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Podcast has no episode tracks yet!')));
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showAddEventsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Live Concerts & Events', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('No upcoming live tour dates near your location right now.', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  /// Plus (+) Button Modal Bottom Sheet (Exact match for Screenshot 3)
  void _showPlusMenuModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1F24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlusMenuItem(
              icon: Icons.music_note,
              title: 'Playlist',
              subtitle: 'Create a playlist with songs or episodes',
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => const CreatePlaylistDialog());
              },
            ),
            const SizedBox(height: 16),
            _buildPlusMenuItem(
              icon: Icons.groups_outlined,
              title: 'Collaborative playlist',
              subtitle: 'Create a playlist together with friends',
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => const CreatePlaylistDialog());
              },
            ),
            const SizedBox(height: 16),
            _buildPlusMenuItem(
              icon: Icons.bubble_chart_outlined,
              title: 'Blend',
              subtitle: 'Combine your friends\' tastes into a playlist',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Blend playlist invited successfully!')));
              },
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlusMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
