import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/notifications/push_notification_service.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _pushInitialized = false;

  Future<void> _initializePushNotifications(WidgetRef ref) async {
    try {
      await ref.read(pushNotificationServiceProvider).initialize();
      if (mounted) {
        setState(() {
          _pushInitialized = true;
        });
      }
    } catch (error) {
      debugPrint('[FCM] Échec initialisation : $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        ref.listen<AsyncValue<User?>>(authViewModelProvider, (previous, next) {
          final user = next.valueOrNull;
          if (user != null && !_pushInitialized) {
            _initializePushNotifications(ref);
          }
        });

        final router = ref.watch(appRouterProvider);
        final themeMode = ref.watch(themeModeProvider);

        return MaterialApp.router(
          title: 'Lolango_v2',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          routerConfig: router,
        );
      },
    );
  }
}
