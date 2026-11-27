import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/widgets/circle_action_button.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/core/widgets/shimmer_loading.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/customer/favorites/providers/favorites_provider.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_stepper_screen.dart';
import 'package:bookease/features/chat/providers/chat_provider.dart';
import 'package:bookease/features/chat/data/models/chat_model.dart';
import 'package:bookease/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:bookease/features/customer/services/presentation/screens/provider_profile_screen.dart';
import 'package:bookease/features/provider/data/service_image_presets.dart';

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
    final existing =
    chatProvider.conversations.where((c) => c.propertyId == service.id).toList();
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
        MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: conv)),
      );
    }
  }

  Widget _overlayCircle({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withAlpha(110),
        shape: const CircleBorder(),
        child: InkResponse(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 42.r,
            height: 42.r,
            child: Icon(icon, color: color, size: 22.sp),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = widget.service;
    final resolvedHeroTag = widget.heroTag ?? 'service_img_${service.id}';
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFav = favoritesProvider.isFavorite(service.id);
    final muted = theme.colorScheme.onSurface.withAlpha(150);

    final List<String> rawImages = [
      if (service.imageUrl.isNotEmpty) service.imageUrl,
      ...service.galleryImages
          .where((url) => url.isNotEmpty && url != service.imageUrl),
    ];
    final allImages = rawImages.isEmpty
        ? [ServiceImagePresets.forCategory(service.category)]
        : rawImages;
    if (_selectedImageIdx >= allImages.length) _selectedImageIdx = 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320.h,
            pinned: true,
            leadingWidth: 62.w,
            leading: Padding(
              padding: EdgeInsets.only(left: 14.w, top: 6.h, bottom: 6.h),
              child: _overlayCircle(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 14.w),
                child: _overlayCircle(
                  icon: isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? Colors.redAccent : Colors.white,
                  tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                  onPressed: () => favoritesProvider.toggleFavorite(service.id),
                ),
              ),
            ],
            // Rounded content-sheet overlap
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(24.h),
              child: Container(
                height: 24.h,
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(top: 8.h),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                ),
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(40),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  allImages[_selectedImageIdx].isEmpty
                      ? Container(
                          color: Colors.grey.withAlpha(60),
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
                              color: Colors.grey.withAlpha(60),
                              child: Icon(Icons.broken_image, size: 60.sp),
                            ),
                          ),
                        ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100.h,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(150),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (allImages.length > 1)
                    Positioned(
                      bottom: 36.h,
                      right: 16.w,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            allImages.length,
                            (idx) => GestureDetector(
                              onTap: () => setState(() => _selectedImageIdx = idx),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.symmetric(horizontal: 3.w),
                                width: 38.r,
                                height: 38.r,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: _selectedImageIdx == idx
                                        ? theme.colorScheme.primary
                                        : Colors.white54,
                                    width: _selectedImageIdx == idx ? 2.5 : 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: allImages[idx].isEmpty
                                      ? Container(color: Colors.grey.withAlpha(60))
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
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.r, 4.r, 20.r, 20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusPill(
                        label: AppCategories.nameOf(service.category).toUpperCase(),
                        color: theme.colorScheme.secondary,
                        showDot: false,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withAlpha(14),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 15.sp, color: muted),
                            SizedBox(width: 4.w),
                            Text(
                              service.formattedDuration,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    service.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (service.providerName != null) ...[
                    SizedBox(height: 14.h),
                    Material(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18.r),
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
                        child: Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(
                                color: theme.colorScheme.onSurface.withAlpha(20)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22.r,
                                backgroundColor:
                                theme.colorScheme.secondary.withAlpha(30),
                                child: Text(
                                  service.providerName!.isNotEmpty
                                      ? service.providerName![0].toUpperCase()
                                      : 'P',
                                  style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.providerName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.sp),
                                    ),
                                    SizedBox(height: 3.h),
                                    const StatusPill(
                                      label: 'Verified provider',
                                      color: AppColors.success,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: muted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  Text(
                    'About Service',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                      "What's Included",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12.h),
                    ...service.features.map(
                          (feature) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                color: AppColors.success.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_rounded,
                                  size: 14.sp, color: AppColors.success),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                feature,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
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
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 12,
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
                  Text('Total Price',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted)),
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
              CircleActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'Chat with Provider',
                size: 50.r,
                onPressed: () => _openChat(context, service),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomButton(
                  label: 'Book Now',
                  icon: Icons.calendar_month_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookingStepperScreen(service: service),
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