import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/audio_player_provider.dart';
import 'providers/music_library_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/saavn_api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ping JioSaavn Render service in background on launch to wake instance
  SaavnApiService.pingServer();

  // Check if first-time user
  bool isFirstTime = true;
  try {
    final prefs = await SharedPreferences.getInstance();
    isFirstTime = prefs.getBool('is_first_time_user') ?? true;
  } catch (e) {
    debugPrint('Error reading first-time user flag: $e');
  }

  // Set immersive dark system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(ExoticMusicApp(isFirstTime: isFirstTime));
}

class ExoticMusicApp extends StatelessWidget {
  final bool isFirstTime;
  const ExoticMusicApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
        ChangeNotifierProvider(create: (_) => MusicLibraryProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'EXOTIC MUSIC',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: isFirstTime ? const OnboardingScreen() : const MainNavigationScreen(),
      ),
    );
  }
}
