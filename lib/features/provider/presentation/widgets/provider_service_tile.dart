import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';

/// Provider listing card. The complete card slides left to reveal circular actions.
class ProviderServiceTile extends StatefulWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProviderServiceTile({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ProviderServiceTile> createState() => _ProviderServiceTileState();
}

class _ProviderServiceTileState extends State<ProviderServiceTile> {
  double _dragOffset = 0;
  bool get _actionsVisible => _dragOffset > 5;

  double get _revealWidth => 136.w;

  void _close() {
    if (mounted) setState(() => _dragOffset = 0);
  }

  Widget _circularAction({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46.r,
                height: 46.r,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withAlpha(150);
    final img = 84.r;
    final service = widget.service;
    final active = service.isActive;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.s12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              // Main Sliding Card Content
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragOffset = (_dragOffset - details.delta.dx)
                        .clamp(0.0, _revealWidth);
                  });
                },
                onHorizontalDragEnd: (_) {
                  setState(() {
                    _dragOffset = _dragOffset >= _revealWidth * 0.35
                        ? _revealWidth
                        : 0;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(-_dragOffset, 0, 0),
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withAlpha(20),
                    ),
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
                              child: service.imageUrl.trim().isEmpty
                                  ? Container(
                                      width: img,
                                      height: img,
                                      color: theme.colorScheme.onSurface.withAlpha(15),
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: muted,
                                        size: 22.sp,
                                      ),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: service.imageUrl,
                                      width: img,
                                      height: img,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        width: img,
                                        height: img,
                                        color: theme.colorScheme.onSurface.withAlpha(15),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        width: img,
                                        height: img,
                                        color: theme.colorScheme.onSurface.withAlpha(15),
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: muted,
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
                                    service.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp,
                                    ),
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
                                      Icon(Icons.schedule_rounded,
                                          size: 13.sp, color: muted),
                                      SizedBox(width: 3.w),
                                      Text(
                                        '${service.durationMinutes}m',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: muted,
                                        ),
                                      ),
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
                            color: active ? AppColors.success : muted,
                          ),
                          const Spacer(),
                          Text(
                            _actionsVisible ? 'Swipe right to close' : 'Swipe left for actions',
                            style: TextStyle(color: muted, fontSize: 10.sp),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Circular Action Buttons - Rendered ON TOP when swiped!
              if (_actionsVisible)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: _dragOffset,
                  child: ClipRect(
                    child: Container(
                      color: theme.scaffoldBackgroundColor,
                      alignment: Alignment.centerRight,
                      child: OverflowBox(
                        alignment: Alignment.centerRight,
                        minWidth: _revealWidth,
                        maxWidth: _revealWidth,
                        child: Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _circularAction(
                                icon: Icons.edit_rounded,
                                label: 'Edit',
                                color: theme.colorScheme.primary.withAlpha(30),
                                iconColor: theme.colorScheme.primary,
                                tooltip: 'Edit service',
                                onTap: () {
                                  _close();
                                  widget.onEdit();
                                },
                              ),
                              SizedBox(width: 8.w),
                              _circularAction(
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                                color: AppColors.error.withAlpha(30),
                                iconColor: AppColors.error,
                                tooltip: 'Delete service',
                                onTap: () {
                                  _close();
                                  widget.onDelete();
                                },
                              ),
                            ],
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
    );
  }
}