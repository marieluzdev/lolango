import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/widgets/modal_action_tile.dart';
import 'package:lolango_v2/core/widgets/reusable_modal_bottom_sheet.dart';
import 'package:lolango_v2/core/widgets/app_loading.dart';
import 'package:lolango_v2/core/widgets/app_error_state.dart';
import 'package:lolango_v2/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/profile_header.dart';
import '../widgets/profile_bio_section.dart';
import '../widgets/profile_interests_section.dart';
import '../widgets/profile_socials_section.dart';
import '../widgets/profile_photo_gallery.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _formatCity(String? fullAddress) {
    if (fullAddress == null || fullAddress.trim().isEmpty) return 'Localisation non renseignée';
    final parts = fullAddress.split(',');
    if (parts.length > 2) {
      final country = parts.last.trim();
      var cityPart = parts[parts.length - 2].trim();
      if (RegExp(r'^\d+$').hasMatch(cityPart) && parts.length > 3) {
        cityPart = parts[parts.length - 3].trim();
      }
      cityPart = cityPart.replaceAll(RegExp(r'^Région de\s+', caseSensitive: false), '')
                         .replaceAll(RegExp(r'^Region of\s+', caseSensitive: false), '')
                         .replaceAll(RegExp(r'^Region de\s+', caseSensitive: false), '');
      return '$cityPart, $country';
    }
    return fullAddress;
  }

  void _showOptionsSheet({
    required BuildContext context,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color primary,
  }) {
    showReusableModalBottomSheet(
      context: context,
      title: 'Options',
      surface: surface,
      textPrimary: textPrimary,
      children: [
        ModalActionTile(
          icon: LucideIcons.eye,
          label: 'Aperçu profil',
          textColor: textPrimary,
          onTap: () {
            Navigator.of(context).pop();
            context.push('/profile-preview');
          },
        ),
        const SizedBox(height: 12),
        ModalActionTile(
          icon: LucideIcons.settings,
          label: 'Paramètres',
          textColor: textPrimary,
          onTap: () {
            Navigator.of(context).pop();
            context.push('/settings');
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // EN-TÊTE FIXE : "Mon profil" + bouton Options
            // ==================================================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              decoration: BoxDecoration(
                color: background,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mon profil',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showOptionsSheet(
                      context: context,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      primary: primary,
                    ),
                    icon: Icon(LucideIcons.menu, color: textPrimary),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENU DÉFILANT
            // ==================================================
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(profileProvider.notifier).refreshProfile(),
                child: profileState.when(
                  loading: () => AppLoading(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ProfileHeader(
                            firstName: 'Chargement',
                            username: 'chargement',
                            location: 'Ville',
                            gender: 'male',
                            age: 25,
                            primaryPhotoUrl: null,
                          ),
                          const SizedBox(height: 28),
                          const ProfilePhotoGallery(photoUrls: []),
                          const SizedBox(height: 24),
                          ProfileBioSection(bio: 'Ceci est une fausse bio de chargement. ' * 3),
                        ],
                      ),
                    ),
                  ),
                  error: (err, stack) => AppErrorState(
                    message: err.toString(),
                    onRetry: () =>
                        ref.read(profileProvider.notifier).refreshProfile(),
                  ),
                  data: (profile) {
                    if (profile == null) {
                      return AppErrorState(
                        message: "Impossible de charger le profil.",
                        onRetry: () =>
                            ref.read(profileProvider.notifier).refreshProfile(),
                      );
                    }

                    final firstName = profile.profile.name;
                    final username = profile.profile.username;
                    final bio =
                        profile.profile.bio ??
                        'Ajoute une bio pour te présenter.';
                    final location = _formatCity(profile.profile.city);
                    final gender = profile.profile.gender ?? 'Non renseigné';
                    final socials = profile.socials;
                    final interests = profile.interests;
                    final photoUrls = profile.photoUrls;
                    final primaryPhotoUrl = photoUrls.isNotEmpty
                        ? photoUrls.first
                        : null;
                    final age = profile.profile.age;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileHeader(
                            firstName: firstName,
                            username: username,
                            location: location,
                            gender: gender,
                            age: age,
                            primaryPhotoUrl: primaryPhotoUrl,
                          ),
                          const SizedBox(height: 28),
                          ProfilePhotoGallery(photoUrls: photoUrls),
                          const SizedBox(height: 24),
                          ProfileBioSection(bio: bio),
                          const SizedBox(height: 24),
                          ProfileInterestsSection(interests: interests),
                          const SizedBox(height: 24),
                          ProfileSocialsSection(socials: socials),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
