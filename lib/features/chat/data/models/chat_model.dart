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
    final readAt = json['readAt'];
    return MessageModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      conversationId:
          (json['conversationId'] ?? json['chatId'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['sender']?['id'] ?? '').toString(),
      senderName:
          (json['senderName'] ?? json['sender']?['name'] ?? 'User').toString(),
      content: (json['content'] ?? json['message'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toUtc() ??
              DateTime.now().toUtc()
          : DateTime.now().toUtc(),
      isRead: json['isRead'] == true ||
          json['read'] == true ||
          (readAt != null && readAt.toString().isNotEmpty),
    );
  }

  MessageModel copyWith({bool? isRead}) => MessageModel(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );

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
  final String? participantAvatarUrl;
  final String? customerName;
  final String? customerAvatarUrl;
  final String? providerName;
  final String? providerAvatarUrl;
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
    this.participantAvatarUrl,
    this.customerName,
    this.customerAvatarUrl,
    this.providerName,
    this.providerAvatarUrl,
    this.lastMessage,
    this.updatedAt,
    this.unreadCount = 0,
  });

  ConversationModel copyWith({
    String? lastMessage,
    DateTime? updatedAt,
    int? unreadCount,
  }) =>
      ConversationModel(
        id: id,
        propertyId: propertyId,
        propertyName: propertyName,
        propertyImageUrl: propertyImageUrl,
        participantId: participantId,
        participantName: participantName,
        participantAvatarUrl: participantAvatarUrl,
        customerName: customerName,
        customerAvatarUrl: customerAvatarUrl,
        providerName: providerName,
        providerAvatarUrl: providerAvatarUrl,
        lastMessage: lastMessage ?? this.lastMessage,
        updatedAt: updatedAt ?? this.updatedAt,
        unreadCount: unreadCount ?? this.unreadCount,
      );

  String displayNameFor({required bool currentUserIsProvider}) {
    final name = currentUserIsProvider ? customerName : providerName;
    if (name != null && name.trim().isNotEmpty) return name;
    return participantName.trim().isNotEmpty &&
            participantName != 'Provider/Customer'
        ? participantName
        : (currentUserIsProvider ? 'Customer' : 'Service Provider');
  }

  String? avatarFor({required bool currentUserIsProvider}) {
    return currentUserIsProvider
        ? (customerAvatarUrl ?? participantAvatarUrl)
        : (providerAvatarUrl ?? participantAvatarUrl);
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final service = json['service'] is Map
        ? json['service'] as Map
        : (json['property'] is Map ? json['property'] as Map : const {});
    final customer =
        json['customer'] is Map ? json['customer'] as Map : const {};
    final provider = json['provider'] is Map
        ? json['provider'] as Map
        : (json['owner'] is Map ? json['owner'] as Map : const {});
    final participant =
        json['participant'] is Map ? json['participant'] as Map : const {};
    final messages =
        json['messages'] is List ? json['messages'] as List : const [];
    final latestMessage = json['latestMessage'] is Map
        ? json['latestMessage'] as Map
        : messages.isNotEmpty && messages.first is Map
            ? messages.first as Map
            : const {};
    final rawLastMessage =
        json['lastMessage'] ?? json['snippet'] ?? latestMessage['content'];

    String? text(dynamic value) =>
        value == null || value.toString().trim().isEmpty
            ? null
            : value.toString();

    return ConversationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      propertyId:
          (json['propertyId'] ?? json['serviceId'] ?? service['id'] ?? '')
              .toString(),
      propertyName: (json['propertyName'] ??
              service['name'] ??
              json['serviceName'] ??
              'Service')
          .toString(),
      propertyImageUrl: text(json['propertyImageUrl'] ??
          service['imageUrl'] ??
          service['mainImageUrl']),
      participantId:
          (json['participantId'] ?? json['userId'] ?? participant['id'] ?? '')
              .toString(),
      participantName: (json['participantName'] ??
              participant['name'] ??
              json['otherUser']?['name'] ??
              '')
          .toString(),
      participantAvatarUrl: text(participant['avatarUrl'] ??
          json['participantAvatarUrl'] ??
          json['otherUser']?['avatarUrl']),
      customerName: text(json['customerName'] ?? customer['name']),
      customerAvatarUrl:
          text(json['customerAvatarUrl'] ?? customer['avatarUrl']),
      providerName:
          text(json['providerName'] ?? provider['name'] ?? json['ownerName']),
      providerAvatarUrl: text(json['providerAvatarUrl'] ??
          provider['avatarUrl'] ??
          json['ownerAvatarUrl']),
      lastMessage: text(rawLastMessage),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toUtc()
          : null,
      unreadCount: json['unreadCount'] != null
          ? (int.tryParse(json['unreadCount'].toString()) ?? 0)
          : (json['unread'] != null
              ? (int.tryParse(json['unread'].toString()) ?? 0)
              : 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'propertyId': propertyId,
        'propertyName': propertyName,
        'propertyImageUrl': propertyImageUrl,
        'participantId': participantId,
        'participantName': participantName,
        'participantAvatarUrl': participantAvatarUrl,
        'customerName': customerName,
        'customerAvatarUrl': customerAvatarUrl,
        'providerName': providerName,
        'providerAvatarUrl': providerAvatarUrl,
        'lastMessage': lastMessage,
        'updatedAt': updatedAt?.toIso8601String(),
        'unreadCount': unreadCount,
      };
}
