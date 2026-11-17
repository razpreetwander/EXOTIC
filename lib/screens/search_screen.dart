import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/music_data.dart';
import '../models/song_model.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../services/saavn_api_service.dart';
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
  List<Song> _saavnResults = [];
  String _activeGenre = 'All';

  // Popular Trending Search Suggestions
  final List<String> _trendingSuggestions = [
    'Karan Aujla',
    'Diljit Dosanjh',
    'Sidhu Moose Wala',
    'Arijit Singh',
    'Winning Speech',
    'Tauba Tauba',
    'Shubh',
    'AP Dhillon',
    'Top 50 India',
    'The Weeknd',
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _saavnResults = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 380), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    final results = await SaavnApiService.searchSongs(query, limit: 25);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _saavnResults = results;
    });
  }

  void _searchByGenre(String genre) {
    setState(() {
      _activeGenre = genre;
      _searchController.text = genre == 'All' ? '' : genre;
    });
    if (genre == 'All') {
      setState(() => _saavnResults = []);
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
                    : _searchController.text.trim().isNotEmpty || _saavnResults.isNotEmpty
                        ? _buildSearchResultsList(_saavnResults, playerProvider, libraryProvider)
                        : _buildBrowseAndTrendingView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseAndTrendingView() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Trending Searches
        const Text(
          'Trending Searches',
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
          children: _trendingSuggestions.map((query) {
            return ActionChip(
              backgroundColor: const Color(0xFF22242B),
              side: const BorderSide(color: Colors.white12),
              avatar: const Icon(Icons.trending_up, color: AppColors.primary, size: 16),
              label: Text(query, style: const TextStyle(color: Colors.white, fontSize: 12)),
              onPressed: () {
                _searchController.text = query;
                _performSearch(query);
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Browse All Categories Grid
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(Icons.music_note, color: Colors.white24, size: 50),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              'No results found for "${_searchController.text.trim()}"',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching with a different song or artist name',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
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
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: const Color(0xFF282828),
                child: const Icon(Icons.music_note, color: Colors.white54),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 320kbps Lossless Badge
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '320k',
                  style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(
                  libraryProvider.isLiked(song.id) ? Icons.favorite : Icons.favorite_border,
                  color: libraryProvider.isLiked(song.id) ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () {
                  libraryProvider.toggleLikeSong(song);
                },
              ),
            ],
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
