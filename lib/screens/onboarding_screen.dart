import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isResetMode;
  const OnboardingScreen({super.key, this.isResetMode = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  // Form State
  final TextEditingController _emailController = TextEditingController(text: 'exoticmusic@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: 'exotic@2026');
  final TextEditingController _nameController = TextEditingController(text: 'Exoticmusic');
  final TextEditingController _artistSearchController = TextEditingController();

  bool _obscurePassword = true;
  int _selectedDay = 17;
  int _selectedMonth = 11;
  int _selectedYear = 2000;
  String _selectedGender = 'Male';

  bool _optOutMarketing = true;
  bool _shareData = true;

  // Selected Languages (Pre-select Punjabi & International as in video)
  final Set<String> _selectedLanguages = {'Punjabi', 'International'};

  // Selected Artists
  final Set<String> _selectedArtists = {'The Weeknd', 'Diljit Dosanjh', 'Karan Aujla'};

  String _artistCategoryFilter = 'For You';

  // Language Cards Data (with background colors and artist cut-out photos)
  final List<Map<String, dynamic>> _languages = [
    {
      'name': 'Hindi',
      'color': Color(0xFFE91429),
      'image': 'https://c.saavncdn.com/artists/Arijit_Singh_002_20260925061936_500x500.jpg',
    },
    {
      'name': 'International',
      'color': Color(0xFFE8630A),
      'image': 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400',
    },
    {
      'name': 'Punjabi',
      'color': Color(0xFFB02897),
      'image': 'https://c.saavncdn.com/artists/Diljit_Dosanjh_004_20260925061936_500x500.jpg',
    },
    {
      'name': 'Tamil',
      'color': Color(0xFFC39600),
      'image': 'https://c.saavncdn.com/artists/Anirudh_Ravichander_004_20260925061936_500x500.jpg',
    },
    {
      'name': 'Telugu',
      'color': Color(0xFF1E88E5),
      'image': 'https://c.saavncdn.com/artists/Sid_Sriram_003_20260925061936_500x500.jpg',
    },
    {
      'name': 'Malayalam',
      'color': Color(0xFF00897B),
      'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400',
    },
    {
      'name': 'Marathi',
      'color': Color(0xFF8D6E63),
      'image': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=400',
    },
    {
      'name': 'Gujarati',
      'color': Color(0xFFD81B60),
      'image': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=400',
    },
    {
      'name': 'Bengali',
      'color': Color(0xFF3949AB),
      'image': 'https://c.saavncdn.com/artists/Shreya_Ghoshal_004_20260925061936_500x500.jpg',
    },
    {
      'name': 'Kannada',
      'color': Color(0xFF7CB342),
      'image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400',
    },
    {
      'name': 'Haryanvi',
      'color': Color(0xFF6A1B9A),
      'image': 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=400',
    },
    {
      'name': 'Bhojpuri',
      'color': Color(0xFFF57C00),
      'image': 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?q=80&w=400',
    },
  ];

  // Artists Data with Category Tags
  final List<Map<String, String>> _allArtists = [
    {
      'name': 'Karan Aujla',
      'category': 'Punjabi',
      'image': 'https://c.saavncdn.com/artists/Karan_Aujla_005_20260925061936_500x500.jpg',
    },
    {
      'name': 'Taylor Swift',
      'category': 'International',
      'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400',
    },
    {
      'name': 'The Weeknd',
      'category': 'International',
      'image': 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400',
    },
    {
      'name': 'Diljit Dosanjh',
      'category': 'Punjabi',
      'image': 'https://c.saavncdn.com/artists/Diljit_Dosanjh_004_20260925061936_500x500.jpg',
    },
    {
      'name': 'Sidhu Moose Wala',
      'category': 'Punjabi',
      'image': 'https://c.saavncdn.com/artists/Sidhu_Moose_Wala_003_20260925061936_500x500.jpg',
    },
    {
      'name': 'BTS',
      'category': 'International',
      'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400',
    },
    {
      'name': 'Arijit Singh',
      'category': 'Hindi',
      'image': 'https://c.saavncdn.com/artists/Arijit_Singh_002_20260925061936_500x500.jpg',
    },
    {
      'name': 'Guru Randhawa',
      'category': 'Punjabi',
      'image': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=400',
    },
    {
      'name': 'Ed Sheeran',
      'category': 'International',
      'image': 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=400',
    },
    {
      'name': 'Drake',
      'category': 'International',
      'image': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=400',
    },
    {
      'name': 'Tame Impala',
      'category': 'International',
      'image': 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?q=80&w=400',
    },
    {
      'name': 'Amrinder Gill',
      'category': 'Punjabi',
      'image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400',
    },
    {
      'name': 'Justin Bieber',
      'category': 'International',
      'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400',
    },
    {
      'name': 'Shubh',
      'category': 'Punjabi',
      'image': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=400',
    },
    {
      'name': 'Yo Yo Honey Singh',
      'category': 'Punjabi',
      'image': 'https://c.saavncdn.com/artists/Yo_Yo_Honey_Singh_002_20260925061936_500x500.jpg',
    },
    {
      'name': 'Badshah',
      'category': 'Hindi',
      'image': 'https://c.saavncdn.com/artists/Badshah_005_20260925061936_500x500.jpg',
    },
    {
      'name': 'Divine',
      'category': 'Hindi',
      'image': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=400',
    },
    {
      'name': 'Rihanna',
      'category': 'International',
      'image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400',
    },
    {
      'name': 'Katy Perry',
      'category': 'International',
      'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400',
    },
    {
      'name': 'Beyoncé',
      'category': 'International',
      'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400',
    },
    {
      'name': 'Gippy Grewal',
      'category': 'Punjabi',
      'image': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=400',
    },
    {
      'name': 'Sunanda Sharma',
      'category': 'Punjabi',
      'image': 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=400',
    },
  ];

  @override
  void initState() {
    super.initState();
    // If in reset mode from Settings, start at language selection (Page 7)
    final initialPage = widget.isResetMode ? 7 : 0;
    _currentPage = initialPage;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _artistSearchController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 10) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time_user', false);
    await prefs.setStringList('user_preferred_languages', _selectedLanguages.toList());
    await prefs.setStringList('user_preferred_artists', _selectedArtists.toList());
    await prefs.setString('user_username', _nameController.text.trim());
    await prefs.setString('user_email', _emailController.text.trim());

    if (!mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.updateProfile(
      username: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (widget.isResetMode) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Music taste and preferences updated successfully!')),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Controlled via buttons
          onPageChanged: (page) => setState(() => _currentPage = page),
          children: [
            _buildPage0Landing(),
            _buildPage1Email(),
            _buildPage2Password(),
            _buildPage3BirthDate(),
            _buildPage4Gender(),
            _buildPage5Name(),
            _buildPage6LoadingDots(),
            _buildPage7Notifications(),
            _buildPage8Languages(),
            _buildPage9Artists(),
            _buildPage10GreatPicks(),
            _buildPage11VipOffer(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // PAGE 0: LANDING WELCOME SCREEN (Video Frame 00:00)
  // =========================================================================
  Widget _buildPage0Landing() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const Spacer(),
          // App Logo
          Image.asset(
            'assets/images/app_logo.png',
            width: 72,
            height: 72,
            errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: AppColors.primary, size: 72),
          ),
          const SizedBox(height: 32),
          const Text(
            'Millions of songs.\nFree on EXOTIC.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const Spacer(),

          // Primary Orange Button: Sign up for free
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _nextPage,
              child: const Text('Sign up for free', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),

          // Continue with phone number
          _buildOutlinedButton(
            icon: Icons.phone_android,
            text: 'Continue with phone number',
            onTap: _nextPage,
          ),
          const SizedBox(height: 12),

          // Continue with Google
          _buildOutlinedButton(
            icon: Icons.g_mobiledata,
            text: 'Continue with Google',
            onTap: _nextPage,
          ),
          const SizedBox(height: 24),

          // Log in Text
          GestureDetector(
            onTap: _completeOnboarding,
            child: const Text(
              'Log in',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 1: CREATE ACCOUNT - EMAIL (Video Frame 00:01 - 00:18)
  // =========================================================================
  Widget _buildPage1Email() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Create account'),
          const SizedBox(height: 24),
          const Text(
            "What's your email address?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            "You'll need to confirm this email later.",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('name@domain.com'),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _nextPage,
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 32),
          const Center(
            child: Text('Or sign up with', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 18),

          _buildOutlinedButton(icon: Icons.phone_android, text: 'Phone number', onTap: _nextPage),
          const SizedBox(height: 12),
          _buildOutlinedButton(icon: Icons.g_mobiledata, text: 'Google', onTap: _nextPage),
          const Spacer(),

          Center(
            child: GestureDetector(
              onTap: _completeOnboarding,
              child: const Text(
                'Already have an account? Log in',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 2: CREATE A PASSWORD (Video Frame 00:19 - 00:28)
  // =========================================================================
  Widget _buildPage2Password() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Create account'),
          const SizedBox(height: 24),
          const Text(
            'Create a password',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use at least 10 characters.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: _inputDecoration('Password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Center(
            child: SizedBox(
              width: 140,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: _nextPage,
                child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 3: WHAT'S YOUR DATE OF BIRTH? (Video Frame 00:29 - 00:35)
  // =========================================================================
  Widget _buildPage3BirthDate() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Create account'),
          const SizedBox(height: 24),
          const Text(
            "What's your date of birth?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 40),

          // 3-Wheel Date Picker
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Day
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: _selectedDay - 1),
                    itemExtent: 44,
                    onSelectedItemChanged: (index) => setState(() => _selectedDay = index + 1),
                    children: List.generate(31, (i) => Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 20)))),
                  ),
                ),
                // Month
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: _selectedMonth - 1),
                    itemExtent: 44,
                    onSelectedItemChanged: (index) => setState(() => _selectedMonth = index + 1),
                    children: const [
                      Center(child: Text('Jan', style: TextStyle(color: Colors.white, fontSize: 20))),
                      Center(child: Text('Feb', style: TextStyle(color: Colors.white, fontSize: 20))),
                      Center(child: Text('Mar', style: TextStyle(color: Colors.white, fontSize: 20))),
                      Center(child: Text('Apr', style: TextStyle(color: Colors.white, fontSize: 20))),
                      Center(child: Text('May', style: TextStyle(color: Colors.white, fontSize: 20))),
                      Center(child: Text('Jun', style: TextStyle(color: Colors.white, fontSize: 20))),
                      Center(child: Text('Jul', style: TextStyle(color: Colors.white, fontSize: 20))),
                      Center(child: Text('Aug', style: TextStyle(color: Colors.white, fontSize: 20))),
                      Center(child: Text('Sept', style: TextStyle(color: Colors.white, fontSize: 20))),
                      Center(child: Text('Oct', style: TextStyle(color: Colors.white, fontSize: 20))),
                      Center(child: Text('Nov', style: TextStyle(color: Colors.white, fontSize: 20))),
                      Center(child: Text('Dec', style: TextStyle(color: Colors.white, fontSize: 20))),
                    ],
                  ),
                ),
                // Year
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: 2010 - 1970),
                    itemExtent: 44,
                    onSelectedItemChanged: (index) => setState(() => _selectedYear = 1970 + index),
                    children: List.generate(45, (i) => Center(child: Text('${1970 + i}', style: const TextStyle(color: Colors.white, fontSize: 20)))),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          Center(
            child: SizedBox(
              width: 140,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: _nextPage,
                child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 4: WHAT'S YOUR GENDER? (Video Frame 00:36 - 00:37)
  // =========================================================================
  Widget _buildPage4Gender() {
    final genders = ['Female', 'Male', 'Non-binary', 'Other', 'Prefer not to say'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Create account'),
          const SizedBox(height: 24),
          const Text(
            "What's your gender?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 24),

          Wrap(
            spacing: 12,
            runSpacing: 14,
            children: genders.map((g) {
              final isSel = _selectedGender == g;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedGender = g);
                  Future.delayed(const Duration(milliseconds: 200), _nextPage);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isSel ? AppColors.primary : Colors.white24),
                  ),
                  child: Text(
                    g,
                    style: TextStyle(
                      color: isSel ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 5: WHAT'S YOUR NAME? (Video Frame 00:38 - 00:46)
  // =========================================================================
  Widget _buildPage5Name() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Create account'),
          const SizedBox(height: 24),
          const Text(
            "What's your name?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: _inputDecoration('Your name'),
          ),
          const SizedBox(height: 8),
          const Text(
            'This appears on your EXOTIC profile.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 24),
          const Text(
            'By tapping "Create account", you agree to the EXOTIC MUSIC Terms of Use and Privacy Policy.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),

          // Checkboxes
          _buildCheckbox(
            value: _optOutMarketing,
            text: 'I would prefer not to receive marketing emails from EXOTIC.',
            onChanged: (val) => setState(() => _optOutMarketing = val),
          ),
          const SizedBox(height: 14),
          _buildCheckbox(
            value: _shareData,
            text: "Share my registration data with EXOTIC's content providers for marketing purposes.",
            onChanged: (val) => setState(() => _shareData = val),
          ),

          const Spacer(),
          Center(
            child: SizedBox(
              width: 180,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  _nextPage();
                  // Trigger pulse loading then auto advance
                  Timer(const Duration(milliseconds: 1400), _nextPage);
                },
                child: const Text('Create account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 6: LOADING PULSE SCREEN (Video Frame 00:47 - 00:54)
  // =========================================================================
  Widget _buildPage6LoadingDots() {
    return const Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulsingDot(delay: 0),
          SizedBox(width: 10),
          _PulsingDot(delay: 200),
          SizedBox(width: 10),
          _PulsingDot(delay: 400),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 7: TURN ON NOTIFICATIONS (Video Frame 00:55 - 00:57)
  // =========================================================================
  Widget _buildPage7Notifications() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 110,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Center(
              child: Icon(Icons.notifications_active, color: AppColors.primary, size: 36),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Turn on notifications',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'Get updates about new music, special offers, events and more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const Spacer(),

          SizedBox(
            width: 220,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: _nextPage,
              child: const Text('Turn on notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 14),

          GestureDetector(
            onTap: _nextPage,
            child: const Text(
              'Not now',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Manage your notification categories in Settings at any time.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 8: WHAT MUSIC DO YOU LIKE? (Video Frame 00:58 - 01:05)
  // =========================================================================
  Widget _buildPage8Languages() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What music do you\nlike?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 16),

          // 2-Column colorful grid of languages matching Video Frame 00:59
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final item = _languages[index];
                final String name = item['name'];
                final Color cardColor = item['color'];
                final String imgUrl = item['image'];
                final isSelected = _selectedLanguages.contains(name);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedLanguages.remove(name);
                      } else {
                        _selectedLanguages.add(name);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Language Title on top left
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        // Artist Cut-out Image on bottom right (tilted slightly)
                        Positioned(
                          right: -10,
                          bottom: -10,
                          width: 80,
                          height: 80,
                          child: Transform.rotate(
                            angle: 0.15,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white30),
                              ),
                            ),
                          ),
                        ),

                        // Checkmark Badge if selected
                        if (isSelected)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(Icons.check, color: Colors.black, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Next Button
          Center(
            child: SizedBox(
              width: 140,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: _selectedLanguages.isNotEmpty ? _nextPage : null,
                child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 9: CHOOSE 3 OR MORE ARTISTS (Video Frame 01:06 - 01:19)
  // =========================================================================
  Widget _buildPage9Artists() {
    final query = _artistSearchController.text.toLowerCase().trim();
    final filtered = _allArtists.where((a) {
      final matchesSearch = query.isEmpty || a['name']!.toLowerCase().contains(query);
      final matchesCategory = (_artistCategoryFilter == 'For You') ||
          (a['category']?.toLowerCase() == _artistCategoryFilter.toLowerCase());
      return matchesSearch && matchesCategory;
    }).toList();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose 3 or more\nartists you like.',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
              ),
              const SizedBox(height: 14),

              // Search Bar matching Video Frame 01:06
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _artistSearchController,
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.black54, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.black87),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category Filter Chips: For You, International, Punjabi, etc.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildArtistCategoryChip('For You'),
                    const SizedBox(width: 8),
                    _buildArtistCategoryChip('International'),
                    const SizedBox(width: 8),
                    _buildArtistCategoryChip('Punjabi'),
                    const SizedBox(width: 8),
                    _buildArtistCategoryChip('Hindi'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3-Column Round Artist Avatars Grid
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 90),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final name = item['name']!;
                    final img = item['image']!;
                    final isSel = _selectedArtists.contains(name);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSel) {
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
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: const Color(0xFF282828),
                                backgroundImage: NetworkImage(img),
                              ),
                              if (isSel)
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.black, size: 18),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Floating Bottom Pill: "X SELECTED" + "Done" (Video Frame 01:14 - 01:19)
        if (_selectedArtists.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_selectedArtists.length} SELECTED',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      ),
                      onPressed: () {
                        _nextPage();
                        // Trigger Great picks auto-transition
                        Timer(const Duration(milliseconds: 2400), _nextPage);
                      },
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // =========================================================================
  // PAGE 10: GREAT PICKS TRANSITION (Video Frame 01:20 - 01:23)
  // =========================================================================
  Widget _buildPage10GreatPicks() {
    final selList = _allArtists.where((a) => _selectedArtists.contains(a['name'])).take(5).toList();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Overlapping Avatars Row
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: selList.map((a) {
                return Align(
                  widthFactor: 0.65,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF121212), width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: NetworkImage(a['image']!),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Great picks!',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 20),

          // 3 Pulsing dots + "Finding music for you..."
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PulsingDot(delay: 0),
              SizedBox(width: 8),
              _PulsingDot(delay: 200),
              SizedBox(width: 8),
              _PulsingDot(delay: 400),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Finding music for you...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 11: VIP / REWARDS OFFER (Video Frame 01:24 - 01:27)
  // =========================================================================
  Widget _buildPage11VipOffer() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A0DAD), Color(0xFF121212)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.stars, color: AppColors.primary, size: 20),
              SizedBox(width: 6),
              Text('EXOTIC VIP • REWARDS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
            ],
          ),
          const Spacer(),

          const Text(
            'No gatekeeping,\nonly Rewards 🎁',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),

          // Gift / Trophy Box Graphic
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF28103A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: const Center(
              child: Icon(Icons.card_giftcard, color: AppColors.primary, size: 68),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "I know, we're nice. Now access unlimited lossless 320kbps streams, ad-free listening & offline downloads with VIP Rewards!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              onPressed: _completeOnboarding,
              child: const Text('EXPLORE NOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 14),

          GestureDetector(
            onTap: _completeOnboarding,
            child: const Text(
              'Dismiss',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================
  Widget _buildHeader(String title) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: _previousPage,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildOutlinedButton({required IconData icon, required String text, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 22), // Balances the icon width
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox({required bool value, required String text, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.primary : Colors.transparent,
              border: Border.all(color: value ? AppColors.primary : Colors.white38, width: 2),
            ),
            child: value ? const Icon(Icons.check, color: Colors.black, size: 14) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCategoryChip(String label) {
    final isSel = _artistCategoryFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _artistCategoryFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? AppColors.primary : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// Animated Pulsing Dot Widget for Spotify loading screen
class _PulsingDot extends StatefulWidget {
  final int delay;
  const _PulsingDot({required this.delay});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.2, end: 1.0).animate(_controller),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }
}
