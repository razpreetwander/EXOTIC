import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../theme/app_colors.dart';
import '../screens/now_playing_screen.dart';
import '../widgets/device_picker_sheet.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final currentSong = playerProvider.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final double progress = playerProvider.duration.inMilliseconds > 0
        ? (playerProvider.position.inMilliseconds / playerProvider.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const NowPlayingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        );
      },
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.playerBar,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  // Track Cover Art
                  Hero(
                    tag: 'now_playing_art_${currentSong.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        currentSong.coverUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title & Artist
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentSong.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Connect Device Icon
                  IconButton(
                    icon: const Icon(Icons.devices, color: AppColors.textSecondary, size: 20),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const DevicePickerSheet(),
                      );
                    },
                  ),
                  // Like Heart Button
                  IconButton(
                    icon: Icon(
                      currentSong.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: currentSong.isLiked ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      libraryProvider.toggleLikeSong(currentSong);
                    },
                  ),
                  // Play/Pause Button
                  IconButton(
                    icon: playerProvider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(
                            playerProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                            color: AppColors.textPrimary,
                            size: 32,
                          ),
                    onPressed: () {
                      playerProvider.togglePlayPause();
                    },
                  ),
                ],
              ),
            ),
            // Bottom Progress Bar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
