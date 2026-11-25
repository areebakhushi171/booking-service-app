import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdaptiveScaffoldDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int badgeCount;

  const AdaptiveScaffoldDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount = 0,
  });
}

/// Phones: floating pill bottom navigation (selected item expands with its
/// label). Wide screens: a styled navigation rail.
class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationIndexChanged;
  final List<AdaptiveScaffoldDestination> destinations;
  final Widget body;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationIndexChanged,
    required this.destinations,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.of(context).size.width >= 800;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: Container(
                margin: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: theme.colorScheme.onSurface.withAlpha(20)),
                ),
                child: NavigationRail(
                  backgroundColor: Colors.transparent,
                  selectedIndex: currentIndex,
                  onDestinationSelected: onNavigationIndexChanged,
                  labelType: NavigationRailLabelType.all,
                  indicatorColor: theme.colorScheme.primary.withAlpha(30),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: _badged(d, d.icon),
                        selectedIcon: _badged(d, d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
          child: Container(
            height: 66.h,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(
                color: theme.colorScheme.onSurface.withAlpha(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(
                      theme.brightness == Brightness.dark ? 90 : 28),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < destinations.length; i++)
                  _NavItem(
                    destination: destinations[i],
                    selected: i == currentIndex,
                    onTap: () {
                      if (i != currentIndex) {
                        HapticFeedback.selectionClick();
                        onNavigationIndexChanged(i);
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _badged(AdaptiveScaffoldDestination d, IconData icon) {
    return Badge(
      isLabelVisible: d.badgeCount > 0,
      label: Text(d.badgeCount > 99 ? '99+' : '${d.badgeCount}'),
      child: Icon(icon),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AdaptiveScaffoldDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final inactive = theme.colorScheme.onSurface.withAlpha(140);

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 48.h,
          constraints: BoxConstraints(minWidth: 48.r),
          padding: EdgeInsets.symmetric(horizontal: selected ? 14.w : 10.w),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
              colors: [primary, theme.colorScheme.secondary],
            )
                : null,
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: selected
                ? [
              BoxShadow(
                color: primary.withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: destination.badgeCount > 0,
                label: Text(destination.badgeCount > 99 ? '99+' : '${destination.badgeCount}'),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    key: ValueKey(selected),
                    size: 24.sp,
                    color: selected ? theme.colorScheme.onPrimary : inactive,
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                  padding: EdgeInsets.only(left: 6.w),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}