import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(Supabase.instance.client);
});

class OnboardingViewModel extends StateNotifier<AsyncValue<void>> {
  final OnboardingRepository repository;

  OnboardingViewModel(this.repository) : super(const AsyncData(null));

  Future<bool> checkUsernameAvailability(String username) async {
    state = const AsyncLoading();
    try {
      final result = await repository.checkUsernameAvailability(username);
      state = const AsyncData(null);
      return result;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }

  Future<void> saveProfile(Map<String, dynamic> payload) async {
    state = const AsyncLoading();
    try {
      print('DEBUG onboarding viewmodel: calling repository.saveProfile');
      await repository.saveProfile(payload);
      print('DEBUG onboarding viewmodel: repository.saveProfile success');
      state = const AsyncData(null);
    } catch (error, stack) {
      print('DEBUG onboarding viewmodel: repository.saveProfile failed');
      print('DEBUG onboarding viewmodel: error=$error');
      print('DEBUG onboarding viewmodel: stack=$stack');
      state = AsyncError(error, stack);
      rethrow;
    }
  }
}

final onboardingViewModelProvider = StateNotifierProvider<OnboardingViewModel, AsyncValue<void>>((ref) {
  return OnboardingViewModel(ref.watch(onboardingRepositoryProvider));
});
