import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'package:lolango_v2/core/errors/failures.dart';
import 'package:lolango_v2/core/utils/logger.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';
import '../domain/conversation_model.dart';
import '../domain/message_model.dart';

class MessagingRepository {
  final SupabaseClient _client;
  final ProfileRepository _profileRepository;

  MessagingRepository(this._client, this._profileRepository);

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthFailure("User not logged in");
    return user.id;
  }

  Future<List<ConversationModel>> getConversations() async {
    try {
      // 0. Auto-sync missing conversations for existing matches
      try {
        final matchesRes = await _client
            .from('matches')
            .select('id, user1_id, user2_id')
            .or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId');
        
        final convsRes = await _client
            .from('conversations')
            .select('match_id')
            .or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId');
            
        final existingMatchIds = (convsRes as List).map((c) => c['match_id'] as String).toSet();
        
        for (final row in matchesRes as List) {
          final matchId = row['id'] as String;
          if (!existingMatchIds.contains(matchId)) {
            AppLogger.d('[MESSAGING] Creating missing conversation for match $matchId');
            await _client.from('conversations').insert({
              'match_id': matchId,
              'user1_id': row['user1_id'],
              'user2_id': row['user2_id'],
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        }
      } catch (e) {
        AppLogger.e('[MESSAGING] Error auto-syncing conversations: $e');
      }

      // 1. Récupérer les conversations où l'utilisateur est impliqué
      final convRes = await _client
          .from('conversations')
          .select()
          .or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId')
          .order('updated_at', ascending: false);

      final conversations = convRes as List<dynamic>;
      
      // S'il n'y a pas de conversations, on retourne une liste vide
      if (conversations.isEmpty) return [];

      final List<ConversationModel> result = [];

      for (var row in conversations) {
        final otherUserId = row['user1_id'] == _currentUserId ? row['user2_id'] : row['user1_id'];
        
        // Fetch Other User Profile
        final profile = await _profileRepository.fetchDetailedProfileById(otherUserId);
        
        // Fetch Last Message
        final msgRes = await _client
            .from('messages')
            .select()
            .eq('conversation_id', row['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        MessageModel? lastMessage;
        if (msgRes != null) {
          lastMessage = MessageModel.fromMap(msgRes);
        }

        // Fetch Unread Count
        final unreadRes = await _client
            .from('messages')
            .select('id')
            .eq('conversation_id', row['id'])
            .eq('sender_id', otherUserId)
            .isFilter('read_at', null);
            
        final unreadCount = (unreadRes as List).length;

        if (profile != null) {
          result.add(ConversationModel(
            id: row['id'],
            matchId: row['match_id'],
            otherUser: profile,
            lastMessage: lastMessage,
            unreadCount: unreadCount,
            createdAt: DateTime.parse(row['created_at']).toLocal(),
          ));
        }
      }

      return result;
    } catch (e) {
      AppLogger.e('[MESSAGING] Error getting conversations: $e');
      throw Failure.from(e);
    }
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final res = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return (res as List).map((e) => MessageModel.fromMap(e)).toList();
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<void> sendMessage(String conversationId, String content, {String type = 'text', Map<String, dynamic>? metadata}) async {
    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _currentUserId,
        'content': content,
        'type': type,
        'metadata': metadata ?? {},
      });
      
      // Met à jour la date de la conversation
      await _client.from('conversations').update({
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', conversationId);

      // Fetch the conversation to get the other user id for notification
      final convRes = await _client.from('conversations').select('user1_id, user2_id').eq('id', conversationId).single();
      final targetId = convRes['user1_id'] == _currentUserId ? convRes['user2_id'] : convRes['user1_id'];
      
      // TODO: Envoyer une notification push
      await _client.from('notifications').insert({
        'user_id': targetId,
        'title': 'Nouveau message',
        'body': content,
      });

    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _client
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_id', _currentUserId)
          .isFilter('read_at', null);
    } catch (e) {
      AppLogger.e('[MESSAGING] Error marking as read: $e');
    }
  }
}
