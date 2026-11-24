import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/circle_action_button.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/core/widgets/user_avatar.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/services/providers/service_provider.dart';
import 'package:bookease/features/customer/services/presentation/screens/service_details_screen.dart';
import 'package:bookease/features/customer/services/presentation/widgets/service_card.dart';
import 'package:bookease/features/chat/providers/chat_provider.dart';
import 'package:bookease/features/chat/data/models/chat_model.dart';
import 'package:bookease/features/chat/presentation/screens/chat_detail_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  final String providerId;
  final String providerName;

  const ProviderProfileScreen({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviderServices();
  }

  Future<void> _loadProviderServices() async {
    try {
      final allServices = context.read<ServiceProvider>().services;
      final providerServices =
      allServices.where((s) => s.providerId == widget.providerId).toList();
      if (mounted) {
        setState(() {
          _services = providerServices;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openChat(BuildContext context) async {
    if (_services.isEmpty) return;
    final chatProvider = context.read<ChatProvider>();
    final sampleService = _services.first;
    final existing = chatProvider.conversations
        .where((c) => c.propertyId == sampleService.id)
        .toList();
    ConversationModel conv;
    if (existing.isNotEmpty) {
      conv = existing.first;
    } else {
      conv = await chatProvider.startConversation(
        propertyId: sampleService.id,
        participantId: widget.providerId,
      );
    }
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: conv)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withAlpha(150);

    return Scaffold(
      appBar: AppBar(title: Text(widget.providerName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSizes.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                FadeSlideIn(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border.all(
                            color: theme.colorScheme.onSurface.withAlpha(20)),
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 78.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, -40.h),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: UserAvatar(
                                    avatarUrl: null,
                                    name: widget.providerName,
                                    radius: 38.r,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Padding(
                                  padding:
                                  EdgeInsets.symmetric(horizontal: 16.w),
                                  child: Text(
                                    widget.providerName,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                const StatusPill(
                                  label: 'Verified Service Provider',
                                  color: AppColors.success,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                20.r, 0, 20.r, 20.r),
                            child: Transform.translate(
                              offset: Offset(0, -26.h),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '${_services.length}',
                                        style: TextStyle(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Text('Services',
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              color: muted)),
                                    ],
                                  ),
                                  CircleActionButton(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    tooltip: 'Contact provider',
                                    label: 'Contact',
                                    size: 54.r,
                                    onPressed: _services.isEmpty
                                        ? null
                                        : () => _openChat(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      width: 4.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Services Offered (${_services.length})',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                if (_services.isEmpty)
                  const SizedBox(
                    height: 320,
                    child: EmptyStateView(
                      icon: Icons.storefront_outlined,
                      title: 'No services yet',
                      message:
                      'No active services listed by this provider.',
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _services.length,
                    itemBuilder: (context, idx) {
                      final service = _services[idx];
                      return FadeSlideIn(
                        index: idx,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: ServiceCard(
                            service: service,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ServiceDetailsScreen(service: service),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}