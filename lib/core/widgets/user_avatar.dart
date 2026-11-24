import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Reusable avatar widget that handles loading, caching, broken image fallback to initials,
/// and edit badge overlay with a theme-colored blue camera badge.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final VoidCallback? onEditTap;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 24.0,
    this.onTap,
    this.showEditBadge = false,
    this.onEditTap,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'BE';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = radius * 2;
    final url = avatarUrl?.trim();
    final hasImage = url != null && url.isNotEmpty;

    Widget avatarContent = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(180),
          width: 1.5.w,
        ),
      ),
      child: ClipOval(
        child: Container(
          width: size,
          height: size,
          color: hasImage ? Colors.transparent : theme.colorScheme.primary,
          child: hasImage
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.transparent,
                    child: Center(
                      child: SizedBox(
                        width: radius * 0.8,
                        height: radius * 0.8,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _buildInitialsFallback(theme),
                )
              : _buildInitialsFallback(theme),
        ),
      ),
    );

    if (onTap != null) {
      avatarContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: avatarContent,
      );
    }

    if (!showEditBadge) return avatarContent;

    return Stack(
      alignment: Alignment.center,
      children: [
        avatarContent,
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onEditTap ?? onTap,
            child: CircleAvatar(
              radius: (radius * 0.32).r.clamp(12.0, 20.0),
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.camera_alt_rounded,
                size: (radius * 0.32).r.clamp(12.0, 18.0),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: (radius * 0.75).sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
