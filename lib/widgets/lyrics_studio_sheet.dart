import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/lyrics_translation_service.dart';
import '../theme/app_colors.dart';

class LyricsStudioSheet extends StatefulWidget {
  final String currentLanguage;
  final String currentFont;
  final String currentAnimation;
  final Function(String langCode) onLanguageSelected;
  final Function(String fontKey) onFontSelected;
  final Function(String animKey) onAnimationSelected;

  const LyricsStudioSheet({
    super.key,
    required this.currentLanguage,
    required this.currentFont,
    required this.currentAnimation,
    required this.onLanguageSelected,
    required this.onFontSelected,
    required this.onAnimationSelected,
  });

  @override
  State<LyricsStudioSheet> createState() => _LyricsStudioSheetState();
}

class _LyricsStudioSheetState extends State<LyricsStudioSheet> {
  int _activeTab = 0; // 0: Language, 1: Font, 2: Animation
  late String _selectedLang;
  late String _selectedFont;
  late String _selectedAnim;

  final List<Map<String, String>> _fonts = [
    {'key': 'outfit', 'name': 'Exotic Modern', 'desc': 'Clean, ultra-crisp modern sans'},
    {'key': 'montserrat', 'name': 'Spotify Bold', 'desc': 'Punchy, iconic music app typography'},
    {'key': 'poppins', 'name': 'Urban Flow', 'desc': 'Hip-Hop & Pop energetic groove'},
    {'key': 'spaceMono', 'name': 'Cyber Mono', 'desc': 'Synthwave, Phonk & EDM futuristic'},
    {'key': 'cinzel', 'name': 'Cinematic Serif', 'desc': 'Deep romantic & orchestral mood'},
    {'key': 'caveat', 'name': 'Handwritten', 'desc': 'Artistic, cursive acoustic feel'},
  ];

  final List<Map<String, String>> _animations = [
    {'key': 'karaoke', 'name': 'Karaoke Pulse', 'desc': 'Active line pulses with neon orange backlight aura'},
    {'key': 'apple', 'name': 'Apple Smooth Glide', 'desc': 'Active line expands in bold focus, inactive lines blur softly'},
    {'key': 'wave', 'name': 'Wave Shimmer', 'desc': 'Active line shimmers with warm orange gradient flow'},
    {'key': 'minimal', 'name': 'Minimal Crisp', 'desc': 'Classic Spotify-style fast highlight transition'},
    {'key': 'neon', 'name': 'Neon Frame', 'desc': 'Active line is framed in glowing orange cyber border'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLang = widget.currentLanguage;
    _selectedFont = widget.currentFont;
    _selectedAnim = widget.currentAnimation;
  }

  TextStyle _getPreviewTextStyle(String fontKey) {
    switch (fontKey) {
      case 'montserrat':
        return GoogleFonts.montserrat();
      case 'poppins':
        return GoogleFonts.poppins();
      case 'spaceMono':
        return GoogleFonts.spaceMono();
      case 'cinzel':
        return GoogleFonts.cinzel();
      case 'caveat':
        return GoogleFonts.caveat();
      case 'outfit':
      default:
        return GoogleFonts.outfit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF2C2C2C), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black87, blurRadius: 28, spreadRadius: 4),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Lyrics Studio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Real-time translation, custom fonts & animations',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3 Pill Tabs: Language / Font / Animation
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                _buildTabButton(0, Icons.translate_rounded, 'Language'),
                _buildTabButton(1, Icons.text_fields_rounded, 'Font'),
                _buildTabButton(2, Icons.auto_awesome_rounded, 'Animation'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tab Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _activeTab == 0
                  ? _buildLanguageTab()
                  : _activeTab == 1
                      ? _buildFontTab()
                      : _buildAnimationTab(),
            ),
          ),

          // Apply & Done Action
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Apply & Done',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSel = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSel ? Colors.black : Colors.white70),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSel ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 1: LANGUAGE SELECTION
  Widget _buildLanguageTab() {
    return ListView.builder(
      key: const ValueKey('lang_tab'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: LyricsTranslationService.supportedLanguages.length,
      itemBuilder: (context, index) {
        final item = LyricsTranslationService.supportedLanguages[index];
        final code = item['code']!;
        final name = item['name']!;
        final native = item['native']!;
        final flag = item['flag']!;
        final isSel = _selectedLang == code;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedLang = code);
            widget.onLanguageSelected(code);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSel ? AppColors.primary.withOpacity(0.14) : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSel ? AppColors.primary : Colors.white.withOpacity(0.06),
                width: isSel ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: isSel ? AppColors.primary : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        native,
                        style: TextStyle(
                          color: isSel ? AppColors.primary.withOpacity(0.8) : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSel)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: const Icon(Icons.check, size: 16, color: Colors.black),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 2: FONT SELECTION
  Widget _buildFontTab() {
    return ListView.builder(
      key: const ValueKey('font_tab'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: _fonts.length,
      itemBuilder: (context, index) {
        final font = _fonts[index];
        final key = font['key']!;
        final name = font['name']!;
        final desc = font['desc']!;
        final isSel = _selectedFont == key;
        final previewStyle = _getPreviewTextStyle(key);

        return GestureDetector(
          onTap: () {
            setState(() => _selectedFont = key);
            widget.onFontSelected(key);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSel ? AppColors.primary.withOpacity(0.14) : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSel ? AppColors.primary : Colors.white.withOpacity(0.06),
                width: isSel ? 1.6 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isSel ? AppColors.primary : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isSel)
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 10),
                // Live Font Sample Preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Rollin with my team, neon glowing bright',
                    style: previewStyle.copyWith(
                      color: isSel ? AppColors.primary : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 3: ANIMATION SELECTION
  Widget _buildAnimationTab() {
    return ListView.builder(
      key: const ValueKey('anim_tab'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: _animations.length,
      itemBuilder: (context, index) {
        final anim = _animations[index];
        final key = anim['key']!;
        final name = anim['name']!;
        final desc = anim['desc']!;
        final isSel = _selectedAnim == key;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedAnim = key);
            widget.onAnimationSelected(key);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSel ? AppColors.primary.withOpacity(0.14) : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSel ? AppColors.primary : Colors.white.withOpacity(0.06),
                width: isSel ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getAnimationIcon(key),
                    color: isSel ? Colors.black : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: isSel ? AppColors.primary : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                if (isSel)
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getAnimationIcon(String key) {
    switch (key) {
      case 'karaoke':
        return Icons.flare_rounded;
      case 'apple':
        return Icons.blur_linear_rounded;
      case 'wave':
        return Icons.waves_rounded;
      case 'neon':
        return Icons.crop_portrait_rounded;
      case 'minimal':
      default:
        return Icons.music_note_rounded;
    }
  }
}
