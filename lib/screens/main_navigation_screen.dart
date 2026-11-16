import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/mini_player.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'premium_screen.dart';
import 'create_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    PremiumScreen(),
    CreateScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayer(),
                Container(
                  color: const Color(0xFF000000),
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    backgroundColor: Colors.transparent,
                    selectedItemColor: Colors.white,
                    unselectedItemColor: const Color(0xFFA7A7A7),
                    type: BottomNavigationBarType.fixed,
                    showUnselectedLabels: true,
                    selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        activeIcon: Icon(Icons.home_filled),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.search),
                        activeIcon: Icon(Icons.search),
                        label: 'Search',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.library_music_outlined),
                        activeIcon: Icon(Icons.library_music),
                        label: 'Your Library',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.workspace_premium_outlined),
                        activeIcon: Icon(Icons.workspace_premium),
                        label: 'Premium',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.add_circle_outline),
                        activeIcon: Icon(Icons.add_circle),
                        label: 'Create',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
