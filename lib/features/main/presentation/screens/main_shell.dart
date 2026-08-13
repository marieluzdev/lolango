import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/discovery/presentation/screens/discovery_screen.dart';
import 'package:lolango_v2/features/home/presentation/screens/home_screen.dart';
import 'package:lolango_v2/features/match/presentation/screens/match_screen.dart';
import 'package:lolango_v2/features/profile/presentation/screens/profile_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DiscoveryScreen(),
    MatchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBackground = isDark ? AppColors.navbarDark : AppColors.navbarLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: navBackground,
        elevation: 0,
        height: 72,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        indicatorColor: isDark
            ? AppColors.primaryDark.withValues(alpha: 0.18)
            : AppColors.primaryLight.withValues(alpha: 0.20),
        destinations: [
          NavigationDestination(
            icon: Icon(LucideIcons.house, color: textSecondary),
            selectedIcon: Icon(LucideIcons.house, color: AppColors.primaryLight),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.search, color: textSecondary),
            selectedIcon: Icon(LucideIcons.search, color: AppColors.primaryLight),
            label: 'Découvrir',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.heart, color: textSecondary),
            selectedIcon: Icon(LucideIcons.heart, color: AppColors.primaryLight),
            label: 'Match',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.userRound, color: textSecondary),
            selectedIcon: Icon(LucideIcons.userRound, color: AppColors.primaryLight),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
