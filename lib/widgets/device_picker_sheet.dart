import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/audio_player_provider.dart';
import '../theme/app_colors.dart';

class DevicePickerSheet extends StatefulWidget {
  const DevicePickerSheet({super.key});

  @override
  State<DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends State<DevicePickerSheet> {
  String _selectedRoute = 'This Phone (Built-in Speaker)';

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final isPlaying = playerProvider.isPlaying;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.speaker_group, color: AppColors.primary, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Connect to a device',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Real-time connected playback routes:',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // 1. PRIMARY REAL DEVICE: THIS PHONE
            GestureDetector(
              onTap: () {
                setState(() => _selectedRoute = 'This Phone (Built-in Speaker)');
                adminProvider.setConnectedDevice('This Phone (Built-in Speaker)');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Audio stream active on: This Phone')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedRoute == 'This Phone (Built-in Speaker)'
                      ? AppColors.primary.withOpacity(0.12)
                      : const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedRoute == 'This Phone (Built-in Speaker)'
                        ? AppColors.primary
                        : Colors.white10,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_android, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                'This Phone',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPlaying
                                ? 'Currently Playing'
                                : 'Ready to play',
                            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (isPlaying)
                      const Icon(Icons.volume_up, color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. REAL WIRELESS / BLUETOOTH / HEADPHONES ROUTE
            GestureDetector(
              onTap: () {
                setState(() => _selectedRoute = 'Bluetooth / Wired Headphones');
                adminProvider.setConnectedDevice('Bluetooth / Wired Headphones');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Switched to Bluetooth/Headphones output route. Connected headphones or car audio will play automatically!'),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedRoute == 'Bluetooth / Wired Headphones'
                      ? AppColors.primary.withOpacity(0.12)
                      : const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedRoute == 'Bluetooth / Wired Headphones'
                        ? AppColors.primary
                        : Colors.white10,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.headphones, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Bluetooth / Wired Audio',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Wireless Earbuds, Headphones or Car Audio',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedRoute == 'Bluetooth / Wired Headphones')
                      const Icon(Icons.check, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Real Hardware Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.white54, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'When you pair Bluetooth earbuds or connect your car, Android automatically routes the audio stream directly.',
                      style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
