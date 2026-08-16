import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileSocialsSection extends StatelessWidget {
  final Map<String, String> socials;

  const ProfileSocialsSection({
    super.key,
    required this.socials,
  });

  ({Color color, IconData icon}) _socialStyle(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return (color: const Color(0xFFE1306C), icon: LucideIcons.camera);
      case 'snapchat':
        return (color: const Color(0xFFF7C600), icon: LucideIcons.messageCircle);
      case 'tiktok':
        return (color: const Color(0xFF000000), icon: LucideIcons.music);
      default:
        return (color: const Color(0xFF999999), icon: LucideIcons.link);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (socials.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        Icon(LucideIcons.chevronRight, size: 18, color: textSecondary),
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
