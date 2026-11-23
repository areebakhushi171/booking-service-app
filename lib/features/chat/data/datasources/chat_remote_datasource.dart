import 'package:bookease/core/network/api_client.dart';
import 'package:bookease/core/network/api_endpoints.dart';
import 'package:bookease/features/chat/data/models/chat_model.dart';

class ChatRemoteDataSource {
  final ApiClient _client;
  ChatRemoteDataSource(this._client);

  List<ConversationModel> _parseConversations(dynamic data) {
    final list = data is List
        ? data
        : (data is Map ? (data['conversations'] ?? data['data'] ?? []) as List : []);
    return list.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  List<MessageModel> _parseMessages(dynamic data) {
    final list = data is List
        ? data
        : (data is Map ? (data['messages'] ?? data['data'] ?? []) as List : []);
    return list.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  ConversationModel _parseSingleConversation(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return ConversationModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      if (data['conversation'] is Map<String, dynamic>) {
        return ConversationModel.fromJson(data['conversation'] as Map<String, dynamic>);
      }
      return ConversationModel.fromJson(data);
    }
    return const ConversationModel(
      id: '',
      propertyId: '',
      propertyName: '',
      participantId: '',
      participantName: '',
    );
  }

  MessageModel _parseSingleMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return MessageModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      if (data['message'] is Map<String, dynamic>) {
        return MessageModel.fromJson(data['message'] as Map<String, dynamic>);
      }
      return MessageModel.fromJson(data);
    }
    return MessageModel(
      id: '',
      conversationId: '',
      senderId: '',
      senderName: '',
      content: '',
      createdAt: DateTime.now(),
    );
  }

  Future<List<ConversationModel>> fetchConversations() async {
    final res = await _client.get(ApiEndpoints.conversations);
    return _parseConversations(res.data);
  }

  Future<ConversationModel> createConversation({required String propertyId, String? participantId}) async {
    final res = await _client.post(ApiEndpoints.conversations, body: {
      'serviceId': propertyId,
      'propertyId': propertyId,
      if (participantId != null) 'participantId': participantId,
    });
    return _parseSingleConversation(res.data);
  }

  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    final res = await _client.get(ApiEndpoints.conversationMessages(conversationId));
    return _parseMessages(res.data);
  }

  Future<MessageModel> sendMessage(String conversationId, String content) async {
    final res = await _client.post(ApiEndpoints.conversationMessages(conversationId), body: {
      'content': content,
    });
    return _parseSingleMessage(res.data);
  }

  Future<void> markConversationRead(String conversationId) async {
    await _client.patch(ApiEndpoints.readConversation(conversationId));
  }
}
