import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
import '../theme/app_colors.dart';

class EqualizerSheet extends StatelessWidget {
  const EqualizerSheet({super.key});

  static const List<String> frequencies = ['60Hz', '230Hz', '910Hz', '3.6kHz', '14kHz'];
  static const List<String> presets = ['Exotic Bass', 'Pop Energy', 'Rock Synth', 'Vocal Warmth', 'Flat'];

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);

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
                  Icon(Icons.equalizer, color: AppColors.secondary, size: 26),
                  SizedBox(width: 10),
                  Text(
                    'Exotic Audio Equalizer',
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
          const SizedBox(height: 16),

          // Equalizer Preset Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = presets[index];
                final isSelected = playerProvider.currentEqPreset == preset;
                return ChoiceChip(
                  label: Text(preset),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.cardBg,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      playerProvider.setEqPreset(preset);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Frequency Sliders Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final gainDb = playerProvider.eqBands[index];
              return Column(
                children: [
                  Text(
                    '${gainDb > 0 ? '+' : ''}${gainDb.toStringAsFixed(1)}dB',
                    style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: gainDb,
                        min: -12.0,
                        max: 12.0,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.surfaceLight,
                        onChanged: (val) {
                          playerProvider.updateEqBand(index, val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    frequencies[index],
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 20),

          // Live Spectrum Bar Animation
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(9, (index) {
                final height = playerProvider.spectrumBars[index] * 40.0;
                return Container(
                  width: 14,
                  height: height.clamp(4.0, 40.0),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
