import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfilePhotoGallery extends StatelessWidget {
  final List<String> photoUrls;

  const ProfilePhotoGallery({
    super.key,
    required this.photoUrls,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final secondary = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Photos',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (photoUrls.length > 4)
              GestureDetector(
                onTap: () => context.push('/profile-photos'),
                child: Text(
                  'Voir tout',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _PhotoGalleryGrid(
          photoUrls: photoUrls,
          surface: surface,
          border: border,
          primary: primary,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onAddPhoto: () => context.push('/profile-photos'),
          onTapPhoto: (_) => context.push('/profile-photos'),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _PhotoGalleryGrid extends StatelessWidget {
  final List<String> photoUrls;
  final Color surface;
  final Color border;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onTapPhoto;
  final bool isDark;

  const _PhotoGalleryGrid({
    required this.photoUrls,
    required this.surface,
    required this.border,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.onAddPhoto,
    required this.onTapPhoto,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const double galleryHeight = 264;
    const double gap = 8;

    if (photoUrls.isEmpty) {
      return _AddPhotoTile(
        surface: surface,
        border: border,
        primary: primary,
        height: 140,
        onTap: onAddPhoto,
        isDark: isDark,
      );
    }

    final hasSecondPhoto = photoUrls.length > 1;

    return SizedBox(
      height: galleryHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _PhotoTile(
              url: photoUrls[0],
              border: border,
              surface: surface,
              badgeLabel: 'Photo principale',
              badgeSurface: surface,
              badgeText: textPrimary,
              onTap: () => onTapPhoto(0),
            ),
          ),
          const SizedBox(width: gap),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _AddPhotoTile(
                    surface: surface,
                    border: border,
                    primary: primary,
                    onTap: onAddPhoto,
                    isDark: isDark,
                  ),
                ),
                if (hasSecondPhoto) ...[
                  const SizedBox(height: gap),
                  Expanded(
                    child: _PhotoTile(
                      url: photoUrls[1],
                      border: border,
                      surface: surface,
                      onTap: () => onTapPhoto(1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final Color border;
  final Color surface;
  final String? badgeLabel;
  final Color? badgeSurface;
  final Color? badgeText;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.url,
    required this.border,
    required this.surface,
    required this.onTap,
    this.badgeLabel,
    this.badgeSurface,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: border, width: 1),
              ),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: surface,
                  child: Icon(LucideIcons.imageOff, color: border),
                ),
              ),
            ),
            if (badgeLabel != null)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: badgeText,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final Color surface;
  final Color border;
  final Color primary;
  final double? height;
  final VoidCallback onTap;
  final bool isDark;

  const _AddPhotoTile({
    required this.surface,
    required this.border,
    required this.primary,
    required this.onTap,
    this.height,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, size: 22, color: iconColor),
            const SizedBox(height: 6),
            Text(
              'Ajouter\nune photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
