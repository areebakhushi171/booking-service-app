import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(right: 10.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary
                  : (theme.brightness == Brightness.dark
                      ? theme.cardColor
                      : Colors.white),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isSelected ? primary : theme.dividerColor.withAlpha(40),
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primary.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16.sp,
                  color: isSelected
                      ? Colors.white
                      : (theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey.shade700),
                ),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey.shade800),
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
