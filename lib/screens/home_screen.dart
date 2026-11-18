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
import '../providers/settings_provider.dart';
import '../services/saavn_api_service.dart';
import '../services/yt_music_service.dart';
import '../services/notification_service.dart';
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

  // 12 Requested Dynamic Home Feed Sections (Strict User Sequence)
  List<Song> _saavnQuickPicks = [];         // 1. QUICK PICKS FOR YOU
  List<Artist> _userFavoriteArtists = [];   // 2. Your favourite artists
  List<Song> _recommendedForYou = [];       // 3. Recommended for you
  List<Song> _featuredReleases = [];        // 4. Featured Releases
  List<Song> _recentFallback = [];          // 5. RECENT (fallback if history empty)
  List<Map<String, dynamic>> _albumsYouLike = []; // 6. Albums you like
  List<Song> _recommendedToday = [];        // 7. Recommended for today
  List<Song> _toGetYouStarted = [];         // 8. To get you started
  List<Artist> _suggestedArtists = [];      // 9. suggested artists
  List<Song> _basedOnLatest = [];           // 10. based on your latest listening
  List<Song> _trendingSongs = [];           // 11. trending
  List<Song> _popularSongs = [];            // 12. popular

  bool _isFetchingSaavn = false;
  String _lang1Name = 'Hindi';
  String _lang2Name = 'Punjabi';
  String _primaryArtistName = 'Artist';
  String _secondaryArtistName = 'Artist';

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
      final preferredArtists = prefs.getStringList('user_preferred_artists') ?? [];
      final preferredLanguages = prefs.getStringList('user_preferred_languages') ?? [];

      final bool isInternational = (preferredLanguages.isNotEmpty &&
              (preferredLanguages.first.toLowerCase() == 'international' ||
                  preferredLanguages.first.toLowerCase() == 'english')) ||
          (preferredLanguages.isEmpty &&
              preferredArtists.any((a) => ['The Weeknd', 'Taylor Swift', 'Drake', 'BTS', 'Dua Lipa', 'Justin Bieber', 'Alan Walker', 'Katy Perry', 'Ed Sheeran'].contains(a)));

      final bool isPunjabi = preferredLanguages.isNotEmpty && preferredLanguages.first.toLowerCase() == 'punjabi';

      final String defaultArtist = isInternational ? 'The Weeknd' : (isPunjabi ? 'Karan Aujla' : 'Arijit Singh');
      final String defaultSecondary = isInternational ? 'Taylor Swift' : (isPunjabi ? 'Diljit Dosanjh' : 'Shreya Ghoshal');

      final primaryArtist = preferredArtists.isNotEmpty ? preferredArtists.first : defaultArtist;
      final secondaryArtist = preferredArtists.length > 1
          ? preferredArtists[1]
          : (preferredArtists.isNotEmpty ? preferredArtists.first : defaultSecondary);

      final lang1 = preferredLanguages.isNotEmpty ? preferredLanguages[0] : (isInternational ? 'International' : 'Hindi');
      final lang2 = preferredLanguages.length > 1
          ? preferredLanguages[1]
          : (preferredLanguages.isNotEmpty ? preferredLanguages[0] : (isInternational ? 'English' : 'Punjabi'));

      _lang1Name = lang1;
      _lang2Name = lang2;
      _primaryArtistName = primaryArtist;
      _secondaryArtistName = secondaryArtist;

      final userName = prefs.getString('user_name') ?? 'Music Lover';
      NotificationService.requestPermission().then((_) {
        NotificationService.checkAndShowWelcomeNotification(lang1, userName);
      });

      // Dynamic Section Search Queries based on user language preferences
      final String releasesQuery = isInternational ? 'New Releases English' : 'New Releases $lang1';
      final String recentQuery = isInternational ? 'Latest Pop Hits' : 'Latest Tracks $lang1';
      final String dailyHitsQuery = isInternational ? 'Global Daily Hits' : 'Daily Hits $lang1';
      final String suggestedArtistsQuery = isInternational ? 'English Pop' : lang1;
      final String trendingQuery = isInternational
          ? 'Global Top 50'
          : (isPunjabi ? 'Trending Punjabi Hits' : 'Trending Hits India');
      final String popularQuery = isInternational ? 'Global Pop Superhits' : 'Popular Superhits $lang1';

      // 1. DYNAMIC ARTISTS: Fetch real DP from YouTube / JioSaavn (NO hardcoded maps!)
      final List<Artist> favArtists = [];
      for (final name in preferredArtists) {
        final dp = await YtMusicService.getArtistProfilePic(name);
        favArtists.add(
          Artist(
            id: 'artist_${name.toLowerCase().replaceAll(' ', '_')}',
            name: name,
            imageUrl: dp,
            bio: '$name verified artist on EXOTIC MUSIC.',
            language: lang1,
            artistType: 'Artist',
            genre: 'Popular',
            monthlyListeners: 18500000,
          ),
        );
      }

      // 2. PARALLEL DYNAMIC FETCH for all 12 sections
      final quickPicksFuture = SaavnApiService.searchSongs(primaryArtist, limit: 8);
      final recommendedFuture = SaavnApiService.getFamousSongsForLanguage(isInternational ? 'International' : lang1, limit: 10);
      final featuredReleasesFuture = SaavnApiService.searchSongs(releasesQuery, limit: 10);
      final recentFallbackFuture = SaavnApiService.searchSongs(recentQuery, limit: 10);
      final albumsFuture = SaavnApiService.searchAlbums(primaryArtist, limit: 8);
      final recommendedTodayFuture = SaavnApiService.searchSongs(dailyHitsQuery, limit: 10);
      final toGetStartedFuture = SaavnApiService.getFamousSongsForLanguage(isInternational ? 'English' : lang2, limit: 10);
      final suggestedArtistsFuture = SaavnApiService.searchArtists(suggestedArtistsQuery, limit: 8);
      final basedOnLatestFuture = SaavnApiService.searchSongs(secondaryArtist, limit: 10);
      final trendingFuture = SaavnApiService.searchSongs(trendingQuery, limit: 12);
      final popularFuture = SaavnApiService.searchSongs(popularQuery, limit: 12);

      final quickSongs = await quickPicksFuture;
      final recSongs = await recommendedFuture;
      final featSongs = await featuredReleasesFuture;
      final recFallback = await recentFallbackFuture;
      final albums = await albumsFuture;
      final recToday = await recommendedTodayFuture;
      final startSongs = await toGetStartedFuture;
      final sugArtists = await suggestedArtistsFuture;
      final basedLatest = await basedOnLatestFuture;
      final trendSongs = await trendingFuture;
      final popSongs = await popularFuture;

      if (mounted) {
        setState(() {
          _userFavoriteArtists = favArtists;
          if (quickSongs.isNotEmpty) _saavnQuickPicks = quickSongs;
          if (recSongs.isNotEmpty) _recommendedForYou = recSongs;
          if (featSongs.isNotEmpty) _featuredReleases = featSongs;
          if (recFallback.isNotEmpty) _recentFallback = recFallback;
          if (albums.isNotEmpty) _albumsYouLike = albums;
          if (recToday.isNotEmpty) _recommendedToday = recToday;
          if (startSongs.isNotEmpty) _toGetYouStarted = startSongs;
          if (sugArtists.isNotEmpty) _suggestedArtists = sugArtists;
          if (basedLatest.isNotEmpty) _basedOnLatest = basedLatest;
          if (trendSongs.isNotEmpty) _trendingSongs = trendSongs;
          if (popSongs.isNotEmpty) _popularSongs = popSongs;
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
    final settings = Provider.of<SettingsProvider>(context);

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
                  // Circular Profile Avatar with user initial
                  Builder(
                    builder: (btnCtx) => GestureDetector(
                      onTap: () => Scaffold.of(btnCtx).openDrawer(),
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          settings.username.isNotEmpty ? settings.username[0].toUpperCase() : 'U',
                          style: const TextStyle(
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
      // 1. QUICK PICKS FOR YOU (Top)
      _buildSectionTitle('QUICK PICKS FOR YOU'),
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
                    ),
                  ),
          ),
        ),
      ),

      // 2. Your favourite artists (Directly below Quick Picks)
      if (_userFavoriteArtists.isNotEmpty) ...[
        _buildSectionTitle('Your favourite artists'),
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

      // 3. Recommended for you
      if (_recommendedForYou.isNotEmpty) ...[
        _buildSectionTitle('Recommended for you'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recommendedForYou.length,
              itemBuilder: (context, index) {
                final s = _recommendedForYou[index];
                return _buildRecommendedCard(
                  type: 'FOR YOU',
                  title: s.title,
                  artist: s.artist,
                  imageUrl: s.coverUrl,
                  onTap: () => player.playSong(s, contextPlaylist: _recommendedForYou),
                );
              },
            ),
          ),
        ),
      ],

      // 4. Featured Releases
      if (_featuredReleases.isNotEmpty) ...[
        _buildSectionTitle('Featured Releases'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _featuredReleases.length,
              itemBuilder: (context, index) {
                final s = _featuredReleases[index];
                return _buildRecommendedCard(
                  type: 'NEW RELEASE',
                  title: s.title,
                  artist: s.artist,
                  imageUrl: s.coverUrl,
                  onTap: () => player.playSong(s, contextPlaylist: _featuredReleases),
                );
              },
            ),
          ),
        ),
      ],

      // 5. RECENT
      _buildSectionTitle('RECENT'),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: (library.recentlyPlayed.isNotEmpty)
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: library.recentlyPlayed.length,
                  itemBuilder: (context, index) {
                    final s = library.recentlyPlayed[index];
                    return _buildRecommendedCard(
                      type: 'HISTORY',
                      title: s.title,
                      artist: s.artist,
                      imageUrl: s.coverUrl,
                      onTap: () => player.playSong(s, contextPlaylist: library.recentlyPlayed),
                    );
                  },
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recentFallback.length,
                  itemBuilder: (context, index) {
                    final s = _recentFallback[index];
                    return _buildRecommendedCard(
                      type: 'RECENT HITS',
                      title: s.title,
                      artist: s.artist,
                      imageUrl: s.coverUrl,
                      onTap: () => player.playSong(s, contextPlaylist: _recentFallback),
                    );
                  },
                ),
        ),
      ),

      // 6. Albums you like
      if (_albumsYouLike.isNotEmpty) ...[
        _buildSectionTitle('Albums you like'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 215,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _albumsYouLike.length,
              itemBuilder: (context, index) {
                final alb = _albumsYouLike[index];
                final cover = alb['coverUrl']?.toString() ?? '';
                final title = alb['title']?.toString() ?? 'Album';
                final artist = alb['artist']?.toString() ?? '';
                final year = alb['year']?.toString() ?? '';

                return GestureDetector(
                  onTap: () async {
                    final albumData = await SaavnApiService.getAlbumDetails(alb['id']?.toString() ?? '');
                    if (albumData != null && albumData['songs'] != null) {
                      final albSongs = List<Song>.from(albumData['songs']);
                      if (albSongs.isNotEmpty) {
                        player.playPlaylist(albSongs);
                      }
                    }
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
                            cover,
                            width: 145,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 145,
                              height: 140,
                              color: const Color(0xFF282828),
                              child: const Icon(Icons.album, color: AppColors.primary, size: 40),
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
                          '$artist ${year.isNotEmpty ? "• $year" : ""}',
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

      // 7. Recommended for today
      if (_recommendedToday.isNotEmpty) ...[
        _buildSectionTitle('Recommended for today'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recommendedToday.length,
              itemBuilder: (context, index) {
                final s = _recommendedToday[index];
                return _buildRecommendedCard(
                  type: 'DAILY MIX',
                  title: s.title,
                  artist: s.artist,
                  imageUrl: s.coverUrl,
                  onTap: () => player.playSong(s, contextPlaylist: _recommendedToday),
                );
              },
            ),
          ),
        ),
      ],

      // 8. To get you started
      if (_toGetYouStarted.isNotEmpty) ...[
        _buildSectionTitle('To get you started'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _toGetYouStarted.length,
              itemBuilder: (context, index) {
                final s = _toGetYouStarted[index];
                return _buildRecommendedCard(
                  type: 'ESSENTIALS',
                  title: s.title,
                  artist: s.artist,
                  imageUrl: s.coverUrl,
                  onTap: () => player.playSong(s, contextPlaylist: _toGetYouStarted),
                );
              },
            ),
          ),
        ),
      ],

      // 9. suggested artists
      if (_suggestedArtists.isNotEmpty) ...[
        _buildSectionTitle('suggested artists'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestedArtists.length,
              itemBuilder: (context, index) {
                final artist = _suggestedArtists[index];
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
                          'Suggested',
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

      // 10. based on your latest listening
      if (_basedOnLatest.isNotEmpty) ...[
        _buildSectionTitle('based on your latest listening'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _basedOnLatest.length,
              itemBuilder: (context, index) {
                final s = _basedOnLatest[index];
                return _buildRecommendedCard(
                  type: 'FOR YOU',
                  title: s.title,
                  artist: s.artist,
                  imageUrl: s.coverUrl,
                  onTap: () => player.playSong(s, contextPlaylist: _basedOnLatest),
                );
              },
            ),
          ),
        ),
      ],

      // 11. trending
      if (_trendingSongs.isNotEmpty) ...[
        _buildSectionTitle('tranding'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _trendingSongs.length,
              itemBuilder: (context, index) {
                final s = _trendingSongs[index];
                return _buildRecommendedCard(
                  type: 'TRENDING',
                  title: s.title,
                  artist: s.artist,
                  imageUrl: s.coverUrl,
                  onTap: () => player.playSong(s, contextPlaylist: _trendingSongs),
                );
              },
            ),
          ),
        ),
      ],

      // 12. popular
      if (_popularSongs.isNotEmpty) ...[
        _buildSectionTitle('popular'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _popularSongs.length,
              itemBuilder: (context, index) {
                final s = _popularSongs[index];
                return _buildRecommendedCard(
                  type: 'POPULAR',
                  title: s.title,
                  artist: s.artist,
                  imageUrl: s.coverUrl,
                  onTap: () => player.playSong(s, contextPlaylist: _popularSongs),
                );
              },
            ),
          ),
        ),
      ],
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
            itemCount: _trendingSongs.length,
            itemBuilder: (context, index) {
              final song = _trendingSongs[index];
              return _buildRecommendedCard(
                type: 'HOT TRACK',
                title: song.title,
                artist: song.artist,
                imageUrl: song.coverUrl,
                onTap: () => player.playSong(song, contextPlaylist: _trendingSongs),
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
            _trendingSongs.isNotEmpty
                ? _trendingSongs.take(4).map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildLatestReleaseCard(
                        title: s.artist,
                        subtitle: s.title,
                        trackInfo: 'Single • ${s.album}',
                        imageUrl: s.coverUrl,
                        previewText: 'Play Track',
                        onPreview: () => player.playSong(s, contextPlaylist: _trendingSongs),
                        onPlay: () => player.playSong(s, contextPlaylist: _trendingSongs),
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
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xFF242424),
                    backgroundImage: (artist.imageUrl.isNotEmpty && !artist.imageUrl.contains('unsplash.com'))
                        ? NetworkImage(artist.imageUrl)
                        : null,
                    child: (artist.imageUrl.isEmpty || artist.imageUrl.contains('unsplash.com'))
                        ? Text(
                            artist.name.isNotEmpty ? artist.name[0].toUpperCase() : 'A',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24),
                          )
                        : null,
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
