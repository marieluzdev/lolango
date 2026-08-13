import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/match/presentation/providers/interaction_providers.dart';
import 'package:lolango_v2/features/match/presentation/widgets/blurred_profile_card.dart';
import 'package:lolango_v2/features/match/presentation/widgets/matched_profile_card.dart';
import 'package:lolango_v2/core/widgets/reusable_modal_bottom_sheet.dart';
import 'package:lolango_v2/features/discovery/domain/profile_model.dart';

class MatchScreen extends ConsumerWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    // Clear notification badge when Match menu is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(matchNotificationBadgeProvider) > 0) {
        ref.read(matchNotificationBadgeProvider.notifier).state = 0;
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Match',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Likes reçus'),
                  Tab(text: 'Matchs'),
                ],
                labelColor: Color(0xFFFE3C72),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFFFE3C72),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPendingLikesTab(ref, textPrimary),
                    _buildMatchesTab(ref, textPrimary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildPendingLikesTab(WidgetRef ref, Color textColor) {
    final pendingAsync = ref.watch(pendingLikesProvider);

    return pendingAsync.when(
      data: (likes) {
        if (likes.isEmpty) {
          return Center(
            child: Text('Aucun like reçu pour le moment.', style: TextStyle(color: textColor)),
          );
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.70,
          ),
          itemCount: likes.length,
          itemBuilder: (context, index) {
            final p = likes[index];
            return BlurredProfileCard(
              profile: p,
              onLike: () {
                ref.read(interactionRepositoryProvider).likeProfile(p.id).then((isMatch) {
                  ref.invalidate(pendingLikesProvider);
                  ref.invalidate(matchesProvider);
                  ref.invalidate(interactedProfilesProvider);
                });
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildMatchesTab(WidgetRef ref, Color textColor) {
    final matchesAsync = ref.watch(matchesProvider);

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Text('Aucun match pour le moment.', style: TextStyle(color: textColor)),
          );
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.70,
          ),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final p = matches[index];
            return MatchedProfileCard(
              profile: p,
              onTap: () {
                _showSocialsModal(context, p);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erreur: $e')),
    );
  }

  void _showSocialsModal(BuildContext context, ProfileModel p) {
    showReusableModalBottomSheet(
      context: context,
      title: 'Connexion avec ${p.name}',
      surface: Theme.of(context).cardColor,
      textPrimary: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      children: [
        if (p.socials.isNotEmpty) ...[
          ...p.socials.entries.map((e) {
            return ListTile(
              leading: Icon(LucideIcons.link),
              title: Text(e.key),
              subtitle: Text(e.value),
            );
          }),
        ] else ...[
          const Text('Aucun réseau social renseigné.'),
        ],
      ],
    );
  }
}
