import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';
import '../domain/social_visibility_model.dart';

final hasSeenPrivacyModalProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.hasSeenPrivacyModal();
});

class SocialVisibilityState {
  final SocialVisibility mode;
  final List<String> visiblePlatforms;

  const SocialVisibilityState({
    required this.mode,
    this.visiblePlatforms = const [],
  });
}

class SocialVisibilityNotifier extends AsyncNotifier<SocialVisibilityState> {
  @override
  Future<SocialVisibilityState> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    final profile = await repo.fetchProfile();
    
    if (profile == null) {
      return const SocialVisibilityState(mode: SocialVisibility.afterMatch);
    }
    
    final modeStr = profile['social_visibility'] as String?;
    final mode = SocialVisibility.fromDbString(modeStr);
    
    List<String> platforms = [];
    final rawPlatforms = profile['visible_socials'];
    if (rawPlatforms is List) {
      platforms = rawPlatforms.map((e) => e.toString()).toList();
    }
    
    return SocialVisibilityState(mode: mode, visiblePlatforms: platforms);
  }

  Future<void> saveVisibility(SocialVisibility mode, List<String> visiblePlatforms) async {
    final repo = ref.read(profileRepositoryProvider);
    
    // Optimistic update
    state = AsyncData(SocialVisibilityState(mode: mode, visiblePlatforms: visiblePlatforms));
    
    try {
      await repo.updateSocialVisibility(mode.toDbString(), visiblePlatforms);
    } catch (e) {
      // Revert on error
      ref.invalidateSelf();
      rethrow;
    }
  }

  Future<void> markPrivacyModalSeen() async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.markPrivacyModalSeen();
    ref.invalidate(hasSeenPrivacyModalProvider);
  }
}

final socialVisibilityProvider = AsyncNotifierProvider<SocialVisibilityNotifier, SocialVisibilityState>(
  SocialVisibilityNotifier.new,
);
