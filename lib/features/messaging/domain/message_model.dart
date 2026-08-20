class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type; // 'text' ou 'social_share'
  final Map<String, dynamic>? metadata;
  final DateTime? readAt;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    this.metadata,
    this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id']?.toString() ?? '',
      conversationId: map['conversation_id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      type: map['type']?.toString() ?? 'text',
      metadata: map['metadata'] as Map<String, dynamic>?,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at'].toString()).toLocal() : null,
      createdAt: DateTime.parse(map['created_at'].toString()).toLocal(),
    );
  }
}
