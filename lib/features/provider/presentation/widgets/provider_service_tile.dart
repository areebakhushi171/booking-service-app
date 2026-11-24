import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/circle_action_button.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';

/// A provider's own listing: photo, details, status pill and circular
/// Visibility / Edit / Delete action buttons.
class ProviderServiceTile extends StatelessWidget {
  final ServiceModel service;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProviderServiceTile({
    super.key,
    required this.service,
    required this.onActiveChanged,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _placeholder(ThemeData theme, double s) => Container(
    width: s,
    height: s,
    color: theme.colorScheme.onSurface.withAlpha(15),
    child: Icon(Icons.image_not_supported_outlined,
        color: theme.colorScheme.onSurface.withAlpha(150), size: 22.sp),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withAlpha(150);
    final img = 84.r;
    final active = service.isActive;

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.s12),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha(20)),
      ),
      child: Column(
        children: [
          Opacity(
            opacity: active ? 1 : 0.65,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: service.imageUrl.isEmpty
                      ? _placeholder(theme, img)
                      : CachedNetworkImage(
                    imageUrl: service.imageUrl,
                    width: img,
                    height: img,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(theme, img),
                    errorWidget: (_, __, ___) => _placeholder(theme, img),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700, fontSize: 14.sp),
                      ),
                      SizedBox(height: 6.h),
                      StatusPill(
                        label: AppCategories.nameOf(service.category),
                        color: theme.colorScheme.secondary,
                        showDot: false,
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Text(
                            service.formattedPrice,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Icon(Icons.schedule_rounded, size: 13.sp, color: muted),
                          SizedBox(width: 3.w),
                          Text('${service.durationMinutes}m',
                              style: TextStyle(fontSize: 12.sp, color: muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 22.h),
          Row(
            children: [
              StatusPill(
                label: active ? 'Live' : 'Hidden',
                color: active ? AppColors.success : theme.colorScheme.onSurface.withAlpha(140),
              ),
              const Spacer(),
              CircleActionButton(
                icon: active
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                tooltip: active ? 'Hide from customers' : 'Show to customers',
                color: AppColors.accentTeal,
                size: 40.r,
                onPressed: () => onActiveChanged(!active),
              ),
              SizedBox(width: 10.w),
              CircleActionButton(
                icon: Icons.edit_rounded,
                tooltip: 'Edit service',
                size: 40.r,
                onPressed: onEdit,
              ),
              SizedBox(width: 10.w),
              CircleActionButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete service',
                color: AppColors.error,
                size: 40.r,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}