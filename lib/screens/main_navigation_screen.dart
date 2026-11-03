import 'package:flutter/material.dart';
import '../widgets/adaptive_scaffold.dart';
import 'home_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const MyBookingsScreen(),
      const ProfileScreen(),
    ];

    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onNavigationIndexChanged: (idx) => setState(() => _currentIndex = idx),
      destinations: const [
        AdaptiveScaffoldDestination(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        AdaptiveScaffoldDestination(
          label: 'My Bookings',
          icon: Icons.calendar_today_outlined,
          selectedIcon: Icons.calendar_month_rounded,
        ),
        AdaptiveScaffoldDestination(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ],
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}
