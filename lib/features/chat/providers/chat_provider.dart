import 'package:flutter/foundation.dart';
import 'package:bookease/features/chat/data/models/chat_model.dart';
import 'package:bookease/features/chat/data/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;

  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;

  ChatProvider(this._repository) {
    loadConversations();
  }

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  Future<void> loadConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final list = await _repository.fetchConversations();
      final Map<String, ConversationModel> unique = {};
      for (final c in list) {
        final key = c.id.isNotEmpty ? c.id : '${c.propertyId}_${c.participantId}';
        if (!unique.containsKey(key)) {
          unique[key] = c;
        }
      }
      _conversations = unique.values.toList();
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
    return msgs;
  }

  Future<MessageModel> sendMessage(String conversationId, String content) async {
    final msg = await _repository.sendMessage(conversationId, content);
    await loadConversations();
    return msg;
  }

  Future<ConversationModel> startConversation({required String propertyId, String? participantId}) async {
    final existingIndex = _conversations.indexWhere(
      (c) => c.propertyId == propertyId && (participantId == null || c.participantId == participantId),
    );
    if (existingIndex != -1) {
      return _conversations[existingIndex];
    }
    final conv = await _repository.createConversation(propertyId: propertyId, participantId: participantId);
    await loadConversations();
    return conv;
  }

  Future<void> markRead(String conversationId) async {
    await _repository.markConversationRead(conversationId);
    await loadConversations();
  }
}
