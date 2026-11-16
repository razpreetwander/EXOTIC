import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../theme/app_colors.dart';

class DevicePickerSheet extends StatefulWidget {
  const DevicePickerSheet({super.key});

  @override
  State<DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends State<DevicePickerSheet> {
  final List<Map<String, String>> _devices = [
    {'id': 'dev_phone', 'name': 'Exotic Mobile (This Phone)', 'type': 'Current Device', 'icon': 'assets/images/device_mobile.webp'},
    {'id': 'dev_headphones', 'name': 'Cyber Beats Wireless Headphones', 'type': 'Bluetooth • Active', 'icon': 'assets/images/device_headphones.webp'},
    {'id': 'dev_speaker', 'name': 'Exotic Studio Hi-Fi Speaker', 'type': 'Wi-Fi Speaker', 'icon': 'assets/images/device_speaker.webp'},
    {'id': 'dev_tv', 'name': 'Living Room Smart OLED TV', 'type': 'Chromecast / AirPlay', 'icon': 'assets/images/device_tv.webp'},
    {'id': 'dev_car', 'name': 'Exotic Car Audio', 'type': 'Android Auto / CarPlay', 'icon': 'assets/images/device_car.webp'},
    {'id': 'dev_laptop', 'name': 'MacBook Pro / Gaming Rig', 'type': 'Exotic Desktop App', 'icon': 'assets/images/device_computer.webp'},
    {'id': 'dev_watch', 'name': 'Exotic Smart Watch', 'type': 'Wearable', 'icon': 'assets/images/device_watch.webp'},
  ];

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final currentConnected = adminProvider.connectedDevice;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.cast_connected, color: AppColors.secondary, size: 26),
                  SizedBox(width: 10),
                  Text(
                    'Exotic Connect',
                    style: TextStyle(
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
          const SizedBox(height: 6),
          Text(
            'Active playback stream: $currentConnected',
            style: const TextStyle(color: Color(0xFF00FF87), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // List of available playback devices
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final dev = _devices[index];
                final isSelected = dev['name'] == currentConnected || (index == 0 && !currentConnected.contains(' '));

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.cardBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected ? Border.all(color: const Color(0xFF00FF87)) : null,
                  ),
                  child: ListTile(
                    leading: Image.asset(
                      dev['icon']!,
                      width: 32,
                      height: 32,
                      errorBuilder: (_, __, ___) => const Icon(Icons.devices, color: Color(0xFF00FF87)),
                    ),
                    title: Text(
                      dev['name']!,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00FF87) : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      dev['type']!,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.volume_up, color: Color(0xFF00FF87), size: 22)
                        : null,
                    onTap: () {
                      adminProvider.setConnectedDevice(dev['name']!);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Connected audio stream to ${dev['name']}')),
                      );
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
