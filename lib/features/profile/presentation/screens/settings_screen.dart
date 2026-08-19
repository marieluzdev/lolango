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
import 'package:lolango_v2/features/profile/presentation/providers/profile_provider.dart';
import 'package:lolango_v2/features/social_access/domain/social_visibility_model.dart';
import 'package:lolango_v2/features/social_access/providers/social_visibility_provider.dart';

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
              leading: Icon(LucideIcons.lock, color: textPrimary),
              title: Text(
                'Confidentialité des réseaux',
                style: TextStyle(color: textPrimary),
              ),
              subtitle: Builder(
                builder: (context) {
                  final visibilityAsync = ref.watch(socialVisibilityProvider);
                  final label = visibilityAsync.valueOrNull?.mode.label ?? '—';
                  return Text(
                    label,
                    style: TextStyle(color: textSecondary),
                  );
                },
              ),
              trailing: Icon(LucideIcons.chevronRight, color: textSecondary, size: 18),
              onTap: () async {
                final p = await ref.read(profileRepositoryProvider).fetchDetailedProfile();
                final userPlatforms = p?.socials.keys.toList() ?? [];
                if (context.mounted) {
                  _showPrivacySettingsSheet(context, ref, textPrimary, textSecondary, userPlatforms);
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

/// Ouvre un bottom sheet pour modifier la visibilité des réseaux sans quitter les Paramètres
void _showPrivacySettingsSheet(
  BuildContext context,
  WidgetRef ref,
  Color textPrimary,
  Color textSecondary,
  List<String> userPlatforms,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  final border = isDark ? AppColors.borderDark : AppColors.borderLight;
  final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

  final current = ref.read(socialVisibilityProvider).valueOrNull;
  SocialVisibility selectedMode = current?.mode ?? SocialVisibility.afterMatch;
  final selectedPlatforms = current?.visiblePlatforms.toSet() ?? {};

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(sheetContext).padding.bottom + 16,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Confidentialité des réseaux',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: Icon(Icons.close, color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...SocialVisibility.values.map((mode) {
                    final isSelected = selectedMode == mode;
                    final card = GestureDetector(
                      onTap: () => setSheetState(() => selectedMode = mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.black : border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        mode.label,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (mode == SocialVisibility.afterMatch) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.white : primary,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Défaut',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    mode.description,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white.withValues(alpha: 0.7) : textSecondary,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                    );

                    if (mode == SocialVisibility.selective && isSelected && userPlatforms.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          card,
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                            child: Column(
                              children: userPlatforms.map((platform) {
                                final isPlatformSelected = selectedPlatforms.contains(platform);
                                return Material(
                                  color: Colors.transparent,
                                  child: CheckboxListTile(
                                    value: isPlatformSelected,
                                    onChanged: (val) {
                                      setSheetState(() {
                                        if (val == true) {
                                          selectedPlatforms.add(platform);
                                        } else {
                                          selectedPlatforms.remove(platform);
                                        }
                                      });
                                    },
                                    title: Text(platform, style: TextStyle(color: textPrimary)),
                                    activeColor: primary,
                                    checkColor: Colors.black,
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    }

                    return card;
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              final saved = await _showEditNetworksModal(
                                context,
                                ref,
                                textPrimary,
                                textSecondary,
                                surface,
                                border,
                                primary,
                              );
                              if (saved == false && context.mounted) {
                                _showPrivacySettingsSheet(context, ref, textPrimary, textSecondary, userPlatforms);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textPrimary,
                              side: BorderSide(color: border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Modifier',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await ref.read(socialVisibilityProvider.notifier).saveVisibility(
                                selectedMode,
                                selectedMode == SocialVisibility.selective
                                    ? selectedPlatforms.toList()
                                    : [],
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Visibilité mise à jour ✓'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Enregistrer',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Ouvre un modal pour modifier les réseaux sociaux
Future<bool> _showEditNetworksModal(
  BuildContext parentContext,
  WidgetRef ref,
  Color textPrimary,
  Color textSecondary,
  Color surface,
  Color border,
  Color primary,
) async {
  // Charger les réseaux sociaux actuels
  final profile = await ref.read(profileRepositoryProvider).fetchDetailedProfile();
  final instagramValue = profile?.socials['Instagram'] ?? '';
  final snapchatValue = profile?.socials['Snapchat'] ?? '';
  final tiktokValue = profile?.socials['TikTok'] ?? '';

  final result = await showModalBottomSheet<bool>(
    context: parentContext,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (editCtx) {
      final instagramController = TextEditingController(text: instagramValue);
      final snapchatController = TextEditingController(text: snapchatValue);
      final tiktokController = TextEditingController(text: tiktokValue);

      return StatefulBuilder(
        builder: (editCtx, setEditState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              (MediaQuery.of(editCtx).viewInsets.bottom > 0
                  ? MediaQuery.of(editCtx).viewInsets.bottom
                  : MediaQuery.of(editCtx).padding.bottom) + 16,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Modifier les réseaux',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(editCtx).pop(false);
                          },
                          icon: Icon(Icons.close, color: textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSocialField(
                      controller: instagramController,
                      hintText: 'Instagram',
                      textPrimary: textPrimary,
                      surface: surface,
                      border: border,
                    ),
                    const SizedBox(height: 12),
                    _buildSocialField(
                      controller: snapchatController,
                      hintText: 'Snapchat',
                      textPrimary: textPrimary,
                      surface: surface,
                      border: border,
                    ),
                    const SizedBox(height: 12),
                    _buildSocialField(
                      controller: tiktokController,
                      hintText: 'TikTok',
                      textPrimary: textPrimary,
                      surface: surface,
                      border: border,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(editCtx).pop(false);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textPrimary,
                              side: BorderSide(color: border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: () async {
                              final socialMap = <String, String>{};
                              if (instagramController.text.trim().isNotEmpty) {
                                socialMap['Instagram'] = instagramController.text.trim();
                              }
                              if (snapchatController.text.trim().isNotEmpty) {
                                socialMap['Snapchat'] = snapchatController.text.trim();
                              }
                              if (tiktokController.text.trim().isNotEmpty) {
                                socialMap['TikTok'] = tiktokController.text.trim();
                              }
                              
                              await ref.read(profileRepositoryProvider).upsertSocials(socialMap);
                              ref.invalidate(profileProvider);
                              if (parentContext.mounted) {
                                Navigator.of(editCtx).pop(true);
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Réseaux mis à jour ✓'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Enregistrer',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    },
  );
  
  return result ?? false;
}

Widget _buildSocialField({
  required TextEditingController controller,
  required String hintText,
  required Color textPrimary,
  required Color surface,
  required Color border,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border),
    ),
    child: TextField(
      controller: controller,
      style: TextStyle(fontSize: 17, color: textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );
}
