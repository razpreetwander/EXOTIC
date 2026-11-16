import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/equalizer_sheet.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/device_picker_sheet.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  int _selectedTab = 0; // 0 = Cover, 1 = Lyrics

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final currentSong = playerProvider.currentSong;

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: Text('No song selected', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF282828),
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        const Text(
                          'PLAYING FROM PLAYLIST',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentSong.album,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.equalizer, color: AppColors.primary, size: 24),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const EqualizerSheet(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // View Selector (Cover / Lyrics)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Canvas', style: TextStyle(color: _selectedTab == 0 ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Lyrics', style: TextStyle(color: _selectedTab == 1 ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Main Artwork OR Lyrics
              Expanded(
                child: _selectedTab == 0
                    ? _buildCoverArtView(currentSong)
                    : _buildLyricsView(currentSong, playerProvider),
              ),

              const SizedBox(height: 12),

              // Song Info Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentSong.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        currentSong.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: currentSong.isLiked ? AppColors.primary : AppColors.textMuted,
                        size: 28,
                      ),
                      onPressed: () {
                        libraryProvider.toggleLikeSong(currentSong);
                      },
                    ),
                  ],
                ),
              ),

              // Audio Seek Slider & Timestamps
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: playerProvider.position.inMilliseconds.toDouble().clamp(0.0, playerProvider.duration.inMilliseconds.toDouble()),
                        min: 0.0,
                        max: playerProvider.duration.inMilliseconds > 0
                            ? playerProvider.duration.inMilliseconds.toDouble()
                            : 1.0,
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.white24,
                        onChanged: (value) {
                          playerProvider.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playerProvider.position),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          Text(
                            _formatDuration(playerProvider.duration),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Audio Player Controls (Spotify Green Play Circle)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: playerProvider.isShuffle ? AppColors.primary : AppColors.textSecondary,
                        size: 24,
                      ),
                      onPressed: () => playerProvider.toggleShuffle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: AppColors.textPrimary, size: 36),
                      onPressed: () => playerProvider.playPrevious(),
                    ),
                    // Main Play/Pause Button (#1DB954)
                    GestureDetector(
                      onTap: () => playerProvider.togglePlayPause(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: playerProvider.isLoading
                              ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 3)
                              : Icon(
                                  playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.black,
                                  size: 38,
                                ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: AppColors.textPrimary, size: 36),
                      onPressed: () => playerProvider.playNext(),
                    ),
                    IconButton(
                      icon: Icon(
                        playerProvider.loopState == LoopState.loopOne
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: playerProvider.loopState != LoopState.off ? AppColors.primary : AppColors.textSecondary,
                        size: 24,
                      ),
                      onPressed: () => playerProvider.toggleLoop(),
                    ),
                  ],
                ),
              ),

              // Bottom Actions (Devices & Queue)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.devices, color: AppColors.primary, size: 22),
                      tooltip: 'Exotic Connect',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const DevicePickerSheet(),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.queue_music, color: AppColors.textSecondary, size: 22),
                      tooltip: 'Up Next Queue',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const QueueSheet(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverArtView(Song song) {
    return Center(
      child: Hero(
        tag: 'now_playing_art_${song.id}',
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Image.network(
                song.coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsView(Song song, AudioPlayerProvider provider) {
    final lyrics = song.lyrics;

    if (lyrics.isEmpty) {
      return const Center(
        child: Text('No lyrics available for this track', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: lyrics.length,
        itemBuilder: (context, index) {
          final line = lyrics[index];
          final isCurrentLine = provider.position >= line.timestamp &&
              (index == lyrics.length - 1 || provider.position < lyrics[index + 1].timestamp);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              line.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isCurrentLine ? 18 : 15,
                fontWeight: isCurrentLine ? FontWeight.w900 : FontWeight.normal,
                color: isCurrentLine ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}
