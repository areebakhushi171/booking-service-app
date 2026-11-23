import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/features/customer/favorites/providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/core/widgets/shimmer_loading.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_stepper_screen.dart';
import 'package:bookease/features/chat/providers/chat_provider.dart';
import 'package:bookease/features/chat/data/models/chat_model.dart';
import 'package:bookease/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:bookease/features/customer/services/presentation/screens/provider_profile_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceModel service;
  final String? heroTag;

  const ServiceDetailsScreen({
    super.key,
    required this.service,
    this.heroTag,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  int _selectedImageIdx = 0;

  Future<void> _openChat(BuildContext context, ServiceModel service) async {
    final chatProvider = context.read<ChatProvider>();
    final existing = chatProvider.conversations.where((c) => c.propertyId == service.id).toList();
    ConversationModel conv;
    if (existing.isNotEmpty) {
      conv = existing.first;
    } else {
      try {
        conv = await chatProvider.startConversation(
          propertyId: service.id,
          participantId: service.providerId,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open chat: $e')),
          );
        }
        return;
      }
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
    final service = widget.service;
    final resolvedHeroTag = widget.heroTag ?? 'service_img_${service.id}';
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFav = favoritesProvider.isFavorite(service.id);

    final allImages = [
      service.imageUrl,
      ...service.galleryImages,
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image & Favorite button
          SliverAppBar(
            expandedHeight: 320.h,
            pinned: true,
            leading: CircleAvatar(
              backgroundColor: Colors.black.withAlpha(120),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withAlpha(120),
                  child: IconButton(
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () =>
                        favoritesProvider.toggleFavorite(service.id),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  allImages[_selectedImageIdx].isEmpty
                      ? Container(
                          color: Colors.grey.shade300,
                          child: Icon(Icons.broken_image, size: 60.sp),
                        )
                      : Hero(
                          tag: resolvedHeroTag,
                          child: CachedNetworkImage(
                            imageUrl: allImages[_selectedImageIdx],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => ShimmerPlaceholder(
                              width: double.infinity,
                              height: 320.h,
                              borderRadius: 0,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade300,
                              child: Icon(Icons.broken_image, size: 60.sp),
                            ),
                          ),
                        ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80.h,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(160),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (allImages.length > 1)
                    Positioned(
                      bottom: 12.h,
                      right: 16.w,
                      child: Row(
                        children: List.generate(
                          allImages.length,
                          (idx) => GestureDetector(
                            onTap: () =>
                                setState(() => _selectedImageIdx = idx),
                            child: Container(
                              margin: EdgeInsets.only(left: 6.w),
                              width: 44.w,
                              height: 44.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: _selectedImageIdx == idx
                                      ? theme.colorScheme.primary
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6.r),
                                child: allImages[idx].isEmpty
                                    ? Container(color: Colors.grey.shade300)
                                    : CachedNetworkImage(
                                        imageUrl: allImages[idx],
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          AppCategories.nameOf(service.category).toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 16.sp, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Text(
                            service.formattedDuration,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  Text(
                    service.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (service.providerName != null) ...[
                    SizedBox(height: 6.h),
                    InkWell(
                      onTap: () {
                        if (service.providerId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderProfileScreen(
                                providerId: service.providerId!,
                                providerName: service.providerName!,
                              ),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.storefront_rounded,
                              size: 16.sp, color: theme.colorScheme.secondary),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'Provided by ${service.providerName}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.chevron_right_rounded,
                              size: 16.sp, color: theme.colorScheme.secondary),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  const Divider(),
                  SizedBox(height: 16.h),

                  Text(
                    'About Service',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    service.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  if (service.features.isNotEmpty) ...[
                    Text(
                      'What\'s Included',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ...service.features.map(
                      (feature) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(3.r),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 14.sp,
                                color: Colors.green.shade800,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                feature,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomSheet: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, -3),
            )
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                  Text(
                    service.formattedPrice,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 14.w),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withAlpha(25),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.all(12.r),
                ),
                icon: Icon(Icons.chat_bubble_outline_rounded, color: theme.colorScheme.primary, size: 22.sp),
                onPressed: () => _openChat(context, service),
                tooltip: 'Chat with Provider',
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomButton(
                  label: 'Book Now',
                  icon: Icons.calendar_month_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingStepperScreen(service: service),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
