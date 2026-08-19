import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';
import 'package:lolango_v2/features/social_access/domain/social_visibility_model.dart';
import 'package:lolango_v2/features/social_access/providers/social_visibility_provider.dart';

class ProfileSocialsSection extends ConsumerWidget {
  final Map<String, String> socials;

  const ProfileSocialsSection({super.key, required this.socials});

  /// Retourne la décoration de fond (BoxDecoration) pour l'icône d'un réseau.
  BoxDecoration _socialBgDecoration(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF56040)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'snapchat':
        return const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFFC00),
        );
      case 'tiktok':
        return const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF010101),
        );
      case 'twitter':
      case 'x':
        return const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1DA1F2),
        );
      case 'facebook':
        return const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1877F2),
        );
      case 'youtube':
        return const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFF0000),
        );
      case 'linkedin':
        return const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0A66C2),
        );
      case 'pinterest':
        return const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE60023),
        );
      case 'discord':
        return const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF5865F2),
        );
      default:
        return const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF555555),
        );
    }
  }

  /// Retourne l'icône et la couleur d'icône pour un réseau social.
  ({IconData icon, Color iconColor}) _socialIconStyle(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return (icon: Icons.camera_alt, iconColor: Colors.white);
      case 'snapchat':
        return (icon: Icons.chat_bubble, iconColor: Colors.black);
      case 'tiktok':
        return (icon: Icons.music_note, iconColor: Colors.white);
      case 'twitter':
      case 'x':
        return (icon: Icons.alternate_email, iconColor: Colors.white);
      case 'facebook':
        return (icon: Icons.facebook, iconColor: Colors.white);
      case 'youtube':
        return (icon: Icons.play_arrow, iconColor: Colors.white);
      case 'linkedin':
        return (icon: Icons.work, iconColor: Colors.white);
      case 'pinterest':
        return (icon: Icons.push_pin, iconColor: Colors.white);
      case 'discord':
        return (icon: Icons.headset_mic, iconColor: Colors.white);
      default:
        return (icon: Icons.link, iconColor: Colors.white);
    }
  }

  String? _getAssetPath(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return 'assets/icons/instagram.png';
      case 'snapchat':
        return 'assets/icons/snapchat.png';
      case 'tiktok':
        return 'assets/icons/tiktok.png';
      default:
        return null;
    }
  }

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
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Confirmer',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                                  await ref.read(profileRepositoryProvider).upsertSocials({
                                    'Instagram': instagramController.text.trim(),
                                    'Snapchat': snapchatController.text.trim(),
                                    'TikTok': tiktokController.text.trim(),
                                  });
                                  if (editCtx.mounted) {
                                    Navigator.of(editCtx).pop(true);
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
    return TextField(
      controller: controller,
      style: TextStyle(color: textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: textPrimary.withValues(alpha: 0.5)),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (socials.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réseaux sociaux',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(socials.length, (index) {
              final platform = socials.keys.elementAt(index);
              final socialUsername = socials[platform]!;
              if (platform.isEmpty || socialUsername.isEmpty) {
                return const SizedBox.shrink();
              }
              final assetPath = _getAssetPath(platform);
              final iconStyle = _socialIconStyle(platform);
              final isLast = index == socials.length - 1;

              return Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final p = await ref.read(profileRepositoryProvider).fetchDetailedProfile();
                      final userPlatforms = p?.socials.keys.toList() ?? [];
                      if (context.mounted) {
                        _showPrivacySettingsSheet(context, ref, textPrimary, textSecondary, userPlatforms);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: _socialBgDecoration(platform),
                            child: assetPath != null
                                ? Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Image.asset(
                                      assetPath,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : Icon(
                                    iconStyle.icon,
                                    color: iconStyle.iconColor,
                                    size: 20,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  platform,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  socialUsername,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, thickness: 1, color: border, indent: 70),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
