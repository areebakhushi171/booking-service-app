import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/constants/app_sizes.dart';
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
      final providerServices = allServices.where((s) => s.providerId == widget.providerId).toList();
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
    final existing = chatProvider.conversations.where((c) => c.propertyId == sampleService.id).toList();
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
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(conversation: conv),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.providerName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.s20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36.r,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              widget.providerName.isNotEmpty ? widget.providerName[0].toUpperCase() : 'P',
                              style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.providerName,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Verified Service Provider',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                                ),
                                SizedBox(height: 10.h),
                                ElevatedButton.icon(
                                  onPressed: _services.isEmpty ? null : () => _openChat(context),
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                  label: const Text('Contact Provider'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Services Offered (${_services.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.h),
                  if (_services.isEmpty)
                    const Text('No active services listed by this provider.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _services.length,
                      itemBuilder: (context, idx) {
                        final service = _services[idx];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: ServiceCard(
                            service: service,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceDetailsScreen(service: service),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
