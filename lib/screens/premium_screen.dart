import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Header Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIMITED TIME OFFER',
                  style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Experience music\nwithout limits.',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.15),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ad-free music listening, offline playback, and unlimited skips on mobile and desktop.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              // Current Plan Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Plan', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        SizedBox(height: 2),
                        Text('Exotic Free', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Free Account', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Why join Premium?',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              _buildPerkRow(Icons.block, 'Ad-free music listening', 'Enjoy uninterrupted high quality music streaming.'),
              _buildPerkRow(Icons.download_for_offline_outlined, 'Download to listen offline', 'Save your data by listening without an internet connection.'),
              _buildPerkRow(Icons.shuffle, 'Play in any order', 'Unlimited skips, play whatever song you want on demand.'),
              _buildPerkRow(Icons.high_quality, 'Ultra-High Audio Quality', 'Listen in pristine 320kbps Lossless audio quality.'),

              const SizedBox(height: 24),
              const Text(
                'Available Plans',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              // Plan Card 1: Individual
              _buildPlanCard(
                title: 'Premium Individual',
                price: '₹119 / month after trial',
                subtitle: '1 Premium account • Cancel anytime',
                accentColor: const Color(0xFFFFD2D7),
                textColor: Colors.black,
                btnText: 'Get Premium Individual',
              ),
              const SizedBox(height: 12),
              // Plan Card 2: Student
              _buildPlanCard(
                title: 'Premium Student',
                price: '₹59 / month after trial',
                subtitle: '1 verified student account • Cancel anytime',
                accentColor: const Color(0xFFC4B1D4),
                textColor: Colors.black,
                btnText: 'Get Premium Student',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerkRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String subtitle,
    required Color accentColor,
    required Color textColor,
    required String btnText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(4)),
            child: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(height: 12),
          Text(price, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {},
              child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
