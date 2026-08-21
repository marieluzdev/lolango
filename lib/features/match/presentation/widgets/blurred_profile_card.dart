import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/core/widgets/app_cached_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BlurredProfileCard extends StatelessWidget {
  final DetailedProfileModel profile;
  final VoidCallback onLike;

  const BlurredProfileCard({
    super.key,
    required this.profile,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onLike,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ============================================================
              // PHOTO DU PROFIL
              // ============================================================
              if (profile.primaryPhotoUrl != null)
                AppCachedImage(
                  imageUrl: profile.primaryPhotoUrl!,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  child: Center(
                    child: Icon(
                      LucideIcons.user,
                      size: 48,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),

              // ============================================================
              // FLOU SUR LA PHOTO
              // ============================================================
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(color: Colors.black.withValues(alpha: 0.22)),
                ),
              ),

              // ============================================================
              // DÉGRADÉ SOMBRE
              // ============================================================
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x11000000),
                      Color(0x22000000),
                      Color(0x66000000),
                      Color(0xCC000000),
                    ],
                    stops: [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),

              // ============================================================
              // CONTENU CENTRAL
              // ============================================================
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.heart,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Quelqu'un s'intéresse\nà toi",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
