import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/shimmer_loading.dart';
import 'package:bookease/features/customer/favorites/providers/favorites_provider.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;
  final bool isHorizontal;
  final String? heroTag;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.isHorizontal = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFav = favoritesProvider.isFavorite(service.id);

    final card = _buildCardContent(context, theme, isFav, favoritesProvider);

    if (isHorizontal) {
      return Container(
        width: 250.w,
        margin: EdgeInsets.only(right: AppSizes.s16),
        child: card,
      );
    }
    return card;
  }

  Widget _buildCardContent(
    BuildContext context,
    ThemeData theme,
    bool isFav,
    FavoritesProvider favoritesProvider,
  ) {
    final resolvedHeroTag = heroTag ?? 'service_img_${service.id}';
    final muted = theme.colorScheme.onSurface.withAlpha(150);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Hero animation & favorite button
            SizedBox(
              height: 110.h,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  service.imageUrl.isEmpty
                      ? Container(
                          color: theme.colorScheme.onSurface.withAlpha(25),
                          child: Icon(Icons.broken_image,
                              size: 36.sp, color: muted),
                        )
                      : Hero(
                          tag: resolvedHeroTag,
                          child: CachedNetworkImage(
                            imageUrl: service.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => ShimmerPlaceholder(
                              width: double.infinity,
                              height: 110.h,
                              borderRadius: 0,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: theme.colorScheme.onSurface.withAlpha(25),
                              child: Icon(Icons.broken_image,
                                  size: 36.sp, color: muted),
                            ),
                          ),
                        ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: InkWell(
                      onTap: () => favoritesProvider.toggleFavorite(service.id),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(120),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? Colors.redAccent : Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppCategories.nameOf(service.category).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.secondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                          ),
                        ),
                        if (service.providerName != null)
                          Text(
                            'by ${service.providerName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.sp, color: muted),
                          ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.formattedPrice,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 11.sp, color: muted),
                            SizedBox(width: 2.w),
                            Text(
                              service.formattedDuration,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                                fontWeight: FontWeight.w500,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
