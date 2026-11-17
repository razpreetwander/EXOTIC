import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/artist_model.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../models/album_model.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../providers/admin_provider.dart';
import '../services/saavn_api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import 'artist_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All'; // 'All', 'Music', 'Podcasts', 'Audiobooks'
  String _musicSubFilter = 'All'; // 'All', 'Music', 'Following', 'Podcasts'
  bool _isLoadingTab = false;

  // Real-time JioSaavn Feeds
  List<Song> _saavnQuickPicks = [];
  List<Song> _saavnTrendingHits = [];
  List<Song> _saavnPunjabiHits = [];
  List<Song> _saavnBollywoodHits = [];
  bool _isFetchingSaavn = false;

  @override
  void initState() {
    super.initState();
    _fetchJioSaavnHomeFeed();
  }

  Future<void> _fetchJioSaavnHomeFeed() async {
    if (_isFetchingSaavn) return;
    setState(() => _isFetchingSaavn = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final preferredArtists = prefs.getStringList('user_preferred_artists') ?? ['Karan Aujla', 'Diljit Dosanjh', 'Arijit Singh'];
      final primaryArtist = preferredArtists.isNotEmpty ? preferredArtists.first : 'Karan Aujla';

      // 1. Fetch 8 Quick Picks based on user's primary artist
      final quickSongs = await SaavnApiService.searchSongs(primaryArtist, limit: 8);

      // 2. Fetch Trending 50 India
      final trending = await SaavnApiService.searchSongs('Trending Top 50 India', limit: 10);

      // 3. Fetch Punjabi Hits
      final punjabi = await SaavnApiService.searchSongs('Punjabi Top Hits', limit: 10);

      // 4. Fetch Bollywood Hits
      final bollywood = await SaavnApiService.searchSongs('Bollywood Romantic Hits', limit: 10);

      if (mounted) {
        setState(() {
          if (quickSongs.isNotEmpty) _saavnQuickPicks = quickSongs;
          if (trending.isNotEmpty) _saavnTrendingHits = trending;
          if (punjabi.isNotEmpty) _saavnPunjabiHits = punjabi;
          if (bollywood.isNotEmpty) _saavnBollywoodHits = bollywood;
          _isFetchingSaavn = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching JioSaavn home feed: $e');
      if (mounted) setState(() => _isFetchingSaavn = false);
    }
  }

  void _onFilterTap(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _isLoadingTab = true;
    });

    // Brief authentic Spotify loading spinner transition
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isLoadingTab = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);

    final allAppSongs = adminProvider.allAppSongs;
    final playlists = adminProvider.playlistsCatalog;
    final artists = adminProvider.artistsCatalog;
    final albums = adminProvider.albumsCatalog;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP HEADER (Avatar + Filter Chips) =================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  // Circular Profile Avatar with 'P' (Exact Spotify layout from video)
                  Builder(
                    builder: (btnCtx) => GestureDetector(
                      onTap: () => Scaffold.of(btnCtx).openDrawer(),
                      child: const CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          'P',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Horizontal Scrollable Filter Chips: All, Music, Podcasts, Audiobooks
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Music'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Podcasts'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Audiobooks'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= MAIN CONTENT BODY (With Tab Transitions) =================
            Expanded(
              child: _isLoadingTab
                  ? const Center(
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    )
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        if (_selectedFilter == 'All') ..._buildAllTabSlivers(playerProvider, libraryProvider, adminProvider, allAppSongs, playlists, artists, albums),
                        if (_selectedFilter == 'Music') ..._buildMusicTabSlivers(playerProvider, libraryProvider, allAppSongs),
                        if (_selectedFilter == 'Podcasts') ..._buildPodcastsTabSlivers(playerProvider),
                        if (_selectedFilter == 'Audiobooks') ..._buildAudiobooksTabSlivers(playerProvider),

                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 1. FILTER CHIPS
  // =========================================================================
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _onFilterTap(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFF282828),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. TAB 1: ALL CONTENT
  // =========================================================================
  List<Widget> _buildAllTabSlivers(
    AudioPlayerProvider player,
    MusicLibraryProvider library,
    AdminProvider admin,
    List<Song> songs,
    List<Playlist> playlists,
    List<Artist> artists,
    List<Album> albums,
  ) {
    return [
      // Announcement banner if broadcasted by Admin
      if (admin.announcementMessage.isNotEmpty)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    admin.announcementMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),

      // 8-Card Quick Picks Grid (2 columns x 4 rows = Real JioSaavn Songs)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildListDelegate(
            _saavnQuickPicks.isNotEmpty
                ? _saavnQuickPicks.take(8).map((song) {
                    return _buildQuickTile(
                      title: song.title,
                      imageUrl: song.coverUrl,
                      onTap: () => player.playSong(song, contextPlaylist: _saavnQuickPicks),
                    );
                  }).toList()
                : [
                    _buildQuickTile(
                      title: 'ANYWAY',
                      imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?q=80&w=300',
                      onTap: () => _playTrackByTitle(player, 'ANYWAY'),
                    ),
                    _buildQuickTile(
                      title: 'Svantesson',
                      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300',
                      onTap: () => _playTrackByTitle(player, 'Fine Young Man'),
                    ),
                    _buildQuickTile(
                      title: 'h4rdjump_1988',
                      imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=300',
                      onTap: () => _playTrackByTitle(player, 'h4rdjump_1988'),
                    ),
                    _buildQuickTile(
                      title: 'MXZI',
                      imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=300',
                      onTap: () => _playTrackByTitle(player, 'ERASE'),
                    ),
                    _buildQuickTile(
                      title: '\$werve',
                      imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=300',
                      onTap: () => _playTrackByTitle(player, 'Starboy (Exotic Edit)'),
                    ),
                    _buildQuickTile(
                      title: 'Known Unknowns',
                      imageUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=300',
                      onTap: () => _playTrackByTitle(player, 'Midnight City Beats'),
                    ),
                    _buildQuickTile(
                      title: 'SIDHU MOOSE WALA',
                      imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=300',
                      onTap: () => _playTrackByTitle(player, 'Phantom Ferrari'),
                    ),
                    _buildQuickTile(
                      title: 'TOP 10 MOST VIRAL PHONK',
                      imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=300',
                      onTap: () => _playTrackByTitle(player, 'MONTAGEM MODELLA'),
                    ),
                  ],
          ),
        ),
      ),

      // Advertisement / Sponsored Featured Banner
      SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text('Advertisement', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    Spacer(),
                    Icon(Icons.volume_off, color: Colors.white70, size: 18),
                    SizedBox(width: 12),
                    Icon(Icons.more_vert, color: Colors.white70, size: 18),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=800',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Filtr India', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      ),
                      onPressed: () {
                        if (_saavnTrendingHits.isNotEmpty) {
                          player.playSong(_saavnTrendingHits.first, contextPlaylist: _saavnTrendingHits);
                        } else if (songs.isNotEmpty) {
                          player.playSong(songs.first);
                        }
                      },
                      child: const Text('Listen now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Recommended for Today (Live JioSaavn Trending Hits)
      _buildSectionTitle('Trending Today in India'),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _saavnTrendingHits.isNotEmpty
                ? _saavnTrendingHits.map((s) {
                    return _buildRecommendedCard(
                      type: 'HOT TRACK',
                      title: s.title,
                      artist: s.artist,
                      imageUrl: s.coverUrl,
                      onTap: () => player.playSong(s, contextPlaylist: _saavnTrendingHits),
                    );
                  }).toList()
                : [
                    _buildRecommendedCard(
                      type: 'EP',
                      title: 'MONTAGEM MODELLA',
                      artist: 'ILLXSION',
                      imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=400',
                      onTap: () => _playTrackByTitle(player, 'MONTAGEM MODELLA'),
                    ),
                    _buildRecommendedCard(
                      type: 'EP',
                      title: 'ERASE',
                      artist: 'GXMZ, Repsaj',
                      imageUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?q=80&w=400',
                      onTap: () => _playTrackByTitle(player, 'ERASE'),
                    ),
                    _buildRecommendedCard(
                      type: 'SINGLE',
                      title: 'Fine Young Man',
                      artist: 'Dulla, Toxic',
                      imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=400',
                      onTap: () => _playTrackByTitle(player, 'Fine Young Man'),
                    ),
                  ],
          ),
        ),
      ),

      // Live Punjabi Hits Carousel
      if (_saavnPunjabiHits.isNotEmpty) ...[
        _buildSectionTitle('Popular Punjabi Hits'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _saavnPunjabiHits.length,
              itemBuilder: (context, index) {
                final s = _saavnPunjabiHits[index];
                return _buildRecommendedCard(
                  type: 'PUNJABI',
                  title: s.title,
                  artist: s.artist,
                  imageUrl: s.coverUrl,
                  onTap: () => player.playSong(s, contextPlaylist: _saavnPunjabiHits),
                );
              },
            ),
          ),
        ),
      ],

      // Live Bollywood Melodies Carousel
      if (_saavnBollywoodHits.isNotEmpty) ...[
        _buildSectionTitle('Soulful Bollywood Melodies'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _saavnBollywoodHits.length,
              itemBuilder: (context, index) {
                final s = _saavnBollywoodHits[index];
                return _buildRecommendedCard(
                  type: 'BOLLYWOOD',
                  title: s.title,
                  artist: s.artist,
                  imageUrl: s.coverUrl,
                  onTap: () => player.playSong(s, contextPlaylist: _saavnBollywoodHits),
                );
              },
            ),
          ),
        ),
      ],

      // Dynamic Catalog Sections (Best of Punjabi, Artists, etc.)
      ...admin.homeSectionsList.expand((secTitle) => [
        _buildSectionTitle(secTitle),
        SliverToBoxAdapter(
          child: SizedBox(
            height: secTitle.toLowerCase().contains('artist') ? 160 : 190,
            child: _buildDynamicSectionContent(secTitle, artists, songs, playlists, albums, player),
          ),
        ),
      ]),
    ];
  }

  // =========================================================================
  // 3. TAB 2: MUSIC (Exact Spotify Layout with Latest Releases)
  // =========================================================================
  List<Widget> _buildMusicTabSlivers(AudioPlayerProvider player, MusicLibraryProvider library, List<Song> songs) {
    return [
      // Sub-Filter Chips Row (All, Music, Following, Podcasts)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              _buildSubChip('All'),
              const SizedBox(width: 8),
              _buildSubChip('Music'),
              const SizedBox(width: 8),
              _buildSubChip('Following'),
              const SizedBox(width: 8),
              _buildSubChip('Podcasts'),
            ],
          ),
        ),
      ),

      // 8-Card Quick Picks
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildListDelegate([
            _buildQuickTile(
              title: 'ANYWAY',
              imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?q=80&w=300',
              onTap: () => _playTrackByTitle(player, 'ANYWAY'),
            ),
            _buildQuickTile(
              title: 'Svantesson',
              imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300',
              onTap: () => _playTrackByTitle(player, 'Fine Young Man'),
            ),
            _buildQuickTile(
              title: '\$werve',
              imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=300',
              onTap: () => _playTrackByTitle(player, 'Starboy (Exotic Edit)'),
            ),
            _buildQuickTile(
              title: 'Known Unknowns',
              imageUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=300',
              onTap: () => _playTrackByTitle(player, 'Midnight City Beats'),
            ),
            _buildQuickTile(
              title: 'MXZI',
              imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=300',
              onTap: () => _playTrackByTitle(player, 'ERASE'),
            ),
            _buildQuickTile(
              title: 'h4rdjump_1988',
              imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=300',
              onTap: () => _playTrackByTitle(player, 'h4rdjump_1988'),
            ),
          ]),
        ),
      ),

      _buildSectionTitle('Recommended for today'),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildRecommendedCard(
                type: 'EP',
                title: 'MONTAGEM MODELLA',
                artist: 'ILLXSION',
                imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=400',
                onTap: () => _playTrackByTitle(player, 'MONTAGEM MODELLA'),
              ),
              _buildRecommendedCard(
                type: 'EP',
                title: 'ERASE',
                artist: 'GXMZ, Repsaj',
                imageUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?q=80&w=400',
                onTap: () => _playTrackByTitle(player, 'ERASE'),
              ),
            ],
          ),
        ),
      ),

      // Latest Releases Cards (From video frame 00:08)
      _buildSectionTitle('Latest releases'),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildLatestReleaseCard(
              title: 'Sidhu Moose Wala, Intense',
              subtitle: 'Phantom Ferrari • 3 days ago',
              trackInfo: '1 song • Phantom Ferrari',
              imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400',
              previewText: 'Preview single',
              onPreview: () => _playTrackByTitle(player, 'Phantom Ferrari'),
              onPlay: () => _playTrackByTitle(player, 'Phantom Ferrari'),
            ),
            const SizedBox(height: 12),
            _buildLatestReleaseCard(
              title: 'Mishashi Sensei',
              subtitle: 'JOGO DE SOMBRA HARDSTYLE • 1 week ago',
              trackInfo: '4 songs • JOGO DE SOMBRA HARDSTYLE - SLOWED...',
              imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400',
              previewText: 'Preview EP',
              onPreview: () => _playTrackByTitle(player, 'MONTAGEM MODELLA'),
              onPlay: () => _playTrackByTitle(player, 'MONTAGEM MODELLA'),
            ),
            const SizedBox(height: 12),
            _buildLatestReleaseCard(
              title: 'Svantesson, Olsson',
              subtitle: 'Hold On Nights • 2 weeks ago',
              trackInfo: '2 songs • Hold On Electronic',
              imageUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=400',
              previewText: 'Preview single',
              onPreview: () => _playTrackByTitle(player, 'Fine Young Man'),
              onPlay: () => _playTrackByTitle(player, 'Fine Young Man'),
            ),
          ]),
        ),
      ),
    ];
  }

  // =========================================================================
  // 4. TAB 3: PODCASTS (From video frame 00:10 to 00:12)
  // =========================================================================
  List<Widget> _buildPodcastsTabSlivers(AudioPlayerProvider player) {
    return [
      _buildSectionTitle('Latest episodes'),
      SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF242424),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Overlapping podcast artwork badges
              SizedBox(
                height: 70,
                width: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network('https://images.unsplash.com/photo-1590602847861-f357a9332bbc?q=80&w=150', width: 44, height: 44, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network('https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=150', width: 44, height: 44, fit: BoxFit.cover),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network('https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=150', width: 56, height: 56, fit: BoxFit.cover),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'You haven\'t followed any podcasts yet',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Follow your favourites to stay up to date.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                ),
                onPressed: () {},
                child: const Text('Browse podcasts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),

      // Videos You Might Like (From video frame 00:10)
      _buildSectionTitle('Videos you might like'),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildVideoCard(
              title: 'Stories Only Kids Will Understand!',
              channel: 'His Story: Animation Stories • 16 Oct • 1L+ plays',
              duration: '36:11',
              thumbnailUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?q=80&w=600',
            ),
            const SizedBox(height: 14),
            _buildVideoCard(
              title: 'Men\'s Health & Life Advice with Ranveer',
              channel: 'The Ranveer Show (TRS) • 2L+ plays',
              duration: '08:09',
              thumbnailUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=600',
            ),
          ]),
        ),
      ),
    ];
  }

  // =========================================================================
  // 5. TAB 4: AUDIOBOOKS (From video frame 00:14 to 00:15)
  // =========================================================================
  List<Widget> _buildAudiobooksTabSlivers(AudioPlayerProvider player) {
    return [
      _buildSectionTitle('Audiobooks for you'),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildAudiobookCard(
              title: 'The Art of Seduction (Unabridged)',
              author: 'Robert Greene • 18 Oct 2024 • 9 hrs 12 mins',
              description: 'The Art of Seduction is an indispensable primer of persuasion that reveals one of history\'s greatest weapons...',
              coverUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=400',
              onPreview: () => _playTrackByTitle(player, 'Starboy (Exotic Edit)'),
            ),
            const SizedBox(height: 14),
            _buildAudiobookCard(
              title: '12 Laws of Karma',
              author: 'Manhardeep Singh • 4 Jun 2024 • 57 mins',
              description: 'Life repeating the same old patterns? Embrace these 12 Laws of Karma to manifest a new version of yourself...',
              coverUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=400',
              onPreview: () => _playTrackByTitle(player, 'Midnight City Beats'),
            ),
          ]),
        ),
      ),
    ];
  }

  // =========================================================================
  // WIDGET HELPERS (Authentic Spotify Styling)
  // =========================================================================
  Widget _buildSubChip(String label) {
    final isSelected = _musicSubFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _musicSubFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(16),
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

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
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
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
              child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedCard({
    required String type,
    required String title,
    required String artist,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 145,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl, width: 145, height: 145, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestReleaseCard({
    required String title,
    required String subtitle,
    required String trackInfo,
    required String imageUrl,
    required String previewText,
    required VoidCallback onPreview,
    required VoidCallback onPlay,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(trackInfo, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: onPreview,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_up, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(previewText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.add_circle_outline, color: Colors.white70, size: 24),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onPlay,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: Colors.black, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard({
    required String title,
    required String channel,
    required String duration,
    required String thumbnailUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(thumbnailUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                  child: Text(duration, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
                  child: const Icon(Icons.volume_off, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(channel, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudiobookCard({
    required String title,
    required String author,
    required String description,
    required String coverUrl,
    required VoidCallback onPreview,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(coverUrl, width: 80, height: 80, fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(author, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: onPreview,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.volume_up, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Preview audiobook', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.add_circle_outline, color: Colors.white70, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSectionContent(
    String sectionTitle,
    List<Artist> artists,
    List<Song> allAppSongs,
    List<Playlist> playlists,
    List<Album> albums,
    AudioPlayerProvider player,
  ) {
    final lower = sectionTitle.toLowerCase();
    if (lower.contains('artist')) {
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
                  CircleAvatar(radius: 42, backgroundImage: NetworkImage(artist.imageUrl)),
                  const SizedBox(height: 6),
                  Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const Text('Artist', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allAppSongs.length,
        itemBuilder: (context, index) {
          final song = allAppSongs[index];
          return GestureDetector(
            onTap: () => player.playSong(song, contextPlaylist: allAppSongs),
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

  void _playTrackByTitle(AudioPlayerProvider player, String title) {
    final match = player.playlist.firstWhere(
      (s) => s.title.toLowerCase().contains(title.toLowerCase()),
      orElse: () => player.playlist.first,
    );
    player.playSong(match);
  }
}
