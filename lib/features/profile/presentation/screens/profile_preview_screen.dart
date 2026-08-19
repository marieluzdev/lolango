import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/profile_card.dart';

class ProfilePreviewScreen extends ConsumerStatefulWidget {
  const ProfilePreviewScreen({super.key});

  @override
  ConsumerState<ProfilePreviewScreen> createState() =>
      _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends ConsumerState<ProfilePreviewScreen> {
  DetailedProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .fetchDetailedProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Aperçu de ta carte',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? Center(
              child: Text(
                'Profil introuvable.',
                style: TextStyle(color: textPrimary),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.eye,
                          size: 16,
                          color: textPrimary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'C\'est ainsi que les autres utilisateurs voient ta carte',
                            style: TextStyle(
                              fontSize: 13,
                              color: textPrimary.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: _buildProfileCard(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildProfileCard() {
    final detailedP = _profile!;
    final p = detailedP.profile;

    return ProfileCard(
      name: p.name,
      age: p.age,
      city: p.city,
      photoUrls: detailedP.photoUrls,
      bio: p.bio,
      socials: detailedP.socials,
      blurredSocials: const {}, // User sees their own socials clearly
      interests: detailedP.interests,
      showActionButtons: false,
    );
  }
}
