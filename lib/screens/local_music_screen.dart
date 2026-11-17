import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/song_model.dart';
import '../providers/audio_player_provider.dart';
import '../services/local_music_service.dart';

class LocalMusicScreen extends StatefulWidget {
  const LocalMusicScreen({super.key});

  @override
  State<LocalMusicScreen> createState() => _LocalMusicScreenState();
}

class _LocalMusicScreenState extends State<LocalMusicScreen> {
  bool _isLoading = true;
  List<Song> _allLocalSongs = [];
  Map<String, List<Song>> _artistsMap = {};
  Map<String, List<Song>> _albumsMap = {};
  Set<String> _favSongIds = {};

  String _selectedTab = 'All Songs'; // 'All Songs', 'Artists', 'Albums', 'Favorite Local'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String? _selectedArtistFolder;
  String? _selectedAlbumFolder;

  @override
  void initState() {
    super.initState();
    _scanFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanFiles() async {
    setState(() => _isLoading = true);
    final songs = await LocalMusicService.scanDeviceAudioFiles();
    final favs = await LocalMusicService.getFavoriteLocalSongIds();
    final artists = LocalMusicService.groupSongsByArtist(songs);
    final albums = LocalMusicService.groupSongsByAlbum(songs);

    if (mounted) {
      setState(() {
        _allLocalSongs = songs;
        _artistsMap = artists;
        _albumsMap = albums;
        _favSongIds = favs;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String songId) async {
    final isFav = await LocalMusicService.toggleFavoriteLocalSong(songId);
    setState(() {
      if (isFav) {
        _favSongIds.add(songId);
      } else {
        _favSongIds.remove(songId);
      }
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<AudioPlayerProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_selectedArtistFolder != null || _selectedAlbumFolder != null) {
              setState(() {
                _selectedArtistFolder = null;
                _selectedAlbumFolder = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedArtistFolder != null
                  ? _selectedArtistFolder!
                  : _selectedAlbumFolder != null
                      ? _selectedAlbumFolder!
                      : 'Local Music',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${_allLocalSongs.length} tracks on device',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Rescan Device Storage',
            onPressed: _scanFiles,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search local songs, artists, albums...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            // 4 Classification Filter Chips
            if (_selectedArtistFolder == null && _selectedAlbumFolder == null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildChip('All Songs', Icons.music_note),
                    const SizedBox(width: 8),
                    _buildChip('Artists', Icons.person),
                    const SizedBox(width: 8),
                    _buildChip('Albums', Icons.album),
                    const SizedBox(width: 8),
                    _buildChip('Favorite Local', Icons.favorite),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Main Body Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : _allLocalSongs.isEmpty
                      ? _buildEmptyState()
                      : _buildActiveTabContent(player),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
          _selectedArtistFolder = null;
          _selectedAlbumFolder = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.black : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(AudioPlayerProvider player) {
    if (_selectedArtistFolder != null) {
      final songs = _artistsMap[_selectedArtistFolder] ?? [];
      return _buildSongsListView(songs, player);
    }

    if (_selectedAlbumFolder != null) {
      final songs = _albumsMap[_selectedAlbumFolder] ?? [];
      return _buildSongsListView(songs, player);
    }

    switch (_selectedTab) {
      case 'Artists':
        return _buildArtistsView();
      case 'Albums':
        return _buildAlbumsView();
      case 'Favorite Local':
        final favSongs = _allLocalSongs.where((s) => _favSongIds.contains(s.id)).toList();
        if (favSongs.isEmpty) {
          return const Center(
            child: Text(
              'No favorite local tracks yet.\nTap the heart icon on any song to save it here!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          );
        }
        return _buildSongsListView(favSongs, player);
      case 'All Songs':
      default:
        return _buildSongsListView(_allLocalSongs, player);
    }
  }

  Widget _buildSongsListView(List<Song> sourceSongs, AudioPlayerProvider player) {
    final filtered = _searchQuery.isEmpty
        ? sourceSongs
        : sourceSongs.where((s) {
            return s.title.toLowerCase().contains(_searchQuery) ||
                s.artist.toLowerCase().contains(_searchQuery) ||
                s.album.toLowerCase().contains(_searchQuery);
          }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No matching local tracks found.', style: TextStyle(color: Colors.white54, fontSize: 14)),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final song = filtered[index];
        final isPlaying = player.currentSong?.id == song.id;
        final isFav = _favSongIds.contains(song.id);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPlaying ? Icons.equalizer : Icons.music_note,
              color: isPlaying ? AppColors.primary : Colors.white70,
              size: 24,
            ),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPlaying ? AppColors.primary : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            '${song.artist} • ${_formatDuration(song.duration)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.primary : Colors.white38,
              size: 20,
            ),
            onPressed: () => _toggleFavorite(song.id),
          ),
          onTap: () {
            player.playSong(song, contextPlaylist: filtered);
          },
        );
      },
    );
  }

  Widget _buildArtistsView() {
    final keys = _artistsMap.keys.where((a) {
      return _searchQuery.isEmpty || a.toLowerCase().contains(_searchQuery);
    }).toList();

    if (keys.isEmpty) {
      return const Center(
        child: Text('No matching local artists found.', style: TextStyle(color: Colors.white54, fontSize: 14)),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final artist = keys[index];
        final count = _artistsMap[artist]?.length ?? 0;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: AppColors.primary, size: 26),
          ),
          title: Text(
            artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            '$count songs',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
          onTap: () {
            setState(() => _selectedArtistFolder = artist);
          },
        );
      },
    );
  }

  Widget _buildAlbumsView() {
    final keys = _albumsMap.keys.where((alb) {
      return _searchQuery.isEmpty || alb.toLowerCase().contains(_searchQuery);
    }).toList();

    if (keys.isEmpty) {
      return const Center(
        child: Text('No matching local albums found.', style: TextStyle(color: Colors.white54, fontSize: 14)),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final album = keys[index];
        final count = _albumsMap[album]?.length ?? 0;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.folder, color: AppColors.primary, size: 26),
          ),
          title: Text(
            album,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            '$count songs in folder',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
          onTap: () {
            setState(() => _selectedAlbumFolder = album);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'No Local Audio Files Found',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add music files (.mp3, .m4a, .wav) to your device Music or Download folders, then tap Rescan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Rescan Storage', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _scanFiles,
            ),
          ],
        ),
      ),
    );
  }
}
