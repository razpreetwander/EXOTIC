import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isResetMode;
  const OnboardingScreen({super.key, this.isResetMode = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Selected Languages
  final Set<String> _selectedLanguages = {'Hindi', 'Punjabi', 'English'};

  // Selected Artists
  final Set<String> _selectedArtists = {'Karan Aujla', 'Diljit Dosanjh', 'Arijit Singh'};

  // Available Languages with Flags / Icons
  final List<Map<String, String>> _languages = [
    {'name': 'Hindi', 'native': 'हिन्दी', 'tag': 'Bollywood & Indie'},
    {'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'tag': 'Bhangra & Pop'},
    {'name': 'English', 'native': 'English', 'tag': 'Global Top Hits'},
    {'name': 'Haryanvi', 'native': 'हरियाणवी', 'tag': 'Desi Beats'},
    {'name': 'Bhojpuri', 'native': 'भोजपुरी', 'tag': 'Folk & Dance'},
    {'name': 'Tamil', 'native': 'தமிழ்', 'tag': 'Kollywood & Kuthu'},
    {'name': 'Telugu', 'native': 'తెలుగు', 'tag': 'Tollywood Melodies'},
    {'name': 'Rajasthani', 'native': 'राजस्थानी', 'tag': 'Traditional'},
    {'name': 'Urdu', 'native': 'اردو', 'tag': 'Ghazals & Sufi'},
    {'name': 'Bengali', 'native': 'বাংলা', 'tag': 'Rabindra & Modern'},
  ];

  // Available Artists with Real JioSaavn CDN & Unsplash Photos
  final List<Map<String, String>> _artists = [
    {
      'name': 'Karan Aujla',
      'role': 'Punjabi Pop & Hip-Hop',
      'image': 'https://c.saavncdn.com/artists/Karan_Aujla_005_20260925061936_500x500.jpg',
    },
    {
      'name': 'Diljit Dosanjh',
      'role': 'Global Punjabi Sensation',
      'image': 'https://c.saavncdn.com/artists/Diljit_Dosanjh_004_20260925061936_500x500.jpg',
    },
    {
      'name': 'Sidhu Moose Wala',
      'role': 'Punjabi Rap Legend',
      'image': 'https://c.saavncdn.com/artists/Sidhu_Moose_Wala_003_20260925061936_500x500.jpg',
    },
    {
      'name': 'Arijit Singh',
      'role': 'Soulful Bollywood Melodies',
      'image': 'https://c.saavncdn.com/artists/Arijit_Singh_002_20260925061936_500x500.jpg',
    },
    {
      'name': 'Shubh',
      'role': 'Modern Punjabi Wave',
      'image': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=400',
    },
    {
      'name': 'AP Dhillon',
      'role': 'Brown Munde & Synth',
      'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400',
    },
    {
      'name': 'Yo Yo Honey Singh',
      'role': 'Glory & Desi Kalakaar',
      'image': 'https://c.saavncdn.com/artists/Yo_Yo_Honey_Singh_002_20260925061936_500x500.jpg',
    },
    {
      'name': 'Badshah',
      'role': 'Commercial Rap & Dance',
      'image': 'https://c.saavncdn.com/artists/Badshah_005_20260925061936_500x500.jpg',
    },
    {
      'name': 'Divine',
      'role': 'Gully Gang Mumbai Rap',
      'image': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=400',
    },
    {
      'name': 'The Weeknd',
      'role': 'Synthwave & R&B King',
      'image': 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400',
    },
    {
      'name': 'Dua Lipa',
      'role': 'Future Nostalgia Pop',
      'image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400',
    },
    {
      'name': 'Justin Bieber',
      'role': 'International Pop Star',
      'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingPreferences();
  }

  Future<void> _loadExistingPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLangs = prefs.getStringList('user_preferred_languages');
    if (savedLangs != null && savedLangs.isNotEmpty) {
      setState(() {
        _selectedLanguages.clear();
        _selectedLanguages.addAll(savedLangs);
      });
    }

    final savedArtists = prefs.getStringList('user_preferred_artists');
    if (savedArtists != null && savedArtists.isNotEmpty) {
      setState(() {
        _selectedArtists.clear();
        _selectedArtists.addAll(savedArtists);
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time_user', false);
    await prefs.setStringList('user_preferred_languages', _selectedLanguages.toList());
    await prefs.setStringList('user_preferred_artists', _selectedArtists.toList());

    if (!mounted) return;

    if (widget.isResetMode) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Music preferences updated!')),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Progress Dots and Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step Indicator Dots
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Skip or Close Button
                  if (!widget.isResetMode && _currentPage < 2)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Skip', style: TextStyle(color: Colors.white60, fontSize: 14)),
                    )
                  else if (widget.isResetMode)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // Main PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildWelcomePage(),
                  _buildLanguagesPage(),
                  _buildArtistsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 1: WELCOME SCREEN (Branded Orange Logo & Highlights)
  // =========================================================================
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Main Logo with Glow
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primary,
                  child: const Icon(Icons.music_note, color: Colors.black, size: 70),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'EXOTIC MUSIC',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Millions of songs, podcasts & albums.\nStreamed in pristine 320kbps High Definition.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),

          const SizedBox(height: 36),

          // 3 Feature Badges
          _buildFeatureBadge(Icons.bolt, 'Real-time JioSaavn & Global Search Engine'),
          const SizedBox(height: 12),
          _buildFeatureBadge(Icons.headphones, 'Ultra HD 320kbps Lossless Audio Quality'),
          const SizedBox(height: 12),
          _buildFeatureBadge(Icons.equalizer, 'Custom 10-Band Graphic Equalizer'),

          const Spacer(),

          // Get Started Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 4,
              ),
              onPressed: _nextPage,
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 2: CHOOSE LANGUAGES
  // =========================================================================
  Widget _buildLanguagesPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'What languages do you listen to?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick your preferred languages to personalize your home feed and charts.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Grid of Languages
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final item = _languages[index];
                final name = item['name']!;
                final isSelected = _selectedLanguages.contains(name);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        if (_selectedLanguages.length > 1) {
                          _selectedLanguages.remove(name);
                        }
                      } else {
                        _selectedLanguages.add(name);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.18) : const Color(0xFF1E1F24),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.white12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['native']!,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              onPressed: _nextPage,
              child: Text(
                'Next (${_selectedLanguages.length} selected)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 3: CHOOSE ARTISTS
  // =========================================================================
  Widget _buildArtistsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Choose artists you love.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Select 3 or more artists. We will customize your live feed.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Artists Grid
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.82,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
              ),
              itemCount: _artists.length,
              itemBuilder: (context, index) {
                final artist = _artists[index];
                final name = artist['name']!;
                final isSelected = _selectedArtists.contains(name);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedArtists.remove(name);
                      } else {
                        _selectedArtists.add(name);
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                artist['image']!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF282828),
                                  child: const Icon(Icons.person, color: Colors.white54, size: 40),
                                ),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.black, size: 16),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Finish / Done Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedArtists.isNotEmpty ? AppColors.primary : Colors.white24,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              onPressed: _selectedArtists.isNotEmpty ? _completeOnboarding : null,
              child: Text(
                widget.isResetMode
                    ? 'Save Preferences'
                    : 'Start Listening (${_selectedArtists.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
