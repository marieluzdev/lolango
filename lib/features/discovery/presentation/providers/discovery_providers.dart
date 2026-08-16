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

final allProfilesProvider = FutureProvider<List<DetailedProfileModel>>((ref) async {
  final repo = ref.read(discoveryRepositoryProvider);
  return repo.fetchProfiles();
});

final filteredProfilesProvider = Provider<AsyncValue<List<DetailedProfileModel>>>((ref) {
  final filter = ref.watch(discoveryFilterProvider);
  final allAsync = ref.watch(allProfilesProvider);
  final interactedAsync = ref.watch(interactedProfilesProvider);
  final hiddenIds = ref.watch(hiddenProfilesProvider);

  if (allAsync.hasError) {
    return AsyncValue.error(allAsync.error!, allAsync.stackTrace!);
  }

  if (interactedAsync.hasError) {
    return AsyncValue.error(interactedAsync.error!, interactedAsync.stackTrace!);
  }

  if (!allAsync.hasValue || !interactedAsync.hasValue) {
    return const AsyncValue.loading();
  }

  final all = allAsync.requireValue;
  final interactedIds = interactedAsync.requireValue;

  bool matchesPref(String? profileGender, String? pref) {
    if (pref == null) return true;
    final pg = profileGender?.toLowerCase() ?? '';
    final pf = pref.toLowerCase();
    if (pf.contains('fem')) return pg.contains('fem');
    if (pf.contains('hom')) return pg.contains('hom');
    if (pf.contains('female')) return pg.contains('fem') || pg.contains('female');
    if (pf.contains('male')) return pg.contains('hom') || pg.contains('male');
    return false;
  }

  final filteredList = all.where((detailedP) {
    final p = detailedP.profile;
    if (interactedIds.contains(p.id) || hiddenIds.contains(p.id)) return false;
    
    final ageOk = p.age == null ||
        (p.age! >= filter.ageRange.start && p.age! <= filter.ageRange.end);
    final genderOk =
        filter.gender == null || matchesPref(p.gender, filter.gender);
    final cityOk = filter.city == null ||
        (p.city?.toLowerCase().contains(filter.city!.toLowerCase()) ?? false);
    final socialsOk = filter.socials.isEmpty ||
        filter.socials.any(
          (s) => detailedP.socials.keys.map((k) => k.toLowerCase()).contains(s),
        );
    return ageOk && genderOk && cityOk && socialsOk;
  }).toList();

  return AsyncValue.data(filteredList);
});
