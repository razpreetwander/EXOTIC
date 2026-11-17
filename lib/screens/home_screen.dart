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
import 'playlist_detail_screen.dart';

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
  List<Playlist> _saavnPlaylists = [];
  List<Artist> _userFavoriteArtists = [];
  bool _isFetchingSaavn = false;

  static final Map<String, String> _artistImages = {
    'Karan Aujla': 'https://c.saavncdn.com/artists/Karan_Aujla_005_20260925061936_500x500.jpg',
    'Diljit Dosanjh': 'https://c.saavncdn.com/artists/Diljit_Dosanjh_005_20231025073054_500x500.jpg',
    'Sidhu Moose Wala': 'https://c.saavncdn.com/artists/Sidhu_Moose_Wala_004_20250617183705_500x500.jpg',
    'Arijit Singh': 'https://c.saavncdn.com/artists/Arijit_Singh_004_20241118063717_500x500.jpg',
    'Shubh': 'https://c.saavncdn.com/artists/Shubh_000_20220921112507_500x500.jpg',
    'AP Dhillon': 'https://c.saavncdn.com/890/Excuses-English-2021-20210930112054-500x500.jpg',
    'Yo Yo Honey Singh': 'https://c.saavncdn.com/artists/Yo_Yo_Honey_Singh_004_20260811095253_500x500.jpg',
    'Badshah': 'https://c.saavncdn.com/artists/Badshah_006_20241118064015_500x500.jpg',
    'DIVINE': 'https://c.saavncdn.com/artists/DIVINE_006_20250911071442_500x500.jpg',
    'Divine': 'https://c.saavncdn.com/artists/DIVINE_006_20250911071442_500x500.jpg',
    'The Weeknd': 'https://c.saavncdn.com/artists/The_Weeknd_002_20241003071400_500x500.jpg',
    'Dua Lipa': 'https://c.saavncdn.com/artists/Dua_Lipa_004_20231120090922_500x500.jpg',
    'Justin Bieber': 'https://c.saavncdn.com/artists/Justin_Bieber_005_20201127112218_500x500.jpg',
    'Taylor Swift': 'https://c.saavncdn.com/artists/Taylor_Swift_003_20200226074119_500x500.jpg',
    'BTS': 'https://c.saavncdn.com/artists/BTS_006_20260624192553_500x500.jpg',
    'Ed Sheeran': 'https://c.saavncdn.com/artists/Ed_Sheeran_002_20250625073038_500x500.jpg',
    'Drake': 'https://c.saavncdn.com/artists/Drake_006_20260520062317_500x500.jpg',
    'Guru Randhawa': 'https://c.saavncdn.com/artists/Guru_Randhawa_005_20261026140443_500x500.jpg',
    'Amrinder Gill': 'https://c.saavncdn.com/artists/Amrinder_Gill_500x500.jpg',
    'B Praak': 'https://c.saavncdn.com/artists/B_Praak_001_20191118112005_500x500.jpg',
    'Atif Aslam': 'https://c.saavncdn.com/169/Monsoon-Bollywood-Hits-Hindi-2023-20230616161232-500x500.jpg',
    'Sunanda Sharma': 'https://c.saavncdn.com/545/Jaani-Tera-Naa-Punjabi-2017-500x500.jpg',
    'Gippy Grewal': 'https://c.saavncdn.com/artists/Gippy_Grewal_004_20191118143844_500x500.jpg',
    'Jass Manak': 'https://c.saavncdn.com/artists/Jass_Manak_001_20240119064204_500x500.jpg',
    'Neha Kakkar': 'https://c.saavncdn.com/artists/Neha_Kakkar_007_20241212115832_500x500.jpg',
    'Shreya Ghoshal': 'https://c.saavncdn.com/artists/Shreya_Ghoshal_007_20241101074144_500x500.jpg',
    'Jubin Nautiyal': 'https://c.saavncdn.com/artists/Jubin_Nautiyal_003_20231130204020_500x500.jpg',
    'Lata Mangeshkar': 'https://c.saavncdn.com/artists/Lata_Mangeshkar_004_20230623105323_500x500.jpg',
    'Kishore Kumar': 'https://c.saavncdn.com/artists/Kishore_Kumar_500x500.jpg',
  };

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
      final preferredLanguages = prefs.getStringList('user_preferred_languages') ?? ['Punjabi', 'Hindi', 'English'];
      final primaryArtist = preferredArtists.isNotEmpty ? preferredArtists.first : 'Karan Aujla';

      // 1. Build favorite artists models from user's selected preferences
      final List<Artist> favArtists = preferredArtists.map((name) {
        final img = _artistImages[name] ?? 'https://c.saavncdn.com/artists/Karan_Aujla_005_20260925061936_500x500.jpg';
        return Artist(
          id: 'artist_${name.toLowerCase().replaceAll(' ', '_')}',
          name: name,
          imageUrl: img,
          bio: '$name verified artist discography on EXOTIC MUSIC.',
          language: preferredLanguages.isNotEmpty ? preferredLanguages.first : 'Punjabi',
          artistType: 'Artist',
          genre: 'Top Hits',
          monthlyListeners: 18500000,
        );
      }).toList();

      // 2. Fetch 8 Quick Picks based on user's primary artist
      final quickSongs = await SaavnApiService.searchSongs(primaryArtist, limit: 8);

      // 3. Fetch Trending 50 India
      final trending = await SaavnApiService.searchSongs('Trending Top 50 India', limit: 12);

      // 4. Fetch First Preferred Language Hits (Famous official songs)
      final lang1 = preferredLanguages.isNotEmpty ? preferredLanguages[0] : 'Punjabi';
      final lang1Songs = await SaavnApiService.getFamousSongsForLanguage(lang1, limit: 12);

      // 5. Fetch Second Preferred Language Hits (Famous official songs)
      final lang2 = preferredLanguages.length > 1 ? preferredLanguages[1] : 'Hindi';
      final lang2Songs = await SaavnApiService.getFamousSongsForLanguage(lang2, limit: 12);

      // 6. Fetch Real JioSaavn Playlists
      final playlists = await SaavnApiService.searchPlaylists('Top Hits India', limit: 10);

      if (mounted) {
        setState(() {
          _userFavoriteArtists = favArtists;
          if (quickSongs.isNotEmpty) _saavnQuickPicks = quickSongs;
          if (trending.isNotEmpty) _saavnTrendingHits = trending;
          if (lang1Songs.isNotEmpty) _saavnPunjabiHits = lang1Songs;
          if (lang2Songs.isNotEmpty) _saavnBollywoodHits = lang2Songs;
          if (playlists.isNotEmpty) _saavnPlaylists = playlists;
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
      // 1. Your Favorite Artists Carousel (Directly from User Onboarding/Settings Taste)
      if (_userFavoriteArtists.isNotEmpty) ...[
        _buildSectionTitle('Your Favorite Artists'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _userFavoriteArtists.length,
              itemBuilder: (context, index) {
                final artist = _userFavoriteArtists[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtistProfileScreen(artist: artist),
                      ),
                    );
                  },
                  child: Container(
                    width: 105,
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.surfaceLight,
                          backgroundImage: NetworkImage(artist.imageUrl),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          'Artist',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
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

      // 2. 8-Card Quick Picks Grid (Real Dynamic JioSaavn Songs from User Taste)
      _buildSectionTitle('Quick Picks For You'),
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
                : List.generate(
                    8,
                    (i) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF242424),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(width: 54, color: const Color(0xFF333333)),
                          const SizedBox(width: 10),
                          Container(width: 70, height: 10, color: const Color(0xFF333333)),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),

      // Featured Playlist Banner (Highlights the top trending playlist banner)
      if (_saavnPlaylists.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: GestureDetector(
              onTap: () {
                final topPl = _saavnPlaylists.first;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaylistDetailScreen(playlist: topPl),
                  ),
                );
              },
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _saavnPlaylists.first.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF242424)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.9),
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FEATURED PLAYLIST • 320K LOSSLESS',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _saavnPlaylists.first.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _saavnPlaylists.first.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                                  label: const Text('Play Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: () async {
                                    final songs = await SaavnApiService.getPlaylistSongs(_saavnPlaylists.first.id);
                                    if (songs.isNotEmpty) {
                                      player.playPlaylist(songs);
                                    }
                                  },
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white30),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlaylistDetailScreen(playlist: _saavnPlaylists.first),
                                      ),
                                    );
                                  },
                                  child: const Text('View Tracks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],

      // 3. Trending Playlists Carousel (Real JioSaavn Playlists)
      if (_saavnPlaylists.isNotEmpty) ...[
        _buildSectionTitle('Trending Playlists'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _saavnPlaylists.length,
              itemBuilder: (context, index) {
                final pl = _saavnPlaylists[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailScreen(playlist: pl),
                      ),
                    );
                  },
                  child: Container(
                    width: 145,
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            pl.coverUrl,
                            width: 145,
                            height: 135,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 145,
                              height: 135,
                              color: const Color(0xFF282828),
                              child: const Icon(Icons.queue_music, color: AppColors.primary, size: 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pl.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pl.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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

      // 4. Trending Today in India (Real 320kbps JioSaavn Tracks)
      if (_saavnTrendingHits.isNotEmpty) ...[
        _buildSectionTitle('Trending Today in India'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _saavnTrendingHits.length,
              itemBuilder: (context, index) {
                final s = _saavnTrendingHits[index];
                return _buildRecommendedCard(
                  type: 'HOT TRACK',
                  title: s.title,
                  artist: s.artist,
                  imageUrl: s.coverUrl,
                  onTap: () => player.playSong(s, contextPlaylist: _saavnTrendingHits),
                );
              },
            ),
          ),
        ),
      ],

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

      // 8-Card Quick Picks (Real Tracks)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                : List.generate(
                    8,
                    (i) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF242424),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
          ),
        ),
      ),

      // Recommended for Today (Real JioSaavn Trending Tracks)
      _buildSectionTitle('Recommended for today'),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _saavnTrendingHits.length,
            itemBuilder: (context, index) {
              final song = _saavnTrendingHits[index];
              return _buildRecommendedCard(
                type: '320K LOSSLESS',
                title: song.title,
                artist: song.artist,
                imageUrl: song.coverUrl,
                onTap: () => player.playSong(song, contextPlaylist: _saavnTrendingHits),
              );
            },
          ),
        ),
      ),

      // Latest Releases Cards (Real Tracks)
      _buildSectionTitle('Latest releases'),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildListDelegate(
            _saavnTrendingHits.isNotEmpty
                ? _saavnTrendingHits.take(4).map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildLatestReleaseCard(
                        title: s.artist,
                        subtitle: '${s.title} • Lossless Audio',
                        trackInfo: 'Single • ${s.album}',
                        imageUrl: s.coverUrl,
                        previewText: 'Play 320k Track',
                        onPreview: () => player.playSong(s, contextPlaylist: _saavnTrendingHits),
                        onPlay: () => player.playSong(s, contextPlaylist: _saavnTrendingHits),
                      ),
                    );
                  }).toList()
                : [],
          ),
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
