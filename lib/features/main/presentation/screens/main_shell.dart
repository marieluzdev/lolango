import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/network/connectivity_provider.dart';
import 'package:lolango_v2/core/network/network_aware_provider.dart';
import 'package:lolango_v2/core/utils/logger.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/discovery/presentation/screens/discovery_screen.dart';
import 'package:lolango_v2/features/home/presentation/screens/home_screen.dart';
import 'package:lolango_v2/features/match/presentation/screens/match_screen.dart';
import 'package:lolango_v2/features/profile/presentation/screens/profile_screen.dart';
import 'package:lolango_v2/features/messaging/presentation/screens/conversations_screen.dart';
import 'package:lolango_v2/features/match/presentation/providers/interaction_providers.dart';
import 'package:lolango_v2/features/social_access/presentation/screens/privacy_modal_screen.dart';
import 'package:lolango_v2/features/social_access/providers/social_visibility_provider.dart';

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
    ConversationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeSubscriptions();
      _checkPrivacyModal();
      // Écoute la reconnexion réseau pour réinitialiser les canaux Realtime
      ref.listenManual<bool>(isConnectedProvider, (previous, current) {
        if (previous == false && current == true && mounted) {
          AppLogger.d('[REALTIME] Network restored → re-subscribing Realtime channels.');
          _teardownRealtimeSubscriptions();
          _setupRealtimeSubscriptions();
        }
      });
    });
  }

  Future<void> _checkPrivacyModal() async {
    AppLogger.d('[PRIVACY] _checkPrivacyModal started.');
    try {
      final hasSeen = await ref.read(hasSeenPrivacyModalProvider.future);
      AppLogger.d('[PRIVACY] hasSeenPrivacyModalProvider returned: $hasSeen');
      AppLogger.d('[PRIVACY] Is widget mounted? $mounted');
      
      if (!hasSeen && mounted) {
        AppLogger.d('[PRIVACY] Showing PrivacyModalScreen now.');
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (_) => ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: const PrivacyModalScreen(),
          ),
        );
      } else {
        AppLogger.d('[PRIVACY] Not showing PrivacyModalScreen (hasSeen: $hasSeen, mounted: $mounted).');
      }
    } catch (e) {
      AppLogger.e('[PRIVACY] Error in _checkPrivacyModal: $e');
    }
  }

  void _setupRealtimeSubscriptions() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.d('[REALTIME] No user, skipping subscriptions.');
      return;
    }
    AppLogger.d('[REALTIME] Setting up subscriptions for $userId');

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
            AppLogger.d(
              '[REALTIME] New notification received! Incrementing badge.',
            );
            ref.read(matchNotificationBadgeProvider.notifier).state++;
          },
        )
        .subscribe((status, error) {
          AppLogger.d(
            '[REALTIME] notifications channel status: $status, error: $error',
          );
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
            AppLogger.d(
              '[REALTIME] Someone liked me! Refreshing pending likes.',
            );
            ref.invalidate(pendingLikesProvider);
          },
        )
        .subscribe((status, error) {
          AppLogger.d(
            '[REALTIME] interactions channel status: $status, error: $error',
          );
        });

    // 3. Nouveau match → rafraîchir l'onglet Matchs
    _matchesChannel = Supabase.instance.client
        .channel('matches:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'matches',
          callback: (payload) {
            AppLogger.d('[REALTIME] New match! Refreshing matches.');
            ref.invalidate(matchesProvider);
            ref.invalidate(pendingLikesProvider);
          },
        )
        .subscribe((status, error) {
          AppLogger.d(
            '[REALTIME] matches channel status: $status, error: $error',
          );
        });
  }

  void _teardownRealtimeSubscriptions() {
    _notificationsChannel?.unsubscribe();
    _interactionsChannel?.unsubscribe();
    _matchesChannel?.unsubscribe();
    _notificationsChannel = null;
    _interactionsChannel = null;
    _matchesChannel = null;
  }

  @override
  void dispose() {
    _teardownRealtimeSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Maintient le networkAwareProvider actif pour toute la session
    ref.watch(networkAwareProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    // Items de navigation (identiques à v1)
    final navItems = [
      const _NavItem(icon: LucideIcons.house, label: 'Home', index: 0),
      const _NavItem(icon: LucideIcons.compass, label: 'Découvrir', index: 1),
      const _NavItem(
        icon: LucideIcons.heart,
        label: 'Match',
        index: 2,
      ),
      const _NavItem(icon: LucideIcons.messageCircle, label: 'Messages', index: 3),
      const _NavItem(icon: LucideIcons.userRound, label: 'Profil', index: 4),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: ClipRect(
        child: Container(
          decoration: BoxDecoration(
            color: background,
          ),
          padding: EdgeInsets.only(
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: navItems.map((item) {
              final isSelected = _selectedIndex == item.index;

              final iconColor = isDark
                  ? (isSelected ? Colors.black : Colors.white)
                  : (isSelected ? Colors.white : Colors.black);

              Widget iconWidget = Icon(item.icon, size: 22, color: iconColor);

              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = item.index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 56,
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: iconWidget,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
