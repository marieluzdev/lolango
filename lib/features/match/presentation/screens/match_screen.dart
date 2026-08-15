import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/widgets/modal_action_tile.dart';
import 'package:lolango_v2/features/match/presentation/providers/interaction_providers.dart';
import 'package:lolango_v2/features/match/presentation/widgets/blurred_profile_card.dart';
import 'package:lolango_v2/features/match/presentation/widgets/matched_profile_card.dart';
import 'package:lolango_v2/core/widgets/reusable_modal_bottom_sheet.dart';
import 'package:lolango_v2/features/discovery/domain/profile_model.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  int _tabIndex = 0;

  static const _tabs = ['Likes reçus', 'Matchs'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(matchNotificationBadgeProvider) > 0) {
        ref.read(matchNotificationBadgeProvider.notifier).state = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Text(
                'Match',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Segmented control — conteneur surface, onglet actif fond primary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final isSelected = _tabIndex == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            _tabs[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

              // IndexedStack — pas de flash, les deux tabs restent en mémoire
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    _buildPendingLikesTab(textPrimary),
                    _buildMatchesTab(textPrimary),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingLikesTab(Color textColor) {
    final pendingAsync = ref.watch(pendingLikesProvider);

    return pendingAsync.when(
      data: (likes) {
        if (likes.isEmpty) {
          return Center(
            child: Text('Aucun like reçu pour le moment.', style: TextStyle(color: textColor)),
          );
        }
        return GridView.builder(
          key: const ValueKey('likes'),
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
                  debugPrint('[MATCH] Like back profile: ${p.id}. isMatch: $isMatch');
                  if (isMatch) {
                    ref.invalidate(matchesProvider);
                  }
                  ref.invalidate(pendingLikesProvider);
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

  Widget _buildMatchesTab(Color textColor) {
    final matchesAsync = ref.watch(matchesProvider);

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Text('Aucun match pour le moment.', style: TextStyle(color: textColor)),
          );
        }
        return GridView.builder(
          key: const ValueKey('matches'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    showReusableModalBottomSheet(
      context: context,
      title: 'Connexion avec ${p.name}',
      surface: surface,
      textPrimary: textPrimary,
      children: [
        ModalActionTile(
          icon: LucideIcons.user,
          label: 'Voir profil',
          textColor: Colors.black,
          backgroundColor: primary,
          onTap: () {
            Navigator.of(context).pop();
            context.push('/user-profile/${p.id}', extra: p.name);
          },
        ),
        const SizedBox(height: 12),
        ModalActionTile(
          icon: LucideIcons.flag,
          label: 'Signaler',
          textColor: Colors.red,
          isDangerous: true,
          onTap: () {
            Navigator.of(context).pop();
            // TODO: implémenter le signalement
          },
        ),
      ],
    );
  }
}
