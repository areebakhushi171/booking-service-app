import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AdaptiveScaffoldDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AdaptiveScaffoldDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark ? AppConstants.surfaceDarkColor : null;
    final navIndicatorColor =
        isDark ? Theme.of(context).colorScheme.primary.withAlpha(60) : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint for NavigationRail vs BottomNavigationBar
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
                    return NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
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

        // Mobile layout: BottomNavigationBar
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
              return NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
