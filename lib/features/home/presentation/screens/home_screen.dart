import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/core/utils/logger.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/profile_card.dart';
import 'package:lolango_v2/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:lolango_v2/features/discovery/presentation/providers/discovery_filter_init_provider.dart';
import 'package:lolango_v2/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:lolango_v2/features/match/presentation/providers/interaction_providers.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/filter_modal.dart';
import 'package:lolango_v2/core/widgets/reusable_modal_bottom_sheet.dart';
import 'package:lolango_v2/core/widgets/app_empty_state.dart';
import 'package:lolango_v2/core/widgets/app_error_state.dart';
import 'package:lolango_v2/core/widgets/app_loading.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  List<DetailedProfileModel> _cards = [];
  int _lastFilterHash = -1;
  bool _isProcessingAction = false;
  bool _isFinished = false;

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  void _handleAction(bool isLike, DetailedProfileModel p) async {
    if (_isProcessingAction) return;
    _isProcessingAction = true;



    // Cacher dans le provider (filtrage global)
    ref.read(hiddenProfilesProvider.notifier).update((state) {
      final newState = Set<String>.from(state);
      newState.add(p.profile.id);
      return newState;
    });

    try {
      if (isLike) {
        final isMatch = await ref
            .read(interactionRepositoryProvider)
            .likeProfile(p.profile.id);
        if (isMatch) {
          AppLogger.d(
            '[HOME] Match found for ${p.profile.id}! Incrementing badge.',
          );
          ref.read(matchNotificationBadgeProvider.notifier).state++;
          ref.invalidate(matchesProvider);
        }
      } else {
        await ref.read(interactionRepositoryProvider).passProfile(p.profile.id);
      }
    } finally {
      _isProcessingAction = false;
      ref.invalidate(interactedProfilesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écoute de l'initialisation du filtre
    ref.watch(discoveryFilterInitProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    final filterState = ref.watch(discoveryFilterProvider);
    final filteredAsync = ref.watch(filteredProfilesProvider);

    ref.listen<AsyncValue<List<DetailedProfileModel>>>(
      filteredProfilesProvider,
      (prev, next) {
        if (next.hasValue && next.value != null) {
          final filterChanged = filterState.hashCode != _lastFilterHash;
          if (filterChanged) {
            AppLogger.d(
              '[HOME] Filter changed, resetting cards: ${next.value!.length}',
            );
            setState(() {
              _isFinished = false;
              _cards = List.from(next.value!);
              _lastFilterHash = filterState.hashCode;
            });
          } else if (_cards.isEmpty && _lastFilterHash == -1) {
            AppLogger.d('[HOME] Initial load: ${next.value!.length} cards');
            setState(() {
              _cards = List.from(next.value!);
              _lastFilterHash = filterState.hashCode;
            });
          } else if (next.value!.length > _cards.length) {
            AppLogger.d('[HOME] Pagination load: ${next.value!.length} cards');
            setState(() {
              _isFinished = false;
              _cards = List.from(next.value!);
            });
          }
        }
      },
    );

    return Scaffold(
      backgroundColor: backgroundColor,
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
                    'Accueil',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final surface = Theme.of(context).cardColor;
                      final textCol =
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.black;

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

                      await showReusableModalBottomSheet(
                        context: context,
                        title: 'Filtrer',
                        surface: surface,
                        textPrimary: textCol,
                        children: [
                          FilterModal(
                            initial: initial,
                            onFilterChanged: (newFilter) {
                              ref.read(discoveryFilterProvider.notifier).state = newFilter;
                            },
                          ),
                        ],
                      );
                    },
                    icon: const Icon(LucideIcons.slidersHorizontal),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredAsync.when(
                  loading: () => const AppLoading(
                    child: ProfileCard(
                      name: 'Chargement',
                      age: 25,
                      city: 'Ville',
                      photoUrls: [],
                    ),
                  ),
                  error: (err, stack) => AppErrorState(
                    message: "Impossible de charger les profils.",
                    onRetry: () {
                      ref.invalidate(allProfilesProvider);
                      ref.invalidate(interactedProfilesProvider);
                    },
                  ),
                  data: (data) {
                    if (_isFinished || (_cards.isEmpty && _lastFilterHash != -1)) {
                      final hasRestrictive = filterState.isRestrictive;
                      return AppEmptyState(
                        icon: LucideIcons.ghost,
                        title: hasRestrictive ? "Plus aucun profil" : "C'est tout pour le moment",
                        description: hasRestrictive
                            ? "Tu as swipé tous les profils disponibles avec ces filtres."
                            : "Reviens plus tard pour découvrir de nouveaux profils.",
                        actionLabel: hasRestrictive ? "Voir tout le monde" : null,
                        onAction: hasRestrictive
                            ? () {
                                ref
                                    .read(discoveryFilterProvider.notifier)
                                    .state = DiscoveryFilter(
                                  ageRange: const RangeValues(18, 80),
                                );
                              }
                            : null,
                      );
                    }

                    if (_cards.isEmpty) {
                      return const AppLoading(
                        child: ProfileCard(
                          name: 'Chargement',
                          age: 25,
                          city: 'Ville',
                          photoUrls: [],
                        ),
                      );
                    }

                    return CardSwiper(
                      controller: _swiperController,
                      cardsCount: _cards.length,
                      numberOfCardsDisplayed: _cards.length > 1 ? 2 : 1,
                      isLoop: false,
                      onEnd: () {
                        final hasMore = ref.read(discoveryNotifierProvider).valueOrNull?.hasMore ?? false;
                        if (!hasMore) {
                          setState(() {
                            _isFinished = true;
                          });
                        } else {
                          ref.read(discoveryNotifierProvider.notifier).loadMore();
                        }
                      },
                      cardBuilder:
                          (
                            context,
                            index,
                            percentThresholdX,
                            percentThresholdY,
                          ) {
                            if (index >= _cards.length)
                              return const SizedBox.shrink();
                            final p = _cards[index];
                            return ProfileCard(
                              name: p.profile.name,
                              age: p.profile.age,
                              city: p.profile.city,
                              photoUrls: p.photoUrls,
                              bio: p.profile.bio,
                              socials: p.socials,
                              blurredSocials: p.getBlurredSocials(false),
                              interests: p.interests,
                              isMatched: false,
                              onPass: () {
                                if (!_isProcessingAction) {
                                  _swiperController.swipe(
                                    CardSwiperDirection.left,
                                  );
                                }
                              },
                              onConnect: () {
                                if (!_isProcessingAction) {
                                  _swiperController.swipe(
                                    CardSwiperDirection.right,
                                  );
                                }
                              },
                            );
                          },
                      onSwipe: (previousIndex, currentIndex, direction) {
                        if (previousIndex >= _cards.length) return true;
                        if (_isProcessingAction)
                          return false; // Prevent double swipe

                        if (currentIndex != null && currentIndex >= _cards.length - 3) {
                          ref.read(discoveryNotifierProvider.notifier).loadMore();
                        }

                        final p = _cards[previousIndex];
                        AppLogger.d(
                          '[HOME] onSwipe: ${p.profile.id}, direction: $direction',
                        );

                        _handleAction(
                          direction == CardSwiperDirection.right,
                          p,
                        );
                        return true;
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
}
