import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/profile_model.dart';
import '../../data/discovery_repository.dart';
import '../widgets/filter_modal.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';
import 'package:lolango_v2/features/match/presentation/providers/interaction_providers.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(Supabase.instance.client);
});

final discoveryFilterProvider = StateProvider<DiscoveryFilter>(
  (ref) => DiscoveryFilter(ageRange: const RangeValues(18, 80)),
);

final allProfilesProvider = FutureProvider<List<ProfileModel>>((ref) async {
  final repo = ref.read(discoveryRepositoryProvider);
  return repo.fetchProfiles();
});

final currentUserProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final profileRepo = ref.read(profileRepositoryProvider);
  return profileRepo.fetchProfile();
});

final filteredProfilesProvider = Provider<List<ProfileModel>>((ref) {
  final filter = ref.watch(discoveryFilterProvider);
  final all = ref.watch(allProfilesProvider).value ?? [];
  final interactedIds = ref.watch(interactedProfilesProvider).value ?? [];
  final hiddenIds = ref.watch(hiddenProfilesProvider);

  debugPrint('filteredProfilesProvider: all=${all.length}, interacted=${interactedIds.length}, hidden=${hiddenIds.length}');

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

  return all.where((p) {
    if (interactedIds.contains(p.id) || hiddenIds.contains(p.id)) return false;
    
    final ageOk = p.age == null ||
        (p.age! >= filter.ageRange.start && p.age! <= filter.ageRange.end);
    final genderOk =
        filter.gender == null || matchesPref(p.gender, filter.gender);
    final cityOk = filter.city == null ||
        (p.city?.toLowerCase().contains(filter.city!.toLowerCase()) ?? false);
    final socialsOk = filter.socials.isEmpty ||
        filter.socials.any(
          (s) => p.socials.keys.map((k) => k.toLowerCase()).contains(s),
        );
    return ageOk && genderOk && cityOk && socialsOk;
  }).toList();
});
