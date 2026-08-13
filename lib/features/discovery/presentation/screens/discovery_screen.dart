import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/profile_card.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/filter_modal.dart';
import 'package:lolango_v2/core/widgets/reusable_modal_bottom_sheet.dart';
import 'package:lolango_v2/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:lolango_v2/features/discovery/domain/profile_model.dart';


class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final filtered = ref.watch(filteredProfilesProvider);
    final filterState = ref.watch(discoveryFilterProvider);
    final currentUserAsync = ref.watch(currentUserProfileProvider);

    // Initialisation du filtre depuis les préférences onboarding.
    currentUserAsync.whenData((userMap) {
      try {
        if (userMap != null) {
          final prefs = (userMap['discovery_preferences'] is List)
              ? List<String>.from(userMap['discovery_preferences'])
              : <String>[];
          final isDefault = filterState.ageRange.start == 18 &&
              filterState.ageRange.end == 80 &&
              filterState.gender == null &&
              (filterState.city == null || filterState.city == '') &&
              filterState.socials.isEmpty;
          if (prefs.isNotEmpty && isDefault) {
            final first = prefs.first.toLowerCase();
            String? mapped;
            if (first.contains('fem')) { mapped = 'female'; }
            else if (first.contains('hom')) { mapped = 'male'; }
            if (mapped != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(discoveryFilterProvider.notifier).state = DiscoveryFilter(
                  ageRange: filterState.ageRange,
                  gender: mapped,
                  city: filterState.city,
                  socials: filterState.socials,
                );
              });
            }
          }
        }
      } catch (_) {}
    });

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Découvrir',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final surfaceColor = Theme.of(context).cardColor;
                      final textColor =
                          Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

                      final userMap = ref.read(currentUserProfileProvider).value;
                      String? userCity;
                      if (userMap != null) {
                        userCity = (userMap['location_label'] as String?) ??
                            (userMap['city'] as String?) ??
                            (userMap['location'] as String?);
                      }

                      final initial = DiscoveryFilter(
                        ageRange: filterState.ageRange,
                        gender: filterState.gender,
                        city: userCity ?? filterState.city,
                        socials: filterState.socials,
                      );

                      final res = await showReusableModalBottomSheet(
                        context: context,
                        title: 'Filtrer',
                        surface: surfaceColor,
                        textPrimary: textColor,
                        children: [FilterModal(initial: initial)],
                      );
                      if (res != null && res is DiscoveryFilter) {
                        ref.read(discoveryFilterProvider.notifier).state = res;
                      }
                    },
                    icon: const Icon(Icons.filter_list),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          'Aucun profil trouvé selon les filtres.',
                          style: TextStyle(color: textPrimary, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.70,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          return ProfileCard(
                            name: p.name,
                            age: p.age,
                            city: p.city,
                            country: p.country,
                            photoUrls: p.photoUrls,
                            bio: p.bio,
                            socials: p.socials,
                            interests: p.interests,
                            isGridMode: true,
                            onPass: () {},
                            onConnect: () {},
                            onTap: () {
                              _showActionModal(context, p,
                                  theme: Theme.of(context));
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionModal(BuildContext context, ProfileModel p,
      {required ThemeData theme}) {
    showReusableModalBottomSheet(
      context: context,
      title: p.name,
      surface: theme.cardColor,
      textPrimary: theme.textTheme.bodyLarge?.color ?? Colors.black,
      children: [
        // Description
        if (p.bio != null && p.bio!.isNotEmpty) ...[
          Text(
            p.bio!,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],

        // Réseaux sociaux
        if (p.socials.isNotEmpty) ...[
          const Text(
            'Réseaux sociaux',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...p.socials.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SocialRow(
                platform: e.key,
                username: e.value,
                theme: theme,
                onTap: () {
                  Navigator.pop(context);
                  _showSocialDetailModal(context, e.key, e.value, theme: theme);
                },
              ),
            );
          }),
          const SizedBox(height: 8),
        ] else ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Aucun réseau social renseigné.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],

        // Boutons X et Like
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(Icons.close, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFFE3C72),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(Icons.favorite, size: 28),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSocialDetailModal(
    BuildContext context,
    String platform,
    String username, {
    required ThemeData theme,
  }) {
    showReusableModalBottomSheet(
      context: context,
      title: platform,
      surface: theme.cardColor,
      textPrimary: theme.textTheme.bodyLarge?.color ?? Colors.black,
      children: const [
        SizedBox(height: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ligne de réseau social avec design par plateforme
// ---------------------------------------------------------------------------
class _SocialRow extends StatelessWidget {
  const _SocialRow({
    required this.platform,
    required this.username,
    required this.theme,
    this.onTap,
  });

  final String platform;
  final String username;
  final ThemeData theme;
  final VoidCallback? onTap;

  BoxDecoration _bgDecoration() {
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
        return const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFFC00));
      case 'tiktok':
        return const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF010101));
      case 'twitter':
      case 'x':
        return const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1DA1F2));
      case 'facebook':
        return const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1877F2));
      default:
        return const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF555555));
    }
  }

  ({IconData icon, Color color}) _iconStyle() {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return (icon: Icons.camera_alt, color: Colors.white);
      case 'snapchat':
        return (icon: Icons.chat_bubble, color: Colors.black);
      case 'tiktok':
        return (icon: Icons.music_note, color: Colors.white);
      default:
        return (icon: Icons.link, color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _iconStyle();
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: _bgDecoration(),
            child: Icon(style.icon, color: style.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  username,
                  style: TextStyle(
                    color: textColor.withAlpha((0.6 * 255).round()),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: textColor.withAlpha((0.4 * 255).round())),
        ],
      ),
    );
  }
}
