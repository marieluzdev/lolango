import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/supabase/supabase_client.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/features/discovery/data/discovery_repository.dart';
import '../widgets/filter_modal.dart';
import 'package:lolango_v2/features/match/presentation/providers/interaction_providers.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(ref.watch(supabaseProvider));
});

final discoveryFilterProvider = StateProvider<DiscoveryFilter>(
  (ref) => DiscoveryFilter(ageRange: const RangeValues(18, 80)),
);

// ---------------------------------------------------------------------------
// DiscoveryNotifier — gère la liste paginée des profils
// ---------------------------------------------------------------------------

class DiscoveryState {
  final List<DetailedProfileModel> profiles;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;

  const DiscoveryState({
    this.profiles = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
  });

  DiscoveryState copyWith({
    List<DetailedProfileModel>? profiles,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
  }) {
    return DiscoveryState(
      profiles: profiles ?? this.profiles,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

class DiscoveryNotifier extends AsyncNotifier<DiscoveryState> {
  static const int _pageSize = 20;

  @override
  Future<DiscoveryState> build() async {
    // Réagit aux changements de filtres : recharge depuis la page 0
    final filter = ref.watch(discoveryFilterProvider);
    final interactedIds = await ref.read(interactedProfilesProvider.future);
    final hiddenIds = ref.read(hiddenProfilesProvider);

    final excludeIds = {...interactedIds, ...hiddenIds};

    final repo = ref.read(discoveryRepositoryProvider);
    final profiles = await repo.fetchProfiles(
      page: 0,
      limit: _pageSize,
      filter: filter,
      excludeIds: excludeIds,
    );

    return DiscoveryState(
      profiles: profiles,
      page: 0,
      hasMore: profiles.length == _pageSize,
      isLoadingMore: false,
    );
  }

  /// Charge la page suivante et ajoute les résultats à la liste existante.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    // Signal : chargement en cours
    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final filter = ref.read(discoveryFilterProvider);
      final interactedIds = await ref.read(interactedProfilesProvider.future);
      final hiddenIds = ref.read(hiddenProfilesProvider);
      final excludeIds = {
        ...interactedIds,
        ...hiddenIds,
        ...current.profiles.map((p) => p.profile.id),
      };

      final nextPage = current.page + 1;
      final repo = ref.read(discoveryRepositoryProvider);
      final newProfiles = await repo.fetchProfiles(
        page: nextPage,
        limit: _pageSize,
        filter: filter,
        excludeIds: excludeIds,
      );

      state = AsyncData(
        current.copyWith(
          profiles: [...current.profiles, ...newProfiles],
          page: nextPage,
          hasMore: newProfiles.length == _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      // Ne pas écraser toute la liste — juste stopper le chargement
      state = AsyncData(current.copyWith(isLoadingMore: false, hasMore: false));
    }
  }

  /// Rafraîchit complètement la liste depuis la page 0.
  Future<void> refresh() async {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }
}

final discoveryNotifierProvider =
    AsyncNotifierProvider<DiscoveryNotifier, DiscoveryState>(
      DiscoveryNotifier.new,
    );

// ---------------------------------------------------------------------------
// Keep backward-compatible alias so existing code still compiles
// ---------------------------------------------------------------------------

/// @deprecated — Utiliser `discoveryNotifierProvider` à la place.
final allProfilesProvider = FutureProvider<List<DetailedProfileModel>>((
  ref,
) async {
  final state = await ref.watch(discoveryNotifierProvider.future);
  return state.profiles;
});

/// @deprecated — Utiliser `discoveryNotifierProvider` à la place.
final filteredProfilesProvider =
    Provider<AsyncValue<List<DetailedProfileModel>>>((ref) {
      return ref.watch(discoveryNotifierProvider).whenData((s) => s.profiles);
    });
