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

final conversationsProvider = FutureProvider<List<ConversationModel>>((ref) async {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.getConversations();
});

final messagesProvider = FutureProvider.family<List<MessageModel>, String>((ref, conversationId) async {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.getMessages(conversationId);
});

final unreadMessagesCountProvider = FutureProvider<int>((ref) async {
  final conversations = await ref.watch(conversationsProvider.future);
  int totalUnread = 0;
  for (var conv in conversations) {
    totalUnread += conv.unreadCount;
  }
  return totalUnread;
});
