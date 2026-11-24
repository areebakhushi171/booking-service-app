import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Rounded status badge: tinted background + dot + coloured text.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6.r,
              height: 6.r,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 6.w),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft card with an optional icon + title header.
class SectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;
  final Color? tint;
  final EdgeInsetsGeometry? padding;

  const SectionCard({
    super.key,
    this.title,
    this.icon,
    required this.child,
    this.tint,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tint ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: tint == null ? theme.cardColor : tint!.withAlpha(18),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: tint == null
              ? theme.colorScheme.onSurface.withAlpha(20)
              : tint!.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: accent.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 17.sp, color: accent),
                  ),
                  SizedBox(width: 10.w),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
          ],
          child,
        ],
      ),
    );
  }
}

/// Icon chip + label + value row. Optional [trailing] (e.g. copy button).
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selectable;
  final Widget? trailing;
  final Color? color;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.selectable = false,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    final valueStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14.sp,
      color: theme.colorScheme.onSurface,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36.r,
          height: 36.r,
          decoration: BoxDecoration(
            color: accent.withAlpha(28),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17.sp, color: accent),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              SizedBox(height: 2.h),
              selectable
                  ? SelectableText(value, style: valueStyle)
                  : Text(value, style: valueStyle),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Fade + slide-up entrance. Pass the list [index] for a light stagger.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;

  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final ms = 260 + (index.clamp(0, 8) * 60);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: child),
      ),
      child: child,
    );
  }
}

/// Copies [text] to the clipboard and shows a snackbar.
Future<void> copyToClipboard(BuildContext context, String text,
    {String message = 'Copied'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}