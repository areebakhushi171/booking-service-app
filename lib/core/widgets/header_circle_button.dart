import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tonal circular icon button for screen headers, with optional count badge.
class HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String tooltip;
  final int badgeCount;
  final VoidCallback onPressed;

  const HeaderCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.onSurface.withAlpha(14),
        shape: const CircleBorder(),
        child: InkResponse(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44.r,
            height: 44.r,
            child: Center(
              child: Badge(
                isLabelVisible: badgeCount > 0,
                label: Text('$badgeCount'),
                child: Icon(icon,
                    size: 22.sp, color: iconColor ?? theme.colorScheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}