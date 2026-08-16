import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/profile_card.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/filter_modal.dart';
import 'package:lolango_v2/core/widgets/reusable_modal_bottom_sheet.dart';
import 'package:lolango_v2/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:lolango_v2/features/discovery/presentation/providers/discovery_filter_init_provider.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/features/match/presentation/providers/interaction_providers.dart';
import 'package:lolango_v2/features/profile/presentation/providers/profile_provider.dart';
import 'package:lolango_v2/core/widgets/app_empty_state.dart';
import 'package:lolango_v2/core/widgets/app_error_state.dart';
import 'package:lolango_v2/core/widgets/app_loading.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute de l'initialisation du filtre (sans effet direct sur le rendu local)
    ref.watch(discoveryFilterInitProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final filteredAsync = ref.watch(filteredProfilesProvider);
    final filterState = ref.watch(discoveryFilterProvider);

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
                      final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

                      final userProfile = ref.read(profileProvider).value;
                      String? userCity;
                      if (userProfile != null) {
                        userCity = userProfile.profile.city;
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
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allProfilesProvider);
                    ref.invalidate(interactedProfilesProvider);
                  },
                  child: filteredAsync.when(
                    loading: () => const AppSpinner(),
                    error: (error, _) => AppErrorState(
                      message: "Erreur lors du chargement des profils.",
                      onRetry: () {
                        ref.invalidate(allProfilesProvider);
                        ref.invalidate(interactedProfilesProvider);
                      },
                    ),
                    data: (filtered) {
                      if (filtered.isEmpty) {
                        return CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              child: AppEmptyState(
                                icon: LucideIcons.users,
                                title: 'Aucun profil',
                                description: 'Aucun profil trouvé selon les filtres actuels.',
                                actionLabel: 'Réinitialiser',
                                onAction: () {
                                  ref.read(discoveryFilterProvider.notifier).state = DiscoveryFilter(
                                    ageRange: const RangeValues(18, 80),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      return GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.70,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          return ProfileCard(
                            name: p.profile.name,
                            age: p.profile.age,
                            city: p.profile.city,
                            country: p.profile.country,
                            photoUrls: p.photoUrls,
                            bio: p.profile.bio,
                            socials: p.socials,
                            interests: p.interests,
                            isGridMode: true,
                            onPass: () {
                              ref.read(hiddenProfilesProvider.notifier).update((state) {
                                final newState = Set<String>.from(state);
                                newState.add(p.profile.id);
                                return newState;
                              });
                              ref.read(interactionRepositoryProvider).passProfile(p.profile.id).then((_) {
                                ref.invalidate(interactedProfilesProvider);
                              });
                            },
                            onConnect: () {
                              ref.read(hiddenProfilesProvider.notifier).update((state) {
                                final newState = Set<String>.from(state);
                                newState.add(p.profile.id);
                                return newState;
                              });
                              ref.read(interactionRepositoryProvider).likeProfile(p.profile.id).then((isMatch) {
                                if (isMatch) {
                                  ref.read(matchNotificationBadgeProvider.notifier).state++;
                                  ref.invalidate(matchesProvider);
                                }
                                ref.invalidate(interactedProfilesProvider);
                              });
                            },
                            onTap: () {
                              _showActionModal(context, ref, p, theme: Theme.of(context));
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionModal(BuildContext context, WidgetRef ref, DetailedProfileModel pDetailed,
      {required ThemeData theme}) {
    final p = pDetailed.profile;
    final socials = pDetailed.socials;

    showReusableModalBottomSheet(
      context: context,
      title: p.name,
      surface: theme.cardColor,
      textPrimary: theme.textTheme.bodyLarge?.color ?? Colors.black,
      children: [
        if (p.bio != null && p.bio!.isNotEmpty) ...[
          Text(
            p.bio!,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],

        if (socials.isNotEmpty) ...[
          const Text(
            'Réseaux sociaux',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...socials.entries.map((e) {
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

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(hiddenProfilesProvider.notifier).update((state) {
                    final newState = Set<String>.from(state);
                    newState.add(p.id);
                    return newState;
                  });
                  ref.read(interactionRepositoryProvider).passProfile(p.id).then((_) {
                    ref.invalidate(interactedProfilesProvider);
                  });
                  Navigator.pop(context);
                },
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
                onPressed: () {
                  ref.read(hiddenProfilesProvider.notifier).update((state) {
                    final newState = Set<String>.from(state);
                    newState.add(p.id);
                    return newState;
                  });
                  ref.read(interactionRepositoryProvider).likeProfile(p.id).then((isMatch) {
                    if (isMatch) {
                      ref.read(matchNotificationBadgeProvider.notifier).state++;
                      ref.invalidate(matchesProvider);
                    }
                    ref.invalidate(interactedProfilesProvider);
                  });
                  Navigator.pop(context);
                },
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
