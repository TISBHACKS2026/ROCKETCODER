class Conversation {
  final String id;
  final String? itemId;
  final DateTime createdAt;
  final String? otherParticipantName;

  Conversation({
    required this.id,
    this.itemId,
    required this.createdAt,
    this.otherParticipantName,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      itemId: json['item_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderEmail;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderEmail: json['sender_email'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}