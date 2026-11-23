import 'package:bookease/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:bookease/features/chat/data/models/chat_model.dart';

class ChatRepository {
  final ChatRemoteDataSource _source;
  ChatRepository(this._source);

  Future<List<ConversationModel>> fetchConversations() => _source.fetchConversations();
  Future<ConversationModel> createConversation({required String propertyId, String? participantId}) =>
      _source.createConversation(propertyId: propertyId, participantId: participantId);
  Future<List<MessageModel>> fetchMessages(String conversationId) => _source.fetchMessages(conversationId);
  Future<MessageModel> sendMessage(String conversationId, String content) => _source.sendMessage(conversationId, content);
  Future<void> markConversationRead(String conversationId) => _source.markConversationRead(conversationId);
}
