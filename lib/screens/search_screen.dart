import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/music_data.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../theme/app_colors.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final results = libraryProvider.filteredSongs;

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
                onChanged: (val) {
                  libraryProvider.setSearchQuery(val);
                },
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'What do you want to listen to?',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textPrimary),
                  suffixIcon: libraryProvider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted),
                          onPressed: () => libraryProvider.setSearchQuery(''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Genre Chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: MusicData.genres.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final genreName = index == 0 ? 'All' : MusicData.genres[index - 1]['name']!;
                    final isSelected = libraryProvider.selectedGenre == genreName;

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
                          libraryProvider.setSelectedGenre(genreName);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: libraryProvider.searchQuery.isEmpty && libraryProvider.selectedGenre == 'All'
                    ? _buildBrowseAllGrid(context, libraryProvider)
                    : _buildSearchResultsList(results, playerProvider, libraryProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseAllGrid(BuildContext context, MusicLibraryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse all',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
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
                onTap: () {
                  provider.setSelectedGenre(name);
                },
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
        ),
      ],
    );
  }

  Widget _buildSearchResultsList(
    List results,
    AudioPlayerProvider playerProvider,
    MusicLibraryProvider libraryProvider,
  ) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No songs found',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              song.coverUrl,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            song.title,
            style: TextStyle(
              color: isCurrent ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${song.artist} • ${song.album}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: IconButton(
            icon: Icon(
              song.isLiked ? Icons.favorite : Icons.favorite_border,
              color: song.isLiked ? AppColors.primary : AppColors.textMuted,
            ),
            onPressed: () {
              libraryProvider.toggleLikeSong(song);
            },
          ),
          onTap: () {
            libraryProvider.logRecentlyPlayed(song);
            playerProvider.playSong(song, contextPlaylist: results.cast());
          },
        );
      },
    );
  }
}
