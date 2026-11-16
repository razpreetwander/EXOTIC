import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../theme/app_colors.dart';

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final playlist = playerProvider.playlist;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.queue_music, color: AppColors.primary, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Playing Queue (${playlist.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Drag handles to reorder tracks or swipe to remove.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Queue List
          Expanded(
            child: playlist.isEmpty
                ? const Center(
                    child: Text('Queue is empty', style: TextStyle(color: AppColors.textMuted)),
                  )
                : ReorderableListView.builder(
                    itemCount: playlist.length,
                    onReorder: (oldIndex, newIndex) {
                      playerProvider.reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = playlist[index];
                      final isCurrent = (index == playerProvider.currentIndex);

                      return Container(
                        key: ValueKey(song.id + index.toString()),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.cardBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrent
                              ? Border.all(color: AppColors.primary.withOpacity(0.5))
                              : null,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              song.coverUrl,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent ? AppColors.secondary : AppColors.textPrimary,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                                onPressed: () {
                                  playerProvider.removeFromQueue(index);
                                },
                              ),
                              const Icon(Icons.drag_handle, color: AppColors.textMuted),
                            ],
                          ),
                          onTap: () {
                            playerProvider.playSong(song, contextPlaylist: playlist);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
