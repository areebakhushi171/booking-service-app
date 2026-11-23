import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';

/// A provider's own listing: photo, key facts, Active switch and Edit / Delete.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withAlpha(150);

    return Opacity(
      opacity: service.isActive ? 1 : 0.65,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSizes.s12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: theme.colorScheme.onSurface.withAlpha(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 96.w,
              child: service.imageUrl.isEmpty
                  ? Container(
                      color: theme.colorScheme.onSurface.withAlpha(15),
                      child: Icon(Icons.image_not_supported_outlined,
                          color: muted, size: 24.sp),
                    )
                  : CachedNetworkImage(
                      imageUrl: service.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: theme.colorScheme.onSurface.withAlpha(15)),
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.onSurface.withAlpha(15),
                        child: Icon(Icons.image_not_supported_outlined,
                            color: muted, size: 24.sp),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${AppCategories.nameOf(service.category)}  |  ${service.durationMinutes} min',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      service.formattedPrice,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSizes.s4),
                    Row(
                      children: [
                        Icon(
                          service.isActive
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: 14.sp,
                          color: service.isActive ? AppColors.success : muted,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            service.isActive ? 'Visible' : 'Hidden',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: muted),
                          ),
                        ),
                        Switch(
                          value: service.isActive,
                          onChanged: onActiveChanged,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit'),
                        ),
                        TextButton.icon(
                          onPressed: onDelete,
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.error),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16),
                          label: const Text('Delete'),
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
      ),
    );
  }
}
