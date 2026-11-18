import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/song_model.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_library_provider.dart';
import '../services/lyrics_translation_service.dart';
import '../theme/app_colors.dart';
import '../widgets/equalizer_sheet.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/device_picker_sheet.dart';
import '../widgets/lyrics_studio_sheet.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  int _selectedTab = 0; // 0 = Cover, 1 = Lyrics
  final ScrollController _lyricsScrollController = ScrollController();
  int _lastActiveLyricIndex = -1;

  // Real-time Lyrics Customization & Translation State
  String _targetLyricLanguage = 'original';
  String _lyricFont = 'outfit';
  String _lyricAnimation = 'karaoke';
  bool _isTranslatingLyrics = false;
  List<LyricLine>? _translatedLyrics;
  String? _lastTranslatedSongId;

  @override
  void initState() {
    super.initState();
    _loadLyricsPreferences();
  }

  Future<void> _loadLyricsPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _targetLyricLanguage = prefs.getString('lyrics_target_language') ?? 'original';
        _lyricFont = prefs.getString('lyrics_font_style') ?? 'outfit';
        _lyricAnimation = prefs.getString('lyrics_animation_style') ?? 'karaoke';
      });
    }
  }

  Future<void> _translateCurrentLyrics(Song song, List<LyricLine> original) async {
    if (_targetLyricLanguage == 'original') {
      if (mounted) {
        setState(() {
          _translatedLyrics = null;
          _isTranslatingLyrics = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isTranslatingLyrics = true);

    try {
      final translated = await LyricsTranslationService.translateLyrics(
        songId: song.id,
        originalLyrics: original,
        targetLangCode: _targetLyricLanguage,
      );

      if (mounted) {
        setState(() {
          _translatedLyrics = translated;
          _lastTranslatedSongId = song.id;
          _isTranslatingLyrics = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isTranslatingLyrics = false);
    }
  }

  void _openLyricsStudioSheet(Song song, List<LyricLine> originalLyrics) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LyricsStudioSheet(
        currentLanguage: _targetLyricLanguage,
        currentFont: _lyricFont,
        currentAnimation: _lyricAnimation,
        onLanguageSelected: (newLang) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lyrics_target_language', newLang);
          if (mounted) setState(() => _targetLyricLanguage = newLang);
          _translateCurrentLyrics(song, originalLyrics);
        },
        onFontSelected: (newFont) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lyrics_font_style', newFont);
          if (mounted) setState(() => _lyricFont = newFont);
        },
        onAnimationSelected: (newAnim) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lyrics_animation_style', newAnim);
          if (mounted) setState(() => _lyricAnimation = newAnim);
        },
      ),
    );
  }

  TextStyle _getLyricBaseStyle(String fontKey) {
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

  String _getLanguageBadgeLabel() {
    final match = LyricsTranslationService.supportedLanguages.firstWhere(
      (l) => l['code'] == _targetLyricLanguage,
      orElse: () => {'code': 'original', 'name': 'Original', 'native': 'Original', 'flag': '🎵'},
    );
    return '${match['flag']} ${match['name']}';
  }

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final currentSong = playerProvider.currentSong;

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: Text('No song selected', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF282828),
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        const Text(
                          'PLAYING FROM PLAYLIST',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentSong.album,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.equalizer, color: AppColors.primary, size: 24),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const EqualizerSheet(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // View Selector (Cover / Lyrics)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Canvas', style: TextStyle(color: _selectedTab == 0 ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Lyrics', style: TextStyle(color: _selectedTab == 1 ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Main Artwork OR Lyrics
              Expanded(
                child: _selectedTab == 0
                    ? _buildCoverArtView(currentSong)
                    : _buildLyricsView(currentSong, playerProvider),
              ),

              const SizedBox(height: 12),

              // Song Info Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentSong.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        currentSong.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: currentSong.isLiked ? AppColors.primary : AppColors.textMuted,
                        size: 28,
                      ),
                      onPressed: () {
                        libraryProvider.toggleLikeSong(currentSong);
                      },
                    ),
                  ],
                ),
              ),

              // Audio Seek Slider & Timestamps
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: playerProvider.position.inMilliseconds.toDouble().clamp(0.0, playerProvider.duration.inMilliseconds.toDouble()),
                        min: 0.0,
                        max: playerProvider.duration.inMilliseconds > 0
                            ? playerProvider.duration.inMilliseconds.toDouble()
                            : 1.0,
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.white24,
                        onChanged: (value) {
                          playerProvider.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playerProvider.position),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          Text(
                            _formatDuration(playerProvider.duration),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Audio Player Controls (Vibrant Orange Play Circle)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: playerProvider.isShuffle ? AppColors.primary : AppColors.textSecondary,
                        size: 24,
                      ),
                      onPressed: () => playerProvider.toggleShuffle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: AppColors.textPrimary, size: 36),
                      onPressed: () => playerProvider.playPrevious(),
                    ),
                    // Main Play/Pause Button (Vibrant Orange)
                    GestureDetector(
                      onTap: () => playerProvider.togglePlayPause(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: playerProvider.isLoading
                              ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 3)
                              : Icon(
                                  playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.black,
                                  size: 38,
                                ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: AppColors.textPrimary, size: 36),
                      onPressed: () => playerProvider.playNext(),
                    ),
                    IconButton(
                      icon: Icon(
                        playerProvider.loopState == LoopState.loopOne
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: playerProvider.loopState != LoopState.off ? AppColors.primary : AppColors.textSecondary,
                        size: 24,
                      ),
                      onPressed: () => playerProvider.toggleLoop(),
                    ),
                  ],
                ),
              ),

              // Bottom Actions (Devices & Queue)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.devices, color: AppColors.primary, size: 22),
                      tooltip: 'Exotic Connect',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const DevicePickerSheet(),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.queue_music, color: AppColors.textSecondary, size: 22),
                      tooltip: 'Up Next Queue',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const QueueSheet(),
                        );
                      },
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

  Widget _buildCoverArtView(Song song) {
    return Center(
      child: Hero(
        tag: 'now_playing_art_${song.id}',
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Image.network(
                song.coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsView(Song song, AudioPlayerProvider provider) {
    if (provider.isLoadingLyrics) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text(
              'Fetching synchronized lyrics...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final rawLyrics = provider.currentLyrics.isNotEmpty ? provider.currentLyrics : song.lyrics;

    if (rawLyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.lyrics_outlined, color: AppColors.textMuted, size: 48),
            SizedBox(height: 12),
            Text(
              'No lyrics found for this track',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Enjoy your favorite music',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Auto-trigger translation if target language is selected and track changed
    if (_targetLyricLanguage != 'original' && _lastTranslatedSongId != song.id && !_isTranslatingLyrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _translateCurrentLyrics(song, rawLyrics);
      });
    }

    final lyrics = (_targetLyricLanguage != 'original' && _translatedLyrics != null)
        ? _translatedLyrics!
        : rawLyrics;

    // Auto-scroll to current active lyric line (centered in viewport)
    final currentLineIndex = lyrics.indexWhere((line) {
      final idx = lyrics.indexOf(line);
      return provider.position >= line.timestamp &&
          (idx == lyrics.length - 1 || provider.position < lyrics[idx + 1].timestamp);
    });

    if (currentLineIndex != -1 && currentLineIndex != _lastActiveLyricIndex && _lyricsScrollController.hasClients) {
      _lastActiveLyricIndex = currentLineIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_lyricsScrollController.hasClients) {
          final viewportHeight = _lyricsScrollController.position.viewportDimension;
          final targetOffset = (currentLineIndex * 64.0) - (viewportHeight / 2) + 32.0;
          final clamped = targetOffset.clamp(0.0, _lyricsScrollController.position.maxScrollExtent);
          _lyricsScrollController.animateTo(
            clamped,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    final baseStyle = _getLyricBaseStyle(_lyricFont);

    return GestureDetector(
      onLongPress: () => _openLyricsStudioSheet(song, rawLyrics),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            // Top Action Bar: Hold 3s hint + Live Language & Studio Badge
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app_outlined, size: 13, color: AppColors.primary.withOpacity(0.85)),
                      const SizedBox(width: 4),
                      const Text(
                        'Hold 3s to customize / translate',
                        style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _openLyricsStudioSheet(song, rawLyrics),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isTranslatingLyrics) ...[
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                            ),
                            const SizedBox(width: 6),
                          ] else ...[
                            const Icon(Icons.translate_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            _isTranslatingLyrics ? 'Translating...' : _getLanguageBadgeLabel(),
                            style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.tune_rounded, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.06), height: 1),
            const SizedBox(height: 6),

            // Lyrics List with Dynamic Animation & Font
            Expanded(
              child: ListView.builder(
                controller: _lyricsScrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: lyrics.length,
                itemBuilder: (context, index) {
                  final line = lyrics[index];
                  final isCurrentLine = (index == currentLineIndex);

                  return GestureDetector(
                    onTap: () => provider.seek(line.timestamp),
                    onLongPress: () => _openLyricsStudioSheet(song, rawLyrics),
                    child: _buildLyricAnimatedLine(line, isCurrentLine, baseStyle),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricAnimatedLine(LyricLine line, bool isCurrentLine, TextStyle baseStyle) {
    switch (_lyricAnimation) {
      case 'apple':
        return AnimatedScale(
          scale: isCurrentLine ? 1.15 : 0.96,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: isCurrentLine ? 1.0 : 0.35,
            duration: const Duration(milliseconds: 250),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: isCurrentLine ? Colors.white.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                style: baseStyle.copyWith(
                  fontSize: isCurrentLine ? 21 : 15,
                  fontWeight: isCurrentLine ? FontWeight.w900 : FontWeight.w600,
                  color: isCurrentLine ? Colors.white : Colors.white60,
                  height: 1.35,
                ),
              ),
            ),
          ),
        );

      case 'wave':
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            gradient: isCurrentLine
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.28),
                      Colors.orangeAccent.withOpacity(0.12),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            border: isCurrentLine ? Border.all(color: AppColors.primary.withOpacity(0.5)) : null,
          ),
          child: Text(
            line.text,
            textAlign: TextAlign.center,
            style: baseStyle.copyWith(
              fontSize: isCurrentLine ? 20 : 15,
              fontWeight: isCurrentLine ? FontWeight.w900 : FontWeight.w500,
              color: isCurrentLine ? AppColors.primary : const Color(0xFF999999),
              height: 1.35,
            ),
          ),
        );

      case 'neon':
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isCurrentLine ? const Color(0xFF1E1408) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrentLine ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isCurrentLine
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCurrentLine) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  line.text,
                  textAlign: TextAlign.center,
                  style: baseStyle.copyWith(
                    fontSize: isCurrentLine ? 19 : 15,
                    fontWeight: isCurrentLine ? FontWeight.w900 : FontWeight.w500,
                    color: isCurrentLine ? AppColors.primary : const Color(0xFF888888),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'minimal':
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isCurrentLine ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            line.text,
            textAlign: TextAlign.center,
            style: baseStyle.copyWith(
              fontSize: isCurrentLine ? 19 : 15,
              fontWeight: isCurrentLine ? FontWeight.w900 : FontWeight.w500,
              color: isCurrentLine ? AppColors.primary : const Color(0xFF888888),
              height: 1.35,
            ),
          ),
        );

      case 'karaoke':
      default:
        return AnimatedScale(
          scale: isCurrentLine ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 260),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentLine ? AppColors.primary.withOpacity(0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isCurrentLine
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Text(
              line.text,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(
                fontSize: isCurrentLine ? 20 : 15,
                fontWeight: isCurrentLine ? FontWeight.w900 : FontWeight.w500,
                color: isCurrentLine ? AppColors.primary : const Color(0xFF888888),
                height: 1.35,
              ),
            ),
          ),
        );
    }
  }
}
