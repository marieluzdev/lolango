import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:lolango_v2/features/profile/presentation/providers/profile_provider.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/filter_modal.dart';

final discoveryFilterInitProvider = Provider<void>((ref) {
  final userProfileAsync = ref.watch(profileProvider);

  userProfileAsync.whenData((userProfile) {
    if (userProfile != null) {
      final filterState = ref.read(discoveryFilterProvider);
      final prefs = userProfile.profile.discoveryPreferences;

      final isDefault =
          filterState.ageRange.start == 18 &&
          filterState.ageRange.end == 80 &&
          filterState.gender == null &&
          (filterState.city == null || filterState.city == '') &&
          filterState.socials.isEmpty;

      if (prefs.isNotEmpty && isDefault) {
        final first = prefs.first.toLowerCase();
        String? mapped;
        if (first.contains('fem')) {
          mapped = 'female';
        } else if (first.contains('hom')) {
          mapped = 'male';
        }

        if (mapped != null) {
          // Utilisation de Future.microtask pour éviter de modifier un state
          // pendant la phase de build si ce provider est regardé dans un widget
          Future.microtask(() {
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
  });
});
