import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
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
    _msgController.addListener(() => setState(() {}));
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
      final messages =
      await context.read<ChatProvider>().fetchMessages(widget.conversation.id);
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
      final realMsg =
      await context.read<ChatProvider>().sendMessage(widget.conversation.id, text);
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return 'Today';
    if (_sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withAlpha(150);
    final currentUserId = context.read<AuthProvider>().user.id;
    final canSend = _msgController.text.trim().isNotEmpty && !_sending;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary.withAlpha(120), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 17.r,
                backgroundColor: primary.withAlpha(30),
                child: Text(
                  widget.conversation.propertyName.isNotEmpty
                      ? widget.conversation.propertyName[0].toUpperCase()
                      : 'S',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.propertyName,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Chat with ${widget.conversation.participantName}',
                    style: TextStyle(fontSize: 11.sp, color: muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84.r,
                      height: 84.r,
                      decoration: BoxDecoration(
                        color: primary.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chat_bubble_outline_rounded,
                          size: 38.sp, color: primary),
                    ),
                    SizedBox(height: 16.h),
                    Text('Say hello 👋',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 6.h),
                    Text(
                      'No messages yet. Type a message below!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                final isMe = msg.senderId == currentUserId;
                final isTemp = msg.id.startsWith('temp_');
                final showDate = idx == _messages.length - 1 ||
                    !_sameDay(msg.createdAt, _messages[idx + 1].createdAt);

                return Column(
                  children: [
                    if (showDate)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface
                                .withAlpha(16),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            _dateLabel(msg.createdAt),
                            style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: muted),
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context)
                                    .size
                                    .width *
                                    0.75,
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: isMe ? primary : theme.cardColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(18.r),
                                  topRight: Radius.circular(18.r),
                                  bottomLeft: Radius.circular(
                                      isMe ? 18.r : 4.r),
                                  bottomRight: Radius.circular(
                                      isMe ? 4.r : 18.r),
                                ),
                                border: isMe
                                    ? null
                                    : Border.all(
                                    color: theme
                                        .colorScheme.onSurface
                                        .withAlpha(20)),
                              ),
                              child: Text(
                                msg.content,
                                style: TextStyle(
                                  color: isMe
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                  fontSize: 14.sp,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(msg.createdAt),
                                  style: TextStyle(
                                      fontSize: 10.sp, color: muted),
                                ),
                                if (isMe) ...[
                                  SizedBox(width: 4.w),
                                  Icon(
                                    isTemp
                                        ? Icons.schedule_rounded
                                        : Icons.done_all_rounded,
                                    size: 13.sp,
                                    color: isTemp ? muted : primary,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Floating pill input bar
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(26.r),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withAlpha(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _msgController,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Tooltip(
                    message: 'Send message',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        color: canSend
                            ? primary
                            : theme.colorScheme.onSurface.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: InkResponse(
                        onTap: canSend ? _send : null,
                        customBorder: const CircleBorder(),
                        child: Center(
                          child: _sending
                              ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                              : Icon(
                            Icons.send_rounded,
                            color: canSend
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface.withAlpha(110),
                            size: 20.sp,
                          ),
                        ),
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