import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/core/widgets/app_cached_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MatchedProfileCard extends StatelessWidget {
  final DetailedProfileModel profile;
  final VoidCallback onTap;

  const MatchedProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ============================================================
              // PHOTO
              // ============================================================
              profile.primaryPhotoUrl != null
                  ? AppCachedImage(
                      imageUrl: profile.primaryPhotoUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        LucideIcons.user,
                        size: 48,
                        color: Colors.grey.shade500,
                      ),
                    ),

              // ============================================================
              // BADGE MATCH
              // ============================================================
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MATCH',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: isDark ? Colors.black : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ============================================================
              // INFORMATIONS
              // ============================================================
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ======================================================
                      // NOM + COEUR
                      // ======================================================
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              '${profile.profile.name}${profile.profile.age != null ? ', ${profile.profile.age}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.heart,
                              size: 19,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ======================================================
                      // SEPARATEUR
                      // ======================================================
                      Container(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1)),

                      const SizedBox(height: 15),

                      // ======================================================
                      // MESSAGE MATCH
                      // ======================================================
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 20,
                            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              'Vous vous plaisez\nmutuellement !',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                                color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
