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
      // Initialize the active tab provider
      ref.read(matchActiveTabProvider.notifier).state = _tabIndex;
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
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
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
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 4),
              // Dynamic info text
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tabIndex == 0
                        ? (pendingCount == 1
                            ? '1 like reçu'
                            : '$pendingCount likes reçus')
                        : (matchesCount == 1
                            ? '1 connexion'
                            : '$matchesCount connexions'),
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Segmented control
              // ============================================================
              // SEGMENTED CONTROL
              // ============================================================
              Container(
                width: double.infinity,
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Stack(
                  children: [
                    // ========================================================
                    // INDICATEUR QUI GLISSE
                    // ========================================================
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: _tabIndex == 0
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
                        heightFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.secondaryDark
                                : AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ========================================================
                    // TEXTES DES ONGLETS
                    // ========================================================
                    Row(
                      children: List.generate(_tabs.length, (i) {
                        final isSelected = _tabIndex == i;

                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (_tabIndex == i) return;

                              setState(() {
                                _tabIndex = i;
                              });
                              ref.read(matchActiveTabProvider.notifier).state = i;
                            },
                            child: SizedBox(
                              height: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _tabs[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? (isDark
                                                ? Colors.black
                                                : Colors.white)
                                          : textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),

                                  // Badge Likes
                                  if (i == 0 && unreadLikesCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
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

                                  // Badge Matchs
                                  if (i == 1 && unreadMatchesCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
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
                  ],
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
            padding: const EdgeInsets.only(top: 16),
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
            padding: const EdgeInsets.only(top: 16),
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
          textColor: textPrimary,
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
