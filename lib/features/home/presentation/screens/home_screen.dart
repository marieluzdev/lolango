import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
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

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  void _handleAction(bool isLike, DetailedProfileModel p) async {
    if (_isProcessingAction) return;
    _isProcessingAction = true;

    // Retirer immédiatement la carte de la liste locale
    if (mounted) {
      setState(() {
        _cards.removeWhere((card) => card.profile.id == p.profile.id);
      });
    }

    // Cacher dans le provider (filtrage global)
    ref.read(hiddenProfilesProvider.notifier).update((state) {
      final newState = Set<String>.from(state);
      newState.add(p.profile.id);
      return newState;
    });

    try {
      if (isLike) {
        final isMatch = await ref.read(interactionRepositoryProvider).likeProfile(p.profile.id);
        if (isMatch) {
          debugPrint('[HOME] Match found for ${p.profile.id}! Incrementing badge.');
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
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final filterState = ref.watch(discoveryFilterProvider);
    final filteredAsync = ref.watch(filteredProfilesProvider);

    ref.listen<AsyncValue<List<DetailedProfileModel>>>(filteredProfilesProvider, (prev, next) {
      if (next.hasValue && next.value != null) {
        final filterChanged = filterState.hashCode != _lastFilterHash;
        if (filterChanged) {
          debugPrint('[HOME] Filter changed, resetting cards: ${next.value!.length}');
          setState(() {
            _cards = List.from(next.value!);
            _lastFilterHash = filterState.hashCode;
          });
        } else if (_cards.isEmpty && _lastFilterHash == -1) {
          debugPrint('[HOME] Initial load: ${next.value!.length} cards');
          setState(() {
            _cards = List.from(next.value!);
            _lastFilterHash = filterState.hashCode;
          });
        }
      }
    });

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
                      final textCol = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

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
                        surface: surface,
                        textPrimary: textCol,
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
                child: filteredAsync.when(
                  loading: () => const AppSpinner(),
                  error: (err, stack) => AppErrorState(
                    message: "Impossible de charger les profils.",
                    onRetry: () {
                      ref.invalidate(allProfilesProvider);
                      ref.invalidate(interactedProfilesProvider);
                    },
                  ),
                  data: (data) {
                    if (_cards.isEmpty && _lastFilterHash != -1) {
                      return AppEmptyState(
                        icon: LucideIcons.ghost,
                        title: "Plus aucun profil",
                        description: "Tu as swipé tous les profils disponibles avec ces filtres.",
                        actionLabel: "Voir tout le monde",
                        onAction: () {
                          ref.read(discoveryFilterProvider.notifier).state = DiscoveryFilter(
                            ageRange: const RangeValues(18, 80),
                          );
                        },
                      );
                    }

                    if (_cards.isEmpty) {
                       return const AppSpinner();
                    }

                    return CardSwiper(
                      controller: _swiperController,
                      cardsCount: _cards.length,
                      numberOfCardsDisplayed: _cards.length > 1 ? 2 : 1,
                      isLoop: false,
                      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                        if (index >= _cards.length) return const SizedBox.shrink();
                        final p = _cards[index];
                        return ProfileCard(
                          name: p.profile.name,
                          age: p.profile.age,
                          city: p.profile.city,
                          country: p.profile.country,
                          photoUrls: p.photoUrls,
                          bio: p.profile.bio,
                          socials: p.socials,
                          interests: p.interests,
                          onPass: () {
                            if (!_isProcessingAction) {
                               _swiperController.swipe(CardSwiperDirection.left);
                            }
                          },
                          onConnect: () {
                            if (!_isProcessingAction) {
                              _swiperController.swipe(CardSwiperDirection.right);
                            }
                          },
                        );
                      },
                      onSwipe: (previousIndex, currentIndex, direction) {
                        if (previousIndex >= _cards.length) return true;
                        if (_isProcessingAction) return false; // Prevent double swipe
                        
                        final p = _cards[previousIndex];
                        debugPrint('[HOME] onSwipe: ${p.profile.id}, direction: $direction');

                        _handleAction(direction == CardSwiperDirection.right, p);
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
