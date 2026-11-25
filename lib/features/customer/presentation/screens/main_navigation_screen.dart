import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/widgets/adaptive_scaffold.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/customer/home/presentation/screens/home_screen.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:bookease/features/chat/presentation/screens/conversations_screen.dart';
import 'package:bookease/features/profile/presentation/screens/profile_screen.dart';
import 'package:bookease/features/chat/providers/chat_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      context.read<BookingProvider>().attachUser(userId: user.id, isProvider: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    final screens = [
      const HomeScreen(),
      const MyBookingsScreen(),
      const ConversationsScreen(),
      const ProfileScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: AdaptiveScaffold(
      currentIndex: _currentIndex,
      onNavigationIndexChanged: (idx) {
        if (idx != _currentIndex) setState(() => _currentIndex = idx);
      },
      destinations: [
        const AdaptiveScaffoldDestination(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        const AdaptiveScaffoldDestination(
          label: 'Bookings',
          icon: Icons.calendar_today_outlined,
          selectedIcon: Icons.calendar_month_rounded,
        ),
        AdaptiveScaffoldDestination(
          label: 'Messages',
          icon: Icons.chat_bubble_outline_rounded,
          selectedIcon: Icons.chat_bubble_rounded,
          badgeCount: chatProvider.unreadCount,
        ),
        const AdaptiveScaffoldDestination(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ],
      body: KeyedSubtree(
        key: ValueKey('customer-tab-$_currentIndex'),
        child: screens[_currentIndex],
      ),
      ),
    );
  }
}
