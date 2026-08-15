import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';

class ProfileStatusNotifier extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() async {
    final user = ref.watch(authViewModelProvider).valueOrNull;
    if (user == null) {
      return false;
    }
    
    try {
      return await ref.read(profileRepositoryProvider).hasCompletedProfile();
    } catch (_) {
      return false;
    }
  }

  void markAsCompleted() {
    state = const AsyncData(true);
  }
}

final profileStatusProvider = AsyncNotifierProvider<ProfileStatusNotifier, bool>(() {
  return ProfileStatusNotifier();
});
