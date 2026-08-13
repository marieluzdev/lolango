import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/profile_card.dart';
import 'package:lolango_v2/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:lolango_v2/features/discovery/domain/profile_model.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/filter_modal.dart';
import 'package:lolango_v2/core/widgets/reusable_modal_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final filtered = ref.watch(filteredProfilesProvider);
    final filterState = ref.watch(discoveryFilterProvider);
    final currentUserAsync = ref.watch(currentUserProfileProvider);

    // Initialisation du filtre avec les préférences onboarding.
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
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun profil correspondant pour le moment.',
                          style: TextStyle(color: textPrimary),
                        ),
                      )
                    : CardSwiper(
                        controller: _swiperController,
                        cardsCount: filtered.length,
                        numberOfCardsDisplayed: filtered.length > 1 ? 2 : 1,
                        cardBuilder:
                            (context, index, percentThresholdX, percentThresholdY) {
                          final p = filtered[index];
                          return ProfileCard(
                            name: p.name,
                            age: p.age,
                            city: p.city,
                            country: p.country,
                            photoUrls: p.photoUrls,
                            bio: p.bio,
                            socials: p.socials,
                            interests: p.interests,
                            onPass: () => _swiperController
                                .swipe(CardSwiperDirection.left),
                            onConnect: () => _swiperController
                                .swipe(CardSwiperDirection.right),
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
        if (p.bio != null && p.bio!.isNotEmpty) ...[
          Text(p.bio!, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
