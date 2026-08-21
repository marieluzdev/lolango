import 'package:flutter/material.dart';
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
    final name = profile.profile.name;
    final age = profile.profile.age;

    return GestureDetector(
      onTap: onTap,
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
                  color: Colors.grey.shade300,
                  child: Icon(
                    LucideIcons.user,
                    size: 48,
                    color: Colors.grey.shade500,
                  ),
                ),

              // ============================================================
              // DÉGRADÉ SOMBRE EN BAS DE L'IMAGE
              // ============================================================
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Color(0x22000000),
                      Color(0x55000000),
                      Color(0xDD000000),
                    ],
                    stops: [0.35, 0.48, 0.60, 0.72, 1.0],
                  ),
                ),
              ),

              // ============================================================
              // NOM + ÂGE
              // ============================================================
              Positioned(
                left: 18,
                right: 78,
                bottom: 28,
                child: Text(
                  age != null ? '$name, $age' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ),

              // ============================================================
              // BOUTON MESSAGE
              // ============================================================
              Positioned(
                right: 16,
                bottom: 18,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.messageCircle,
                      color: Colors.white,
                      size: 20,
                    ),
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
