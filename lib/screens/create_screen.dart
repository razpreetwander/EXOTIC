import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/create_playlist_dialog.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Start creating',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Build custom mixes, collaborate with friends, or organize your music.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 24),

              _buildCreateOption(
                context,
                icon: Icons.music_note,
                title: 'Playlist',
                subtitle: 'Build a playlist with songs, podcasts or audiobooks.',
                color: const Color(0xFF1ED760),
                onTap: () {
                  showDialog(context: context, builder: (_) => const CreatePlaylistDialog());
                },
              ),

              const SizedBox(height: 14),

              _buildCreateOption(
                context,
                icon: Icons.people_outline,
                title: 'Blend',
                subtitle: 'Combine your music taste with a friend in a shared mix.',
                color: const Color(0xFF2D9CDB),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Blend invite link generated! Share with your friend.')),
                  );
                },
              ),

              const SizedBox(height: 14),

              _buildCreateOption(
                context,
                icon: Icons.folder_outlined,
                title: 'Folder',
                subtitle: 'Organize your playlists into custom folders.',
                color: const Color(0xFF9B51E0),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Created new music folder in Library!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }
}
