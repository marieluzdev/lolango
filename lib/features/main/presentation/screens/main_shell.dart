import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/discovery/presentation/screens/discovery_screen.dart';
import 'package:lolango_v2/features/home/presentation/screens/home_screen.dart';
import 'package:lolango_v2/features/match/presentation/screens/match_screen.dart';
import 'package:lolango_v2/features/profile/presentation/screens/profile_screen.dart';
import 'package:lolango_v2/features/match/presentation/providers/interaction_providers.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _selectedIndex = 0;

  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _interactionsChannel;
  RealtimeChannel? _matchesChannel;

  final List<Widget> _screens = const [
    HomeScreen(),
    DiscoveryScreen(),
    MatchScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeSubscriptions();
    });
  }

  void _setupRealtimeSubscriptions() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[REALTIME] No user, skipping subscriptions.');
      return;
    }
    debugPrint('[REALTIME] Setting up subscriptions for $userId');

    // 1. Nouvelles notifications → badge +1
    _notificationsChannel = Supabase.instance.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('[REALTIME] New notification received! Incrementing badge.');
            ref.read(matchNotificationBadgeProvider.notifier).state++;
          },
        )
        .subscribe((status, error) {
          debugPrint('[REALTIME] notifications channel status: $status, error: $error');
        });

    // 2. Quelqu'un me like → rafraîchir "Likes reçus"
    _interactionsChannel = Supabase.instance.client
        .channel('interactions:target:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'interactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'target_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('[REALTIME] Someone liked me! Refreshing pending likes.');
            ref.invalidate(pendingLikesProvider);
          },
        )
        .subscribe((status, error) {
          debugPrint('[REALTIME] interactions channel status: $status, error: $error');
        });

    // 3. Nouveau match → rafraîchir l'onglet Matchs
    _matchesChannel = Supabase.instance.client
        .channel('matches:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'matches',
          callback: (payload) {
            debugPrint('[REALTIME] New match! Refreshing matches.');
            ref.invalidate(matchesProvider);
            ref.invalidate(pendingLikesProvider);
          },
        )
        .subscribe((status, error) {
          debugPrint('[REALTIME] matches channel status: $status, error: $error');
        });
  }

  @override
  void dispose() {
    _notificationsChannel?.unsubscribe();
    _interactionsChannel?.unsubscribe();
    _matchesChannel?.unsubscribe();
    super.dispose();
  }

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
            icon: Consumer(
              builder: (context, ref, child) {
                final badgeCount = ref.watch(matchNotificationBadgeProvider);
                if (badgeCount > 0) {
                  return Badge(
                    label: Text(badgeCount.toString()),
                    child: Icon(LucideIcons.heart, color: textSecondary),
                  );
                }
                return Icon(LucideIcons.heart, color: textSecondary);
              },
            ),
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
