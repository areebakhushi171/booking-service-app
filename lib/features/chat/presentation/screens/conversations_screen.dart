import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/core/widgets/shimmer_loading.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/chat/providers/chat_provider.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/core/widgets/user_avatar.dart';
import 'package:bookease/features/chat/presentation/screens/chat_detail_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ChatProvider>();
    final currentUser = context.watch<AuthProvider>().user;
    final all = provider.conversations;

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all.where((c) {
            return c.participantName.toLowerCase().contains(q) ||
                c.propertyName.toLowerCase().contains(q) ||
                (c.lastMessage ?? '').toLowerCase().contains(q);
          }).toList();

    Widget body;
    if (provider.isLoading && all.isEmpty) {
      body = ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: ShimmerPlaceholder(width: double.infinity, height: 92.h),
        ),
      );
    } else if (all.isEmpty) {
      body = EmptyStateView(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No Conversations Yet',
        message:
            'Messages with service providers or customers will appear here when you inquire about services.',
        buttonText: 'Refresh',
        onButtonPressed: () => provider.loadConversations(),
      );
    } else {
      body = Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search conversations',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _query = ''),
                      ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message: 'Try a different name or keyword.',
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.loadConversations(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final conv = filtered[idx];
                        return FadeSlideIn(
                          index: idx,
                          child: _ConversationTile(
                            name: conv.displayNameFor(
                                currentUserIsProvider: currentUser.isProvider),
                            avatarUrl: conv.avatarFor(
                                currentUserIsProvider: currentUser.isProvider),
                            serviceImageUrl: conv.propertyImageUrl,
                            property: conv.propertyName,
                            lastMessage: conv.lastMessage,
                            unread: conv.unreadCount,
                            updatedAt: conv.updatedAt,
                            onTap: () async {
                              try {
                                await provider.markRead(conv.id);
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Unable to mark messages as read: $error',
                                      ),
                                    ),
                                  );
                                }
                              }
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChatDetailScreen(conversation: conv),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages & Chats'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: body,
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String? serviceImageUrl;
  final String property;
  final String? lastMessage;
  final int unread;
  final DateTime? updatedAt;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.avatarUrl,
    required this.serviceImageUrl,
    required this.property,
    required this.lastMessage,
    required this.unread,
    required this.updatedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final hasUnread = unread > 0;
    final muted = theme.colorScheme.onSurface.withAlpha(150);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: theme.colorScheme.onSurface.withAlpha(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.5.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withAlpha(40),
                      width: 2,
                    ),
                  ),
                  child: UserAvatar(
                    avatarUrl: (avatarUrl?.trim().isNotEmpty ?? false)
                        ? avatarUrl
                        : serviceImageUrl,
                    name: name,
                    radius: 25.r,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              property,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                          if (updatedAt != null)
                            Text(
                              _formatTime(updatedAt!),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: muted,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage ?? 'Tap to view conversation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: muted,
                              ),
                            ),
                          ),
                          if (hasUnread) ...[
                            SizedBox(width: 8.w),
                            Container(
                              constraints: BoxConstraints(minWidth: 22.r),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 7.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '$unread',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final localDt = dt.toLocal();
  final now = DateTime.now();
  final sameDay = now.year == localDt.year &&
      now.month == localDt.month &&
      now.day == localDt.day;
  if (sameDay) {
    final h = localDt.hour > 12
        ? localDt.hour - 12
        : (localDt.hour == 0 ? 12 : localDt.hour);
    final m = localDt.minute.toString().padLeft(2, '0');
    final ampm = localDt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  final sameYesterday = yesterday.year == localDt.year &&
      yesterday.month == localDt.month &&
      yesterday.day == localDt.day;
  if (sameYesterday) {
    return 'Yesterday';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${localDt.day} ${months[localDt.month - 1]}';
}
