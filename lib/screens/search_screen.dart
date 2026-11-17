import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/music_data.dart';
import '../models/song_model.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../services/saavn_api_service.dart';
import '../services/yt_music_service.dart';
import '../theme/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isLoading = false;
  List<Song> _searchResults = [];
  String _activeGenre = 'All';

  List<String> _recentSearches = [];
  List<String> _favoriteArtists = [];

  static const String _prefRecentSearchesKey = 'user_recent_searches_list';

  @override
  void initState() {
    super.initState();
    _loadRecentSearchesAndTaste();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearchesAndTaste() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recents = prefs.getStringList(_prefRecentSearchesKey) ?? [];
      final preferredArtists = prefs.getStringList('user_preferred_artists') ?? [];

      if (mounted) {
        setState(() {
          _recentSearches = recents;
          _favoriteArtists = preferredArtists;
        });
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _recentSearches.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
      _recentSearches.insert(0, clean);
      if (_recentSearches.length > 15) {
        _recentSearches = _recentSearches.sublist(0, 15);
      }
      await prefs.setStringList(_prefRecentSearchesKey, _recentSearches);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> _removeRecentSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _recentSearches.remove(query);
      });
      await prefs.setStringList(_prefRecentSearchesKey, _recentSearches);
    } catch (e) {
      debugPrint('Error removing search item: $e');
    }
  }

  Future<void> _clearAllRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _recentSearches.clear();
      });
      await prefs.remove(_prefRecentSearchesKey);
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 380), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    _saveRecentSearch(cleanQuery);
    setState(() => _isLoading = true);

    try {
      // 1. Search JioSaavn Primary Engine
      final saavnFuture = SaavnApiService.searchSongs(cleanQuery, limit: 20);
      // 2. Search YouTube Secondary/Fallback Engine in Parallel
      final ytFuture = YtMusicService.searchSongsOnly(cleanQuery, limit: 10);

      final saavnSongs = await saavnFuture;
      final ytSongs = await ytFuture;

      // 3. Merge Non-Duplicates (Blueprint Rule 4: Match title & artist)
      final Set<String> existingSignatures = {};
      final List<Song> combined = [];

      for (final song in saavnSongs) {
        final sig = '${song.title.toLowerCase().trim()}|${song.artist.toLowerCase().trim()}';
        existingSignatures.add(sig);
        combined.add(song);
      }

      for (final ytSong in ytSongs) {
        final sig = '${ytSong.title.toLowerCase().trim()}|${ytSong.artist.toLowerCase().trim()}';
        if (!existingSignatures.contains(sig)) {
          existingSignatures.add(sig);
          combined.add(ytSong);
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _searchResults = combined;
      });
    } catch (e) {
      debugPrint('Error during hybrid music search: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _searchByGenre(String genre) {
    setState(() {
      _activeGenre = genre;
      _searchController.text = genre == 'All' ? '' : genre;
    });
    if (genre == 'All') {
      setState(() => _searchResults = []);
    } else {
      _performSearch(genre);
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final playerProvider = Provider.of<AudioPlayerProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Search',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: _performSearch,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Songs, artists, or podcasts...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Genre Filter Chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: MusicData.genres.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final genreName = index == 0 ? 'All' : MusicData.genres[index - 1]['name']!;
                    final isSelected = _activeGenre == genreName;

                    return ChoiceChip(
                      label: Text(genreName),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.cardBg,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          _searchByGenre(genreName);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : _searchController.text.trim().isNotEmpty || _searchResults.isNotEmpty
                        ? _buildSearchResultsList(_searchResults, playerProvider, libraryProvider)
                        : _buildRecentAndFavoritesView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAndFavoritesView() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. RECENT SEARCHES (Exact User History with Clear & Delete)
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: _clearAllRecentSearches,
                child: const Text('Clear all', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ..._recentSearches.take(8).map((query) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: AppColors.textSecondary, size: 20),
              title: Text(
                query,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                onPressed: () => _removeRecentSearch(query),
              ),
              onTap: () {
                _searchController.text = query;
                _performSearch(query);
              },
            );
          }),
          const SizedBox(height: 20),
        ],

        // 2. YOUR FAVORITES (Based on User Taste & Preferred Artists)
        if (_favoriteArtists.isNotEmpty) ...[
          const Text(
            'Your favorites',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _favoriteArtists.map((artistName) {
              return ActionChip(
                backgroundColor: const Color(0xFF22242B),
                side: const BorderSide(color: Colors.white12),
                avatar: const Icon(Icons.favorite, color: AppColors.primary, size: 15),
                label: Text(artistName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                onPressed: () {
                  _searchController.text = artistName;
                  _performSearch(artistName);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // 3. BROWSE ALL GENRES GRID
        const Text(
          'Browse all',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: MusicData.genres.length,
          itemBuilder: (context, index) {
            final item = MusicData.genres[index];
            final String name = item['name']!;
            final Color color = Color(int.parse(item['color']!));

            return GestureDetector(
              onTap: () => _searchByGenre(name),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Transform.rotate(
                        angle: 0.3,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.music_note, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildSearchResultsList(
    List<Song> results,
    AudioPlayerProvider playerProvider,
    MusicLibraryProvider libraryProvider,
  ) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No tracks found. Try another query.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        final isCurrent = playerProvider.currentSong?.id == song.id;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              song.coverUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: AppColors.surfaceLight,
                child: const Icon(Icons.music_note, color: AppColors.textMuted),
              ),
            ),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCurrent ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${song.artist} • ${song.album}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: IconButton(
            icon: Icon(
              libraryProvider.isLiked(song.id) ? Icons.favorite : Icons.favorite_border,
              color: libraryProvider.isLiked(song.id) ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            onPressed: () {
              libraryProvider.toggleLikeSong(song);
            },
          ),
          onTap: () {
            libraryProvider.logRecentlyPlayed(song);
            playerProvider.playSong(song, contextPlaylist: results);
          },
        );
      },
    );
  }
}
