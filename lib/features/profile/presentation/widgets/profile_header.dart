import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileHeader extends StatelessWidget {
  final String firstName;
  final String username;
  final String location;
  final String gender;
  final int? age;
  final String? primaryPhotoUrl;

  const ProfileHeader({
    super.key,
    required this.firstName,
    required this.username,
    required this.location,
    required this.gender,
    this.age,
    this.primaryPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Center(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(48),
            child: primaryPhotoUrl != null && primaryPhotoUrl!.isNotEmpty
                ? Image.network(
                    primaryPhotoUrl!,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _AvatarInitial(
                      letter: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'L',
                    ),
                  )
                : _AvatarInitial(
                    letter: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'L',
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            firstName,
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            username,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (location.isNotEmpty && location != 'Localisation non renseignée')
                _InfoPill(
                  icon: LucideIcons.mapPin,
                  label: location,
                  color: textSecondary,
                ),
              if (gender != 'Non renseigné') ...[
                _InfoDivider(color: border),
                _InfoPill(
                  icon: LucideIcons.user,
                  label: gender,
                  color: textSecondary,
                ),
              ],
              if (age != null) ...[
                _InfoDivider(color: border),
                _InfoPill(
                  icon: LucideIcons.cake,
                  label: '$age ans',
                  color: textSecondary,
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.push('/profile-edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: textPrimary,
              side: BorderSide(color: border),
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text(
              'Modifier le profil',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 1,
        height: 12,
        color: color,
      ),
    );
  }
}
