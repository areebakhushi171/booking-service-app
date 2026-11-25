import 'package:flutter/foundation.dart';
import 'package:bookease/core/services/socket_service.dart';
import 'package:bookease/features/chat/data/models/chat_model.dart';
import 'package:bookease/features/chat/data/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;
  final SocketService? _socketService;

  List<ConversationModel> _conversations = [];
  final Map<String, List<MessageModel>> _messagesByConversation = {};
  final Set<String> _activeConversationIds = {};
  final Set<String> _typingUserIdsByConversation = {};
  final Set<String> _onlineUserIds = {};
  int _globalUnreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  ChatProvider(this._repository, [this._socketService]) {
    loadConversations();
  }

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get globalUnreadCount => _globalUnreadCount;

  int get unreadCount => _globalUnreadCount;

  List<MessageModel> messagesFor(String conversationId) =>
      List.unmodifiable(_messagesByConversation[conversationId] ?? const []);

  bool isTyping(String conversationId) =>
      _typingUserIdsByConversation.contains(conversationId);

  bool isUserOnline(String userId) => _onlineUserIds.contains(userId);

  Future<void> loadConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final list = await _repository.fetchConversations();
      final Map<String, ConversationModel> unique = {};
      for (final c in list) {
        final key =
            c.id.isNotEmpty ? c.id : '${c.propertyId}_${c.participantId}';
        unique[key] = c;
      }
      _conversations = unique.values.toList();
      _globalUnreadCount = _conversations.fold(
          0, (sum, conversation) => sum + conversation.unreadCount);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    final msgs = await _repository.fetchMessages(conversationId);
    msgs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _messagesByConversation[conversationId] = _uniqueMessages(msgs);
    notifyListeners();
    return messagesFor(conversationId);
  }

  Future<MessageModel> sendMessage(
      String conversationId, String content) async {
    final msg = await _repository.sendMessage(conversationId, content);
    _upsertMessage(msg);
    await loadConversations();
    return msg;
  }

  List<MessageModel> _uniqueMessages(Iterable<MessageModel> messages) {
    final unique = <String, MessageModel>{};
    for (final message in messages) {
      if (message.id.isNotEmpty) unique[message.id] = message;
    }
    return unique.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _upsertMessage(MessageModel message) {
    if (message.id.isEmpty || message.conversationId.isEmpty) return;
    final messages = _messagesByConversation.putIfAbsent(
      message.conversationId,
      () => [],
    );
    final index = messages.indexWhere((item) => item.id == message.id);
    if (index == -1) {
      messages.insert(0, message);
    } else {
      messages[index] = message;
    }
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void handleMessageNew(Map<String, dynamic> payload) {
    final rawMessage = payload['message'];
    if (rawMessage is! Map) return;
    final message = MessageModel.fromJson(
      rawMessage.map((key, value) => MapEntry(key.toString(), value)),
    );
    _upsertMessage(message);

    final conversationId =
        (payload['conversationId'] ?? message.conversationId).toString();
    final index = _conversations
        .indexWhere((conversation) => conversation.id == conversationId);
    if (index != -1) {
      final unreadCount =
          int.tryParse(payload['unreadCount']?.toString() ?? '');
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: message.content,
        updatedAt: message.createdAt,
        unreadCount: unreadCount,
      );
    }
    final globalCount =
        int.tryParse(payload['globalUnreadCount']?.toString() ?? '');
    if (globalCount != null) {
      _globalUnreadCount = globalCount;
    } else if (index != -1) {
      _globalUnreadCount =
          _conversations.fold(0, (sum, item) => sum + item.unreadCount);
    }
    notifyListeners();
    if (index == -1) loadConversations();

    if (_activeConversationIds.contains(conversationId)) {
      markRead(conversationId).catchError((Object error) {
        _errorMessage = error.toString();
        notifyListeners();
      });
    }
  }

  void handleMessageRead(Map<String, dynamic> payload) {
    final conversationId = payload['conversationId']?.toString();
    final rawIds = payload['messageIds'];
    if (conversationId == null || rawIds is! List) return;
    final messageIds = rawIds.map((id) => id.toString()).toSet();
    final messages = _messagesByConversation[conversationId];
    if (messages == null) return;

    _messagesByConversation[conversationId] = messages
        .map((message) => messageIds.contains(message.id)
            ? message.copyWith(isRead: true)
            : message)
        .toList();
    notifyListeners();
  }

  void handleUnreadCountUpdated(Map<String, dynamic> payload) {
    final count = int.tryParse(payload['unreadCount']?.toString() ?? '');
    if (count == null) return;
    _globalUnreadCount = count;
    notifyListeners();
  }

  void handleConversationUpdated(Map<String, dynamic> payload) {
    final rawConversation = payload['conversation'];
    if (rawConversation is Map) {
      final conversation = ConversationModel.fromJson(
        rawConversation.map((key, value) => MapEntry(key.toString(), value)),
      );
      final index =
          _conversations.indexWhere((item) => item.id == conversation.id);
      if (index == -1 && conversation.id.isNotEmpty) {
        _conversations.insert(0, conversation);
      } else if (index != -1) {
        _conversations[index] = conversation;
      }
      _globalUnreadCount =
          _conversations.fold(0, (sum, item) => sum + item.unreadCount);
      notifyListeners();
      return;
    }

    final conversationId = payload['conversationId']?.toString();
    final rawMessage = payload['latestMessage'];
    if (conversationId == null || rawMessage is! Map) return;
    final message = MessageModel.fromJson(
      rawMessage.map((key, value) => MapEntry(key.toString(), value)),
    );
    _upsertMessage(message);
    final index =
        _conversations.indexWhere((item) => item.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: message.content,
        updatedAt: message.createdAt,
      );
      _conversations.sort((a, b) => (b.updatedAt ??
              DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    }
    notifyListeners();
  }

  void handleTyping(Map<String, dynamic> payload, {required bool isTyping}) {
    final conversationId = payload['conversationId']?.toString();
    if (conversationId == null) return;
    if (isTyping) {
      _typingUserIdsByConversation.add(conversationId);
    } else {
      _typingUserIdsByConversation.remove(conversationId);
    }
    notifyListeners();
  }

  void handlePresence(Map<String, dynamic> payload) {
    final userId = payload['userId']?.toString();
    if (userId == null) return;
    if (payload['event'] == 'user:online') {
      _onlineUserIds.add(userId);
    } else {
      _onlineUserIds.remove(userId);
    }
    notifyListeners();
  }

  void handleSocketDisconnected() {
    if (_typingUserIdsByConversation.isEmpty) return;
    _typingUserIdsByConversation.clear();
    notifyListeners();
  }

  Future<bool> joinConversation(String conversationId) async {
    final service = _socketService;
    if (service == null) return false;
    _activeConversationIds.add(conversationId);
    if (!service.isConnected) return true;

    final joined = await service.joinConversation(conversationId);
    if (!joined) _activeConversationIds.remove(conversationId);
    return joined;
  }

  Future<void> leaveConversation(String conversationId) async {
    _activeConversationIds.remove(conversationId);
    _typingUserIdsByConversation.remove(conversationId);
    await _socketService?.leaveConversation(conversationId);
  }

  Future<void> handleSocketConnected() async {
    await loadConversations();
    for (final conversationId in _activeConversationIds.toList()) {
      await _socketService?.joinConversation(conversationId);
      await fetchMessages(conversationId);
      await markRead(conversationId);
    }
  }

  void sendTyping(String conversationId) =>
      _socketService?.sendTyping(conversationId);

  void stopTyping(String conversationId) =>
      _socketService?.stopTyping(conversationId);

  Future<ConversationModel> startConversation(
      {required String propertyId, String? participantId}) async {
    final existingIndex = _conversations.indexWhere(
      (c) =>
          c.propertyId == propertyId &&
          (participantId == null || c.participantId == participantId),
    );
    if (existingIndex != -1) {
      return _conversations[existingIndex];
    }
    final conv = await _repository.createConversation(
        propertyId: propertyId, participantId: participantId);
    await loadConversations();
    return conv;
  }

  Future<void> markRead(String conversationId) async {
    await _repository.markConversationRead(conversationId);
    await loadConversations();
  }
}
