import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lolango_v2/features/match/data/interaction_repository.dart';
import 'package:lolango_v2/features/discovery/domain/profile_model.dart';

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  return InteractionRepository(Supabase.instance.client);
});

final interactedProfilesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(interactionRepositoryProvider);
  return repo.getInteractedProfileIds();
});

final pendingLikesProvider = FutureProvider<List<ProfileModel>>((ref) async {
  final repo = ref.read(interactionRepositoryProvider);
  return repo.getPendingLikes();
});

final matchesProvider = FutureProvider<List<ProfileModel>>((ref) async {
  final repo = ref.read(interactionRepositoryProvider);
  return repo.getMatches();
});

// État local pour cacher immédiatement les profils dans l'UI sans attendre la BDD
final hiddenProfilesProvider = StateProvider<Set<String>>((ref) => {});

final matchNotificationBadgeProvider = StateProvider<int>((ref) => 0);
