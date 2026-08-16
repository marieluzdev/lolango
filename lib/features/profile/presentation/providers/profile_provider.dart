import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/core/errors/failures.dart';

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, DetailedProfileModel?>(
      ProfileNotifier.new,
    );

class ProfileNotifier extends AsyncNotifier<DetailedProfileModel?> {
  @override
  Future<DetailedProfileModel?> build() async {
    return ref.read(profileRepositoryProvider).fetchDetailedProfile();
  }

  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .fetchDetailedProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(Failure.from(e), st);
    }
  }
}
