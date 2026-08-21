import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/supabase/supabase_client.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';
import 'package:lolango_v2/features/messaging/data/messaging_repository.dart';
import 'package:lolango_v2/features/messaging/domain/conversation_model.dart';
import 'package:lolango_v2/features/messaging/domain/message_model.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(
    ref.watch(supabaseProvider),
    ref.watch(profileRepositoryProvider),
  );
});

// ── Conversations : cache persistant (keepAlive) ─────────────────────────────
// Les conversations restent en mémoire, on invalide manuellement si besoin.
final conversationsProvider = AsyncNotifierProvider<ConversationsNotifier, List<ConversationModel>>(
  ConversationsNotifier.new,
);

class ConversationsNotifier extends AsyncNotifier<List<ConversationModel>> {
  @override
  Future<List<ConversationModel>> build() async {
    // keepAlive : ne jamais disposer automatiquement
    ref.keepAlive();
    final repo = ref.read(messagingRepositoryProvider);
    return repo.getConversations();
  }

  /// Recharge les conversations depuis le serveur.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(messagingRepositoryProvider).getConversations(),
    );
  }
}

// ── Messages : cache par conversation (keepAlive) ────────────────────────────
// Chaque conversation est mise en cache séparément.
// Quand on revient dans une conversation déjà ouverte, les messages
// s'affichent instantanément et un refresh silencieux se fait en arrière-plan.
final messagesProvider =
    AsyncNotifierProvider.family<MessagesNotifier, List<MessageModel>, String>(
  MessagesNotifier.new,
);

class MessagesNotifier extends FamilyAsyncNotifier<List<MessageModel>, String> {
  @override
  Future<List<MessageModel>> build(String arg) async {
    // keepAlive : garder les messages en cache tant que l'app est ouverte.
    ref.keepAlive();
    final repo = ref.read(messagingRepositoryProvider);
    return repo.getMessages(arg);
  }

  /// Refresh silencieux : garde les données existantes visibles
  /// pendant que le nouveau fetch se termine.
  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final fresh = await ref.read(messagingRepositoryProvider).getMessages(arg);
      state = AsyncData(fresh);
    } catch (e, st) {
      // En cas d'erreur, on garde les données précédentes
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
    }
  }
}

// ── Unread count ─────────────────────────────────────────────────────────────
final unreadMessagesCountProvider = FutureProvider<int>((ref) async {
  final conversations = await ref.watch(conversationsProvider.future);
  int totalUnread = 0;
  for (var conv in conversations) {
    totalUnread += conv.unreadCount;
  }
  return totalUnread;
});
