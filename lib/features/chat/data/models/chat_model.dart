class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? json['chatId'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['sender']?['id'] ?? '').toString(),
      senderName: (json['senderName'] ?? json['sender']?['name'] ?? 'User').toString(),
      content: (json['content'] ?? json['message'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true || json['read'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };
}

class ConversationModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String? propertyImageUrl;
  final String participantId;
  final String participantName;
  final String? lastMessage;
  final DateTime? updatedAt;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    this.propertyImageUrl,
    required this.participantId,
    required this.participantName,
    this.lastMessage,
    this.updatedAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      propertyId: (json['propertyId'] ?? json['serviceId'] ?? '').toString(),
      propertyName: (json['propertyName'] ?? json['property']?['name'] ?? 'Service').toString(),
      propertyImageUrl: json['propertyImageUrl']?.toString() ?? json['property']?['imageUrl']?.toString(),
      participantId: (json['participantId'] ?? json['userId'] ?? '').toString(),
      participantName: (json['participantName'] ?? json['participant']?['name'] ?? 'Provider/Customer').toString(),
      lastMessage: json['lastMessage']?.toString() ?? json['snippet']?.toString(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      unreadCount: int.tryParse((json['unreadCount'] ?? 0).toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'propertyId': propertyId,
        'propertyName': propertyName,
        'propertyImageUrl': propertyImageUrl,
        'participantId': participantId,
        'participantName': participantName,
        'lastMessage': lastMessage,
        'updatedAt': updatedAt?.toIso8601String(),
        'unreadCount': unreadCount,
      };
}
