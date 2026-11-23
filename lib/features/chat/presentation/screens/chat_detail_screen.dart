import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/features/chat/data/models/chat_model.dart';
import 'package:bookease/features/chat/providers/chat_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final ConversationModel conversation;
  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await context.read<ChatProvider>().fetchMessages(widget.conversation.id);
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _sending) return;

    final currentUserId = context.read<AuthProvider>().user.id;
    final currentUserName = context.read<AuthProvider>().user.name;

    final tempMsg = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: currentUserId,
      senderName: currentUserName,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, tempMsg);
      _sending = true;
    });
    _msgController.clear();

    try {
      final realMsg = await context.read<ChatProvider>().sendMessage(widget.conversation.id, text);
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == tempMsg.id);
          if (idx != -1) {
            _messages[idx] = realMsg;
          } else {
            _messages.insert(0, realMsg);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == tempMsg.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = context.read<AuthProvider>().user.id;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: theme.colorScheme.primary.withAlpha(30),
              child: Text(
                widget.conversation.participantName.isNotEmpty
                    ? widget.conversation.participantName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.participantName,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.conversation.propertyName,
                    style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurface.withAlpha(160)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 48.sp, color: theme.colorScheme.primary.withAlpha(100)),
                            SizedBox(height: 12.h),
                            Text(
                              'No messages yet. Type a message below!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, idx) {
                          final msg = _messages[idx];
                          final isMe = msg.senderId == currentUserId;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Column(
                              crossAxisAlignment:
                                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? theme.colorScheme.primary
                                        : theme.cardColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16.r),
                                      topRight: Radius.circular(16.r),
                                      bottomLeft: Radius.circular(isMe ? 16.r : 2.r),
                                      bottomRight: Radius.circular(isMe ? 2.r : 16.r),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: isMe ? Colors.transparent : theme.dividerColor.withAlpha(30),
                                    ),
                                  ),
                                  child: Text(
                                    msg.content,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : theme.colorScheme.onSurface,
                                      fontSize: 14.sp,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                                  child: Text(
                                    _formatTime(msg.createdAt),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: theme.colorScheme.onSurface.withAlpha(120),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: theme.dividerColor.withAlpha(50),
                        ),
                      ),
                      child: TextField(
                        controller: _msgController,
                        style: TextStyle(fontSize: 14.sp),
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: _sending ? null : _send,
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? SizedBox(
                              width: 18.r,
                              height: 18.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
