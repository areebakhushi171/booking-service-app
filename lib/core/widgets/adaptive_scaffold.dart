import 'package:flutter/material.dart';
import 'package:bookease/core/constants/app_colors.dart';

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

class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationIndexChanged;
  final List<AdaptiveScaffoldDestination> destinations;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationIndexChanged,
    required this.destinations,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  Widget _buildIcon(AdaptiveScaffoldDestination d, bool selected) {
    final iconWidget = Icon(selected ? d.selectedIcon : d.icon);
    if (d.badgeCount > 0) {
      return Badge(
        label: Text('${d.badgeCount}'),
        child: iconWidget,
      );
    }
    return iconWidget;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark ? AppColors.surfaceDark : null;
    final navIndicatorColor =
        isDark ? Theme.of(context).colorScheme.primary.withAlpha(60) : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMediumOrLarge = constraints.maxWidth >= 720;

        if (isMediumOrLarge) {
          return Scaffold(
            appBar: appBar,
            floatingActionButton: floatingActionButton,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: onNavigationIndexChanged,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: navBgColor,
                  indicatorColor: navIndicatorColor,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  destinations: destinations.map((d) {
                    final selected = destinations.indexOf(d) == currentIndex;
                    return NavigationRailDestination(
                      icon: _buildIcon(d, selected),
                      selectedIcon: _buildIcon(d, true),
                      label: Text(d.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          floatingActionButton: floatingActionButton,
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onNavigationIndexChanged,
            elevation: 3,
            backgroundColor: navBgColor,
            indicatorColor: navIndicatorColor,
            destinations: destinations.map((d) {
              final selected = destinations.indexOf(d) == currentIndex;
              return NavigationDestination(
                icon: _buildIcon(d, selected),
                selectedIcon: _buildIcon(d, true),
                label: d.label,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
