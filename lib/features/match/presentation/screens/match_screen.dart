import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/core/models/profile_model.dart';
import 'package:lolango_v2/core/utils/logger.dart';
import 'package:lolango_v2/core/widgets/app_empty_state.dart';
import 'package:lolango_v2/core/widgets/app_error_state.dart';
import 'package:lolango_v2/core/widgets/app_loading.dart';
import 'package:lolango_v2/core/widgets/modal_action_tile.dart';
import 'package:lolango_v2/core/widgets/reusable_modal_bottom_sheet.dart';
import 'package:lolango_v2/core/widgets/search_bar_widget.dart';
import 'package:lolango_v2/features/match/presentation/providers/interaction_providers.dart';
import 'package:lolango_v2/features/match/presentation/widgets/blurred_profile_card.dart';
import 'package:lolango_v2/features/match/presentation/widgets/matched_profile_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  int _tabIndex = 0;
  String _searchQuery = '';

  static const _tabs = ['Likes reçus', 'Matchs'];

  // Dummy profile for skeleton
  static final _dummyProfile = DetailedProfileModel(
    profile: ProfileModel(
      id: 'dummy',
      name: 'Chargement',
      username: '@loading',
      age: 25,
      gender: 'unknown',
      city: 'Paris',
      country: 'France',
      bio: '...',
      discoveryPreferences: [],
    ),
    photoUrls: ['https://via.placeholder.com/300'],
    socials: {},
    interests: [],
  );

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
    final background = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    final pendingAsync = ref.watch(pendingLikesProvider);
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;
    final seenLikesCount = ref.watch(seenLikesCountProvider);
    final unreadLikesCount = (pendingCount - seenLikesCount).clamp(0, 999);
    
    final matchesAsync = ref.watch(matchesProvider);
    final matchesCount = matchesAsync.valueOrNull?.length ?? 0;
    final seenMatchesCount = ref.watch(seenMatchesCountProvider);
    final unreadMatchesCount = (matchesCount - seenMatchesCount).clamp(0, 999);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabIndex == 0 && pendingCount != seenLikesCount) {
        ref.read(seenLikesCountProvider.notifier).state = pendingCount;
      } else if (_tabIndex == 1 && matchesCount != seenMatchesCount) {
        ref.read(seenMatchesCountProvider.notifier).state = matchesCount;
      }
    });

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

              // Segmented control
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
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
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _tabs[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (i == 0 && unreadLikesCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unreadLikesCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (i == 1 && unreadMatchesCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unreadMatchesCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.04),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_tabIndex),
                        child: _tabIndex == 0
                            ? _buildPendingLikesTab()
                            : _buildMatchesTab(),
                      ),
                    ),
                    // ── Barre de recherche fixe en bas au centre ──
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SearchBarWidget(
                          hint: 'Rechercher...',
                          onChanged: (q) => setState(() => _searchQuery = q),
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

  Widget _buildPendingLikesTab() {
    final pendingAsync = ref.watch(pendingLikesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(pendingLikesProvider),
      child: pendingAsync.when(
        data: (likes) {
          if (likes.isEmpty) {
            return const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: LucideIcons.heart,
                    title: 'Aucun like',
                    description:
                        'Tu n\'as pas encore reçu de like. Continue de swiper !',
                  ),
                ),
              ],
            );
          }
          return GridView.builder(
            key: const ValueKey('likes'),
            physics: const AlwaysScrollableScrollPhysics(),
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
                  ref
                      .read(interactionRepositoryProvider)
                      .likeProfile(p.profile.id)
                      .then((isMatch) {
                        AppLogger.d(
                          '[MATCH] Like back profile: ${p.profile.id}. isMatch: $isMatch',
                        );
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
        loading: () => AppLoading(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return BlurredProfileCard(profile: _dummyProfile, onLike: () {});
            },
          ),
        ),
        error: (e, st) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: AppErrorState(
                message: "Impossible de charger les likes.",
                onRetry: () => ref.invalidate(pendingLikesProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesTab() {
    final matchesAsync = ref.watch(matchesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(matchesProvider),
      child: matchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: LucideIcons.messageCircleHeart,
                    title: 'Aucun match',
                    description:
                        'Les matchs apparaîtront ici quand l\'intérêt sera mutuel.',
                  ),
                ),
              ],
            );
          }
          return GridView.builder(
            key: const ValueKey('matches'),
            physics: const AlwaysScrollableScrollPhysics(),
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
        loading: () => AppLoading(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return MatchedProfileCard(profile: _dummyProfile, onTap: () {});
            },
          ),
        ),
        error: (e, st) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: AppErrorState(
                message: "Impossible de charger les matchs.",
                onRetry: () => ref.invalidate(matchesProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSocialsModal(BuildContext context, DetailedProfileModel pDetailed) {
    final p = pDetailed.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
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
