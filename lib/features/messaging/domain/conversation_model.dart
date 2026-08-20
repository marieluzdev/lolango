import 'package:lolango_v2/core/models/detailed_profile_model.dart';
import 'message_model.dart';

class ConversationModel {
  final String id;
  final String matchId;
  final DetailedProfileModel otherUser;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.matchId,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
  });

  factory ConversationModel.fromMap(
    Map<String, dynamic> map,
    DetailedProfileModel otherUser,
    String currentUserId,
  ) {
    // Calculer le nombre de messages non lus si la requête le fournit
    // Cela nécessite une aggrégation SQL ou un fetch séparé, 
    // ou bien le repository le calcule
    
    // Par exemple, si la db renvoie un champ 'unread_count' dans une query spéciale:
    final unreadCount = int.tryParse(map['unread_count']?.toString() ?? '0') ?? 0;

    return ConversationModel(
      id: map['id']?.toString() ?? '',
      matchId: map['match_id']?.toString() ?? '',
      otherUser: otherUser,
      createdAt: DateTime.parse(map['created_at'].toString()).toLocal(),
      unreadCount: unreadCount,
    );
  }
  
  ConversationModel copyWith({
    String? id,
    String? matchId,
    DetailedProfileModel? otherUser,
    MessageModel? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
