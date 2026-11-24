import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Circular, soft-tinted icon button used for edit / delete / reschedule /
/// accept / reject / complete / share etc. Optional [label] shows a small
/// caption under the circle.
class CircleActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final String? label;

  const CircleActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.size,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    final dim = size ?? 44.r;
    final base = color ?? theme.colorScheme.primary;
    final fg = enabled ? base : theme.colorScheme.onSurface.withAlpha(90);

    final button = Tooltip(
      message: tooltip,
      child: Material(
        color: fg.withAlpha(enabled ? 30 : 20),
        shape: const CircleBorder(),
        child: InkResponse(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          radius: dim * 0.75,
          child: SizedBox(
            width: dim,
            height: dim,
            child: Icon(icon, size: dim * 0.46, color: fg),
          ),
        ),
      ),
    );

    if (label == null) return button;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        SizedBox(height: 6.h),
        Text(
          label!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withAlpha(170),
          ),
        ),
      ],
    );
  }
}