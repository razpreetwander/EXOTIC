import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/equalizer_sheet.dart';
import '../widgets/device_picker_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back Arrow + Settings Title + Search Icon (Exact match for Screenshot 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 24),
                    onPressed: () => _showSettingsSearchDialog(context, settings),
                  ),
                ],
              ),
            ),

            // Scrollable Settings Content
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Free / VIP Account Banner + Go Premium Button (Screenshot 5)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Text(
                          settings.isVipActive ? 'VIP Premium Active' : 'Free account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: settings.isVipActive ? const Color(0xFF00FF87) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: settings.isVipActive ? const Color(0xFF00FF87) : Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          ),
                          onPressed: () {
                            settings.toggleVip(!settings.isVipActive);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(settings.isVipActive ? 'VIP Premium Mode Activated!' : 'Switched to Standard Tier')),
                            );
                          },
                          child: Text(
                            settings.isVipActive ? 'VIP Active ✅' : 'Go Premium',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 10 REAL PERSISTED Settings Category Options!
                  _buildSettingTile(
                    icon: Icons.person_outline,
                    title: 'Account',
                    subtitle: 'Username • Close account',
                    onTap: () => _showAccountDialog(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.music_note_outlined,
                    title: 'Content and display',
                    subtitle: 'Canvas Visualizer (${settings.canvasVisualizer ? 'ON' : 'OFF'}) • ${settings.appLanguage}',
                    onTap: () => _showDisplayDialog(context, settings),
                  ),
                  _buildSettingTile(
                    icon: Icons.lock_outline,
                    title: 'Privacy and social',
                    subtitle: settings.privateSession ? 'Private session ON (History Hidden)' : 'Private session • Public playlists',
                    onTap: () => _showPrivacyDialog(context, settings),
                  ),
                  _buildSettingTile(
                    icon: Icons.volume_up_outlined,
                    title: 'Playback',
                    subtitle: 'Equalizer • Gapless (${settings.gaplessPlayback ? 'ON' : 'OFF'}) • Autoplay (${settings.autoplay ? 'ON' : 'OFF'})',
                    onTap: () => _showPlaybackDialog(context, settings),
                  ),
                  _buildSettingTile(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notifications',
                    subtitle: 'Push Alerts (${settings.pushNotifications ? 'ON' : 'OFF'}) • Email',
                    onTap: () => _showNotificationsDialog(context, settings),
                  ),
                  _buildSettingTile(
                    icon: Icons.devices_outlined,
                    title: 'Apps and devices',
                    subtitle: 'Google Maps • Spotify Connect control',
                    onTap: () => _showDevicesSheet(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.arrow_circle_down_outlined,
                    title: 'Data-saving and offline',
                    subtitle: settings.dataSaver ? 'Data Saver Enabled (Low Bandwidth Stream)' : 'Data Saver mode • Downloads over cellular',
                    onTap: () => _showDataSaverDialog(context, settings),
                  ),
                  _buildSettingTile(
                    icon: Icons.bar_chart_outlined,
                    title: 'Media quality',
                    subtitle: 'Quality: ${settings.audioQuality}',
                    onTap: () => _showMediaQualitySheet(context, settings),
                  ),
                  _buildSettingTile(
                    icon: Icons.subtitles_outlined,
                    title: 'Advertisements',
                    subtitle: settings.isVipActive ? 'Ad-Free Playback Active' : 'Tailored ads enabled',
                    onTap: () => _showAdsDialog(context, settings),
                  ),
                  _buildSettingTile(
                    icon: Icons.info_outline,
                    title: 'About and support',
                    subtitle: 'Version 2.5.0 • Privacy Policy',
                    onTap: () => _showAboutDialog(context),
                  ),

                  const SizedBox(height: 24),

                  // Log out Button
                  Center(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                      ),
                      onPressed: () => _showLogoutDialog(context),
                      child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: Colors.white, size: 26),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
      onTap: onTap,
    );
  }

  void _showSettingsSearchDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Search Settings', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Type setting name (e.g. Quality, Equalizer)',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Search', style: TextStyle(color: Color(0xFF00FF87)))),
        ],
      ),
    );
  }

  void _showAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Account Details', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: Armaansingh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Email: user@exoticglobal.com', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 6),
            Text('Country: India (IN)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showDisplayDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF1E1F24),
          title: const Text('Content & Display', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Canvas Visualizer', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Show background video/visualizer', style: TextStyle(color: Colors.white54, fontSize: 11)),
                value: settings.canvasVisualizer,
                activeTrackColor: const Color(0xFF00FF87),
                onChanged: (val) {
                  settings.toggleCanvasVisualizer(val);
                  setSt(() {});
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done', style: TextStyle(color: Color(0xFF00FF87)))),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF1E1F24),
          title: const Text('Privacy & Social', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SwitchListTile(
            title: const Text('Private Session', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text('Hide listening activity from followers', style: TextStyle(color: Colors.white54, fontSize: 11)),
            value: settings.privateSession,
            activeTrackColor: const Color(0xFF00FF87),
            onChanged: (val) {
              settings.togglePrivateSession(val);
              setSt(() {});
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Save', style: TextStyle(color: Color(0xFF00FF87)))),
          ],
        ),
      ),
    );
  }

  void _showPlaybackDialog(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1F24),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setSt) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.graphic_eq, color: Color(0xFF00FF87)),
                title: const Text('Open 10-Band Equalizer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const EqualizerSheet());
                },
              ),
              SwitchListTile(
                title: const Text('Gapless Playback', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: settings.gaplessPlayback,
                activeTrackColor: const Color(0xFF00FF87),
                onChanged: (v) {
                  settings.toggleGapless(v);
                  setSt(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Autoplay Similar Songs', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: settings.autoplay,
                activeTrackColor: const Color(0xFF00FF87),
                onChanged: (v) {
                  settings.toggleAutoplay(v);
                  setSt(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF1E1F24),
          title: const Text('Notifications Settings', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SwitchListTile(
            title: const Text('Push Notifications', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text('Receive new releases & artist broadcasts', style: TextStyle(color: Colors.white54, fontSize: 11)),
            value: settings.pushNotifications,
            activeTrackColor: const Color(0xFF00FF87),
            onChanged: (val) {
              settings.toggleNotifications(val);
              setSt(() {});
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: Color(0xFF00FF87)))),
          ],
        ),
      ),
    );
  }

  void _showDevicesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DevicePickerSheet(),
    );
  }

  void _showDataSaverDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF1E1F24),
          title: const Text('Data Saver & Offline', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SwitchListTile(
            title: const Text('Data Saver Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text('Sets audio stream quality to low when on mobile data', style: TextStyle(color: Colors.white54, fontSize: 11)),
            value: settings.dataSaver,
            activeTrackColor: const Color(0xFF00FF87),
            onChanged: (v) {
              settings.toggleDataSaver(v);
              setSt(() {});
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done', style: TextStyle(color: Color(0xFF00FF87)))),
          ],
        ),
      ),
    );
  }

  void _showMediaQualitySheet(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1F24),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Audio Streaming Quality', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildQualityItem(context, settings, 'Ultra HD (FLAC 24-bit/96kHz)'),
            _buildQualityItem(context, settings, 'High (320 kbps AAC)'),
            _buildQualityItem(context, settings, 'Normal (160 kbps)'),
            _buildQualityItem(context, settings, 'Automatic (Network Adaptive)'),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityItem(BuildContext context, SettingsProvider settings, String quality) {
    final isSelected = settings.audioQuality == quality;
    return ListTile(
      title: Text(quality, style: TextStyle(color: isSelected ? const Color(0xFF00FF87) : Colors.white, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF00FF87)) : null,
      onTap: () {
        settings.setAudioQuality(quality);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Audio Streaming Quality set to: $quality')));
      },
    );
  }

  void _showAdsDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Advertisements', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          settings.isVipActive ? 'Ad-free VIP playback is active for your account.' : 'Standard account has personalized audio advertisements.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: Color(0xFF00FF87)))),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('About EXOTIC Global Music', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 2.5.0 (Build 2026.08)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Engine: Google Drive v3 Direct Media API', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 6),
            Text('Database: Firebase Realtime Database exoticglobalmusic', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Privacy Policy', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Color(0xFF00FF87)))),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Log out of account?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('Are you sure you want to log out of Armaansingh profile?', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
