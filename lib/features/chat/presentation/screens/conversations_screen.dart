import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/features/chat/providers/chat_provider.dart';
import 'package:bookease/features/chat/presentation/screens/chat_detail_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages & Chats'),
        elevation: 0,
      ),
      body: provider.isLoading && provider.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.conversations.isEmpty
              ? EmptyStateView(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No Conversations Yet',
                  message: 'Messages with service providers or customers will appear here when you inquire about services.',
                  buttonText: 'Refresh',
                  onButtonPressed: () => provider.loadConversations(),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadConversations(),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    itemCount: provider.conversations.length,
                    itemBuilder: (context, idx) {
                      final conv = provider.conversations[idx];
                      final hasUnread = conv.unreadCount > 0;

                      return Card(
                        margin: EdgeInsets.only(bottom: 12.h),
                        elevation: hasUnread ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(
                            color: hasUnread
                                ? theme.colorScheme.primary.withAlpha(80)
                                : theme.dividerColor.withAlpha(40),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.r),
                          onTap: () async {
                            await provider.markRead(conv.id);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(conversation: conv),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.all(14.r),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26.r,
                                  backgroundColor: theme.colorScheme.primary.withAlpha(30),
                                  child: Text(
                                    conv.participantName.isNotEmpty
                                        ? conv.participantName[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              conv.participantName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15.sp,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (conv.updatedAt != null)
                                            Text(
                                              _formatTime(conv.updatedAt!),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurface.withAlpha(120),
                                                fontSize: 11.sp,
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondary.withAlpha(20),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          conv.propertyName,
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: theme.colorScheme.secondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Text(
                                        conv.lastMessage ?? 'Tap to view conversation',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: hasUnread
                                              ? theme.colorScheme.onSurface
                                              : theme.colorScheme.onSurface.withAlpha(150),
                                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasUnread) ...[
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${conv.unreadCount}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  SizedBox(width: 4.w),
                                  Icon(Icons.chevron_right_rounded,
                                      color: theme.colorScheme.onSurface.withAlpha(100)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.day == dt.day && now.month == dt.month && now.year == dt.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day}';
  }
}
