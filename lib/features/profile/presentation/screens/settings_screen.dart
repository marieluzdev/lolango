import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/notifications/push_notification_service.dart';
import 'package:lolango_v2/core/theme/theme_mode_provider.dart';
import 'package:lolango_v2/core/widgets/confirmation_modal_bottom_sheet.dart';
import 'package:lolango_v2/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final themeMode = ref.watch(themeModeProvider);

    Future<void> signOut() async {
      final confirmed = await showConfirmationModalBottomSheet(
        context: context,
        title: 'Se déconnecter ?',
        content: 'Tu seras déconnecté de ton compte pour le moment.',
        cancelText: 'Annuler',
        confirmText: 'Se déconnecter',
      );

      if (!confirmed) return;

      await ref.read(authViewModelProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }

    Future<void> deleteAccount() async {
      final confirmed = await showConfirmationModalBottomSheet(
        context: context,
        title: 'Supprimer mon compte ?',
        content:
            'Cette action est définitive. Toutes les données associées à ton compte seront supprimées.',
        cancelText: 'Annuler',
        confirmText: 'Supprimer',
        destructive: true,
      );

      if (!confirmed) return;

      await ref.read(profileRepositoryProvider).deleteAccount();
      if (context.mounted) context.go('/login');
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text('Paramètres'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.moonStar, color: textPrimary),
                      const SizedBox(width: 12),
                      Text(
                        'Mode sombre',
                        style: TextStyle(color: textPrimary, fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: themeMode == ThemeMode.dark,
                    activeThumbColor: AppColors.primaryLight,
                    onChanged: (value) async {
                      await ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(LucideIcons.bell, color: textPrimary),
              title: Text(
                'Tester les notifications',
                style: TextStyle(color: textPrimary),
              ),
              subtitle: Text(
                'Envoie une notification de test via Supabase',
                style: TextStyle(color: textSecondary),
              ),
              onTap: () async {
                try {
                  await ref
                      .read(pushNotificationServiceProvider)
                      .refreshToken();
                  await ref
                      .read(profileRepositoryProvider)
                      .sendTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification de test envoyée.'),
                      ),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Échec de l\'envoi : $error')),
                    );
                  }
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(LucideIcons.shieldCheck, color: textPrimary),
              title: Text(
                'Vérifier le token FCM',
                style: TextStyle(color: textPrimary),
              ),
              subtitle: Text(
                'Affiche le token local et le token stocké dans Supabase',
                style: TextStyle(color: textSecondary),
              ),
              onTap: () async {
                try {
                  final localToken = await ref
                      .read(pushNotificationServiceProvider)
                      .refreshToken();
                  final storedToken = await ref
                      .read(profileRepositoryProvider)
                      .fetchStoredFcmToken();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Local: ${localToken ?? 'aucun token'}\nStocké: ${storedToken ?? 'aucun token'}',
                        ),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur token FCM : $error')),
                    );
                  }
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(LucideIcons.logOut, color: textPrimary),
              title: Text(
                'Se déconnecter',
                style: TextStyle(color: textPrimary),
              ),
              subtitle: Text(
                'Déconnexion de Supabase',
                style: TextStyle(color: textSecondary),
              ),
              onTap: signOut,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                LucideIcons.trash2,
                color: AppColors.errorLight,
              ),
              title: const Text(
                'Supprimer mon compte',
                style: TextStyle(color: AppColors.errorLight),
              ),
              subtitle: Text(
                'Suppression définitive',
                style: TextStyle(color: textSecondary),
              ),
              onTap: deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
