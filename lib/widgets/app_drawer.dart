import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../screens/settings_screen.dart';
import '../providers/admin_provider.dart';
import '../providers/music_library_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/settings_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Drawer(
      backgroundColor: const Color(0xFF1E1F24),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header: View Profile Action
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showProfileDialog(context, libraryProvider, settings);
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: adminProvider.themeAccentColor.withValues(alpha: 0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: adminProvider.themeAccentColor.withValues(alpha: 0.2), blurRadius: 10),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'View profile',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // Menu Item 1: Add Account
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
              title: const Text('Add account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Switch or add secondary profile', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                _showAddAccountDialog(context, settings);
              },
            ),

            // Menu Item 2: Recents
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white, size: 24),
              title: const Text('Recents', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text('${libraryProvider.recentlyPlayed.length} recently played tracks', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                _showRecentsDialog(context, libraryProvider, playerProvider);
              },
            ),

            // Menu Item 3: Your Updates
            ListTile(
              leading: const Icon(Icons.campaign_outlined, color: Colors.white, size: 24),
              title: const Text('Your Updates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text(adminProvider.announcementMessage.isNotEmpty ? adminProvider.announcementMessage : 'No new updates', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                _showUpdatesDialog(context, adminProvider);
              },
            ),

            // Menu Item 4: Settings and privacy
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
              title: const Text('Settings and privacy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Account, playback, offline & quality', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),

            const Spacer(),
            
            // Footer App Info
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'EXOTIC Global Music v2.5.0\nPowered by Google Drive & Firebase',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, MusicLibraryProvider lib, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                settings.username.isNotEmpty ? settings.username[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${settings.username} Profile',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Tier: VIP Premium Member', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Liked Songs: ${lib.likedSongs.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('Custom Playlists: ${lib.userPlaylists.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('Recently Listened: ${lib.recentlyPlayed.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Add / Switch Account', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('Multi-account sync enabled. You are currently logged in as primary account: ${settings.username}.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  void _showRecentsDialog(BuildContext context, MusicLibraryProvider lib, AudioPlayerProvider player) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Recently Played Tracks', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 260,
          child: lib.recentlyPlayed.isEmpty
              ? const Center(child: Text('No recents yet', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: lib.recentlyPlayed.length,
                  itemBuilder: (c, idx) {
                    final song = lib.recentlyPlayed[idx];
                    return ListTile(
                      dense: true,
                      leading: Image.network(song.coverUrl, width: 36, height: 36, fit: BoxFit.cover),
                      title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      onTap: () {
                        Navigator.pop(ctx);
                        player.playSong(song, contextPlaylist: lib.recentlyPlayed);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showUpdatesDialog(BuildContext context, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Live App Broadcasts', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          admin.announcementMessage.isNotEmpty ? admin.announcementMessage : 'No active announcements broadcasted by Admin right now.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }
}
