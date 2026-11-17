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
        height: 56,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        decoration: BoxDecoration(
          color: const Color(0xFF381F42),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    // Track Cover Art
                    Hero(
                      tag: 'now_playing_art_${currentSong.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          currentSong.coverUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 40,
                            height: 40,
                            color: const Color(0xFF282828),
                            child: const Icon(Icons.music_note, color: Colors.white54, size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Title & Artist with Explicit badge
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Text(
                                  'E',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  currentSong.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Connect Devices Icon
                    IconButton(
                      icon: const Icon(Icons.devices, color: Colors.white70, size: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const DevicePickerSheet(),
                        );
                      },
                    ),
                    // Add / Plus Button
                    IconButton(
                      icon: Icon(
                        currentSong.isLiked ? Icons.check_circle : Icons.add_circle_outline,
                        color: currentSong.isLiked ? AppColors.primary : Colors.white70,
                        size: 21,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        libraryProvider.toggleLikeSong(currentSong);
                      },
                    ),
                    // Play/Pause Button
                    IconButton(
                      icon: playerProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Icon(
                              playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 28,
                            ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        playerProvider.togglePlayPause();
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Progress Bar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
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
