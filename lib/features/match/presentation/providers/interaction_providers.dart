import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/supabase/supabase_client.dart';
import 'package:lolango_v2/features/match/data/interaction_repository.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  return InteractionRepository(ref.watch(supabaseProvider));
});

final interactedProfilesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(interactionRepositoryProvider);
  return repo.getInteractedProfileIds();
});

final pendingLikesProvider = FutureProvider<List<DetailedProfileModel>>((
  ref,
) async {
  final repo = ref.read(interactionRepositoryProvider);
  return repo.getPendingLikes();
});

final matchesProvider = FutureProvider<List<DetailedProfileModel>>((ref) async {
  final repo = ref.read(interactionRepositoryProvider);
  return repo.getMatches();
});

// État local pour cacher immédiatement les profils dans l'UI sans attendre la BDD
final hiddenProfilesProvider = StateProvider<Set<String>>((ref) => {});

final matchNotificationBadgeProvider = StateProvider<int>((ref) => 0);
final seenLikesCountProvider = StateProvider<int>((ref) => 0);
final seenMatchesCountProvider = StateProvider<int>((ref) => 0);

// Onglet actif dans Match (0 = Likes reçus, 1 = Matchs)
final matchActiveTabProvider = StateProvider<int>((ref) => 0);
