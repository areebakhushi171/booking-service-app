import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/widgets/adaptive_scaffold.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/features/chat/presentation/screens/conversations_screen.dart';
import 'package:bookease/features/chat/providers/chat_provider.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/profile/presentation/screens/profile_screen.dart';
import 'package:bookease/features/provider/presentation/screens/my_services_screen.dart';
import 'package:bookease/features/provider/presentation/screens/provider_bookings_screen.dart';
import 'package:bookease/features/provider/presentation/screens/provider_dashboard_screen.dart';
import 'package:bookease/features/provider/providers/provider_services_provider.dart';

/// Provider panel: Dashboard, My Services, Requests, Messages, Profile.
class ProviderShellScreen extends StatefulWidget {
  const ProviderShellScreen({super.key});

  @override
  State<ProviderShellScreen> createState() => _ProviderShellScreenState();
}

class _ProviderShellScreenState extends State<ProviderShellScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      context.read<ProviderServicesProvider>().load(user.id);
      context.read<BookingProvider>().attachUser(userId: user.id, isProvider: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onNavigationIndexChanged: (i) => setState(() => _currentIndex = i),
      destinations: [
        const AdaptiveScaffoldDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
        ),
        const AdaptiveScaffoldDestination(
          label: 'Services',
          icon: Icons.design_services_outlined,
          selectedIcon: Icons.design_services_rounded,
        ),
        const AdaptiveScaffoldDestination(
          label: 'Requests',
          icon: Icons.inbox_outlined,
          selectedIcon: Icons.inbox_rounded,
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ProviderDashboardScreen(
            onOpenTab: (i) => setState(() => _currentIndex = i),
          ),
          const MyServicesScreen(),
          const ProviderBookingsScreen(),
          const ConversationsScreen(),
          const ProfileScreen(),
        ],
      ),
    );
  }
}
