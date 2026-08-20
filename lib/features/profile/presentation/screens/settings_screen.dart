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
        outlineButton: true,
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
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Paramètres',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Apparence', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.palette,
                  title: 'Thème',
                  textPrimary: textPrimary,
                  trailing: Switch(
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
                ),
                _buildTile(
                  icon: LucideIcons.globe,
                  title: 'Langue',
                  textPrimary: textPrimary,
                  showDivider: false,
                ),
              ], surface),

              _buildSectionTitle('Compte', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.bell,
                  title: 'Notifications',
                  textPrimary: textPrimary,
                  onTap: () async {
                    try {
                      await ref.read(pushNotificationServiceProvider).refreshToken();
                      await ref.read(profileRepositoryProvider).sendTestNotification();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification de test envoyée.')));
                    } catch (error) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de l\'envoi : $error')));
                    }
                  },
                ),
                _buildTile(
                  icon: LucideIcons.mapPin,
                  title: 'Lieu',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.lock,
                  title: 'Confidentialité des réseaux',
                  textPrimary: textPrimary,
                  onTap: () async {
                    final p = await ref.read(profileRepositoryProvider).fetchDetailedProfile();
                    final userPlatforms = p?.socials.keys.toList() ?? [];
                    if (context.mounted) {
                      _showPrivacySettingsSheet(context, ref, textPrimary, textSecondary, userPlatforms);
                    }
                  },
                ),
                _buildTile(
                  icon: LucideIcons.users,
                  title: 'Mes communautés',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.ban,
                  title: 'Utilisateurs bloqués',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.trash2,
                  title: 'Supprimer mon compte',
                  textPrimary: AppColors.errorLight,
                  showDivider: false,
                  onTap: deleteAccount,
                ),
              ], surface),

              _buildSectionTitle('Sécurité', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.phone,
                  title: 'Appeler la police',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.shield,
                  title: 'Directives de sécurité',
                  textPrimary: textPrimary,
                  showDivider: false,
                ),
              ], surface),

              _buildSectionTitle('Partenariat', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.badgeCheck,
                  title: 'Devenir partenaire',
                  textPrimary: textPrimary,
                  showDivider: false,
                ),
              ], surface),

              _buildSectionTitle('Légal', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.folder,
                  title: 'Politique de confidentialité',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.fileText,
                  title: 'Conditions d\'utilisation',
                  textPrimary: textPrimary,
                  showDivider: false,
                ),
              ], surface),

              _buildSectionTitle('Support', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.helpCircle,
                  title: 'Centre d\'aide',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.send,
                  title: 'Nous contacter',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.messageCircle,
                  title: 'Faire une suggestion',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.wrench,
                  title: 'Dépannage de connexion',
                  textPrimary: textPrimary,
                  showDivider: false,
                  onTap: () async {
                    try {
                      final localToken = await ref.read(pushNotificationServiceProvider).refreshToken();
                      final storedToken = await ref.read(profileRepositoryProvider).fetchStoredFcmToken();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Local: ${localToken ?? 'aucun token'}\nStocké: ${storedToken ?? 'aucun token'}'), duration: const Duration(seconds: 5)));
                      }
                    } catch (error) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur token FCM : $error')));
                    }
                  },
                ),
              ], surface),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: signOut,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE), // very light red
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: const Icon(LucideIcons.logOut, size: 20),
                  label: const Text(
                    'Déconnexion',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24),
      child: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildGroup(List<Widget> children, Color surface) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required Color textPrimary,
    Widget? trailing,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(icon, color: textPrimary, size: 22),
          title: Text(
            title,
            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: trailing ?? Icon(LucideIcons.chevronRight, color: textPrimary.withOpacity(0.4), size: 18),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(height: 1, indent: 56, endIndent: 16, color: textPrimary.withOpacity(0.1)),
      ],
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
                    final selectedBg = isDark ? Colors.white : Colors.black;
                    final selectedText = isDark ? Colors.black : Colors.white;
                    final selectedTextSec = isDark ? Colors.black87 : Colors.white.withValues(alpha: 0.7);
                    final card = GestureDetector(
                      onTap: () => setSheetState(() => selectedMode = mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? selectedBg : surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? selectedBg : border,
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
                                          color: isSelected ? selectedText : textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (mode == SocialVisibility.afterMatch) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected ? (isDark ? Colors.black12 : Colors.white) : primary,
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
                                      color: isSelected ? selectedTextSec : textSecondary,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: selectedText, size: 22),
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
