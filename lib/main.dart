import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'screens/activity_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();

  final isDarkMode = preferences.getBool('dark_mode') ?? false;

  runApp(FitnessTrackerApp(initialDarkMode: isDarkMode));
}

class FitnessTrackerApp extends StatefulWidget {
  final bool initialDarkMode;

  const FitnessTrackerApp({super.key, required this.initialDarkMode});

  @override
  State<FitnessTrackerApp> createState() => _FitnessTrackerAppState();
}

class _FitnessTrackerAppState extends State<FitnessTrackerApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();

    _isDarkMode = widget.initialDarkMode;
  }

  Future<void> _changeTheme(bool value) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool('dark_mode', value);

    if (!mounted) return;

    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Fitness Tracker',

      theme: AppTheme.lightTheme,

      darkTheme: AppTheme.darkTheme,

      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: SplashScreen(
        nextScreen: MainNavigationScreen(
          isDarkMode: _isDarkMode,
          onThemeChanged: _changeTheme,
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const MainNavigationScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const ProgressScreen(),
      const ActivityScreen(),
      SettingsScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),

          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Activity',
          ),

          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
