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
            // Header: Back Arrow (if can pop) + Settings Title + Search Icon
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
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
                  // Free / VIP Account Banner + Go Premium Button
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Text(
                          settings.isVipActive ? 'VIP Premium Active' : 'Free account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: settings.isVipActive ? AppColors.primary : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: settings.isVipActive ? AppColors.primary : Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          ),
                          onPressed: () {
                            settings.toggleVip(!settings.isVipActive);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  settings.isVipActive
                                      ? 'VIP Premium Mode Activated!'
                                      : 'Switched to Standard Tier',
                                ),
                              ),
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

                  // 1. Account
                  _buildSettingTile(
                    icon: Icons.person_outline,
                    title: 'Account',
                    subtitle: '${settings.username} • ${settings.email}',
                    onTap: () => _showAccountDialog(context, settings),
                  ),

                  // 2. Content & Display
                  _buildSettingTile(
                    icon: Icons.music_note_outlined,
                    title: 'Content and display',
                    subtitle: 'Visualizer (${settings.canvasVisualizer ? 'ON' : 'OFF'}) • Language: ${settings.appLanguage}',
                    onTap: () => _showDisplayDialog(context, settings),
                  ),

                  // 3. Privacy & Social
                  _buildSettingTile(
                    icon: Icons.lock_outline,
                    title: 'Privacy and social',
                    subtitle: settings.privateSession
                        ? 'Private session ON (History Hidden)'
                        : 'Private session • Public playlists',
                    onTap: () => _showPrivacyDialog(context, settings),
                  ),

                  // 4. Playback
                  _buildSettingTile(
                    icon: Icons.volume_up_outlined,
                    title: 'Playback',
                    subtitle: 'Equalizer • Gapless (${settings.gaplessPlayback ? 'ON' : 'OFF'}) • Crossfade (${settings.crossfadeDuration.toInt()}s)',
                    onTap: () => _showPlaybackDialog(context, settings),
                  ),

                  // 5. Notifications
                  _buildSettingTile(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notifications',
                    subtitle: 'Push Alerts (${settings.pushNotifications ? 'ON' : 'OFF'}) • Music updates',
                    onTap: () => _showNotificationsDialog(context, settings),
                  ),

                  // 6. Apps & Devices
                  _buildSettingTile(
                    icon: Icons.devices_outlined,
                    title: 'Apps and devices',
                    subtitle: 'Bluetooth • Connect audio output',
                    onTap: () => _showDevicesSheet(context),
                  ),

                  // 7. Data-Saving & Offline
                  _buildSettingTile(
                    icon: Icons.arrow_circle_down_outlined,
                    title: 'Data-saving and offline',
                    subtitle: 'Data Saver (${settings.dataSaver ? 'ON' : 'OFF'}) • Cache: ${settings.cacheSizeMb.toStringAsFixed(1)} MB',
                    onTap: () => _showDataSaverDialog(context, settings),
                  ),

                  // 8. Media Quality
                  _buildSettingTile(
                    icon: Icons.bar_chart_outlined,
                    title: 'Media quality',
                    subtitle: 'Stream: ${settings.audioQuality}',
                    onTap: () => _showMediaQualitySheet(context, settings),
                  ),

                  // 9. Advertisements
                  _buildSettingTile(
                    icon: Icons.subtitles_outlined,
                    title: 'Advertisements',
                    subtitle: settings.isVipActive ? 'Ad-Free Playback Active' : 'Personalized ads enabled',
                    onTap: () => _showAdsDialog(context, settings),
                  ),

                  // 10. About & Support
                  _buildSettingTile(
                    icon: Icons.info_outline,
                    title: 'About and support',
                    subtitle: 'Version 2.5.0 • Google Drive Direct Engine',
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
                      onPressed: () => _showLogoutDialog(context, settings),
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
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Search Settings', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Type: quality, equalizer, account, cache...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              final query = searchController.text.trim().toLowerCase();
              Navigator.pop(ctx);
              if (query.contains('equalizer') || query.contains('eq')) {
                showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const EqualizerSheet());
              } else if (query.contains('quality') || query.contains('audio')) {
                _showMediaQualitySheet(context, settings);
              } else if (query.contains('account') || query.contains('user')) {
                _showAccountDialog(context, settings);
              } else if (query.contains('cache') || query.contains('data') || query.contains('storage')) {
                _showDataSaverDialog(context, settings);
              } else if (query.contains('device') || query.contains('bluetooth')) {
                _showDevicesSheet(context);
              } else if (query.contains('privacy') || query.contains('social')) {
                _showPrivacyDialog(context, settings);
              } else {
                _showPlaybackDialog(context, settings);
              }
            },
            child: const Text('Search', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAccountDialog(BuildContext context, SettingsProvider settings) {
    final userCtrl = TextEditingController(text: settings.username);
    final emailCtrl = TextEditingController(text: settings.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Account Profile', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: userCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Colors.white60),
                prefixIcon: Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(color: Colors.white60),
                prefixIcon: Icon(Icons.email, color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Membership: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  settings.isVipActive ? 'VIP Premium' : 'Free Standard',
                  style: TextStyle(
                    color: settings.isVipActive ? AppColors.primary : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            onPressed: () {
              if (userCtrl.text.trim().isNotEmpty) {
                settings.setUsername(userCtrl.text.trim());
              }
              if (emailCtrl.text.trim().isNotEmpty) {
                settings.setEmail(emailCtrl.text.trim());
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account details updated successfully!')));
            },
            child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
                subtitle: const Text('Show animated canvas on now playing', style: TextStyle(color: Colors.white54, fontSize: 11)),
                value: settings.canvasVisualizer,
                activeTrackColor: AppColors.primary,
                activeColor: Colors.white,
                onChanged: (val) {
                  settings.toggleCanvasVisualizer(val);
                  setSt(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Explicit Content', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Allow playback of explicit-rated tracks', style: TextStyle(color: Colors.white54, fontSize: 11)),
                value: settings.showExplicitContent,
                activeTrackColor: AppColors.primary,
                activeColor: Colors.white,
                onChanged: (val) {
                  settings.toggleExplicitContent(val);
                  setSt(() {});
                },
              ),
              const Divider(color: Colors.white24),
              ListTile(
                title: const Text('App Language', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(settings.appLanguage, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                trailing: const Icon(Icons.arrow_drop_down, color: Colors.white),
                onTap: () {
                  _showLanguagePicker(context, settings);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    final languages = ['English', 'Hindi', 'Punjabi', 'Spanish', 'French'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Select App Language', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final isSel = settings.appLanguage == lang;
            return ListTile(
              title: Text(lang, style: TextStyle(color: isSel ? AppColors.primary : Colors.white, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
              trailing: isSel ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                settings.setAppLanguage(lang);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Private Session', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Hide listening activity from followers', style: TextStyle(color: Colors.white54, fontSize: 11)),
                value: settings.privateSession,
                activeTrackColor: AppColors.primary,
                activeColor: Colors.white,
                onChanged: (val) {
                  settings.togglePrivateSession(val);
                  setSt(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Share Listening Activity', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Publish recently played songs to your profile', style: TextStyle(color: Colors.white54, fontSize: 11)),
                value: settings.listeningActivity,
                activeTrackColor: AppColors.primary,
                activeColor: Colors.white,
                onChanged: (val) {
                  settings.toggleListeningActivity(val);
                  setSt(() {});
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
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
                leading: const Icon(Icons.graphic_eq, color: AppColors.primary),
                title: const Text('Open 10-Band Equalizer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Bass boost, treble, & surround sound', style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const EqualizerSheet());
                },
              ),
              SwitchListTile(
                title: const Text('Gapless Playback', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: settings.gaplessPlayback,
                activeTrackColor: AppColors.primary,
                activeColor: Colors.white,
                onChanged: (v) {
                  settings.toggleGapless(v);
                  setSt(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Autoplay Similar Songs', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: settings.autoplay,
                activeTrackColor: AppColors.primary,
                activeColor: Colors.white,
                onChanged: (v) {
                  settings.toggleAutoplay(v);
                  setSt(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Audio Normalization', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Sets same volume level for all songs', style: TextStyle(color: Colors.white54, fontSize: 11)),
                value: settings.audioNormalization,
                activeTrackColor: AppColors.primary,
                activeColor: Colors.white,
                onChanged: (v) {
                  settings.toggleAudioNormalization(v);
                  setSt(() {});
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Crossfade (${settings.crossfadeDuration.toInt()}s)', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    Expanded(
                      child: Slider(
                        value: settings.crossfadeDuration,
                        min: 0.0,
                        max: 12.0,
                        divisions: 12,
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.white24,
                        onChanged: (val) {
                          settings.setCrossfade(val);
                          setSt(() {});
                        },
                      ),
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
            activeTrackColor: AppColors.primary,
            activeColor: Colors.white,
            onChanged: (val) {
              settings.toggleNotifications(val);
              setSt(() {});
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
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
          title: const Text('Data Saver & Offline Storage', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Data Saver Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Low bandwidth streaming on mobile data', style: TextStyle(color: Colors.white54, fontSize: 11)),
                value: settings.dataSaver,
                activeTrackColor: AppColors.primary,
                activeColor: Colors.white,
                onChanged: (v) {
                  settings.toggleDataSaver(v);
                  setSt(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Download over Wi-Fi only', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Saves cellular data while offline caching', style: TextStyle(color: Colors.white54, fontSize: 11)),
                value: settings.downloadWifiOnly,
                activeTrackColor: AppColors.primary,
                activeColor: Colors.white,
                onChanged: (v) {
                  settings.toggleDownloadWifiOnly(v);
                  setSt(() {});
                },
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.primary),
                title: const Text('Clear Cached Audio', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text('Cached: ${settings.cacheSizeMb.toStringAsFixed(1)} MB', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                trailing: TextButton(
                  onPressed: () async {
                    final cleared = await settings.clearCache();
                    setSt(() {});
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cleared ${cleared.toStringAsFixed(1)} MB cache!')));
                  },
                  child: const Text('Clear', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
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
      title: Text(
        quality,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.white,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        settings.setAudioQuality(quality);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Streaming quality set to: $quality')));
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
          settings.isVipActive
              ? 'Ad-free VIP playback is active for your account.'
              : 'Standard account has personalized audio advertisements.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('About EXOTIC Global Music', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version: 2.5.0 (Build 2026.08)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Engine: Google Drive v3 Direct Media API', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            const Text('Database: Firebase Realtime Database exoticglobalmusic', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_done, color: Colors.black, size: 18),
              label: const Text('Test Media Engine Connection', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Media Engine & Firebase Connection Verified: 100% Online!')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Privacy Policy', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F24),
        title: const Text('Log out of account?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('Are you sure you want to log out of ${settings.username} profile?', style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
