import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';

class ProfileSocialsSection extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
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
              final style = _socialStyle(platform);
              final isLast = index == socials.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: style.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(style.icon, color: style.color, size: 14),
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
                          LucideIcons.chevronRight,
                          size: 18,
                          color: textSecondary,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, thickness: 1, color: border, indent: 56),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
