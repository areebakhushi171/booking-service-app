import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/category_chip.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/core/widgets/shimmer_loading.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/core/widgets/user_avatar.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/features/customer/favorites/presentation/screens/favorites_screen.dart';
import 'package:bookease/features/customer/favorites/providers/favorites_provider.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/services/presentation/screens/service_details_screen.dart';
import 'package:bookease/features/customer/services/presentation/widgets/service_card.dart';
import 'package:bookease/features/customer/services/providers/service_provider.dart';
import 'package:bookease/features/notifications/providers/notification_provider.dart';
import 'package:bookease/features/notifications/presentation/screens/notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const SliverGridDelegate _gridDelegate =
  SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 14,
    crossAxisSpacing: 14,
    childAspectRatio: 0.76,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<AuthProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final notificationProvider = context.watch<NotificationProvider>();

    final isFiltering = serviceProvider.selectedCategory != null ||
        serviceProvider.searchQuery.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => serviceProvider.loadServices(),
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.s20, vertical: AppSizes.s16),
                  child: Row(
                    children: [
                      UserAvatar(
                        avatarUrl: userProvider.user.avatarUrl,
                        name: userProvider.user.name,
                        radius: 22.r,
                      ),
                      SizedBox(width: AppSizes.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${userProvider.user.name.split(' ').first} 👋',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'What service do you need today?',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _HeaderCircleButton(
                        icon: Icons.notifications_outlined,
                        tooltip: 'Notifications',
                        badgeCount: notificationProvider.unreadCount,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _HeaderCircleButton(
                        icon: Icons.favorite_rounded,
                        iconColor: Colors.redAccent,
                        tooltip: 'Favorites',
                        badgeCount: favoritesProvider.hasUnreadFavorites ? 1 : 0,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FavoritesScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Promo banner
              if (!isFiltering)
                SliverToBoxAdapter(
                  child: FadeSlideIn(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.s20, vertical: AppSizes.s4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                        child: Container(
                          padding: EdgeInsets.all(AppSizes.s20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -30.r,
                                top: -40.r,
                                child: _Circle(size: 130.r, alpha: 28),
                              ),
                              Positioned(
                                right: 40.r,
                                bottom: -50.r,
                                child: _Circle(size: 100.r, alpha: 20),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Book trusted pros\nin a few taps',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 10.h),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12.w, vertical: 6.h),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(40),
                                            borderRadius:
                                            BorderRadius.circular(20.r),
                                          ),
                                          child: Text(
                                            '${serviceProvider.services.length} services available near you',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.event_available_rounded,
                                      size: 54.sp, color: Colors.white54),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Search + sort
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.s20, vertical: AppSizes.s12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => serviceProvider.setSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: 'Search salon, AC, tutor, massage...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: serviceProvider.searchQuery.isNotEmpty
                                ? IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () =>
                                  serviceProvider.setSearchQuery(''),
                            )
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Tooltip(
                        message: 'Sort',
                        child: Material(
                          color: theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          child: InkResponse(
                            customBorder: const CircleBorder(),
                            onTap: () => _showSortBottomSheet(context),
                            child: SizedBox(
                              width: 50.r,
                              height: 50.r,
                              child: Icon(Icons.tune_rounded,
                                  color: theme.colorScheme.onPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 6.h, bottom: AppSizes.s8),
                  child: SizedBox(
                    height: 48.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: AppSizes.s20),
                      itemCount: AppCategories.all.length + 1,
                      itemBuilder: (context, idx) {
                        if (idx == 0) {
                          return CategoryChip(
                            label: 'All',
                            icon: Icons.grid_view_rounded,
                            isSelected: serviceProvider.selectedCategory == null,
                            onTap: () => serviceProvider.selectCategory(null),
                          );
                        }
                        final cat = AppCategories.all[idx - 1];
                        final catId = cat['id'] as String;
                        return CategoryChip(
                          label: cat['name'] as String,
                          icon: cat['icon'] as IconData,
                          isSelected: serviceProvider.selectedCategory == catId,
                          onTap: () => serviceProvider.selectCategory(catId),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Content
              if (serviceProvider.isLoading && serviceProvider.services.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.s20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerPlaceholder(width: 160.w, height: 24.h),
                        SizedBox(height: AppSizes.s16),
                        SizedBox(
                          height: 250.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (_, __) => const ServiceCardSkeleton(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (serviceProvider.errorMessage != null &&
                  serviceProvider.services.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    icon: Icons.cloud_off_rounded,
                    title: 'Connection Issue',
                    message: serviceProvider.errorMessage!,
                    buttonText: 'Try Again',
                    onButtonPressed: () => serviceProvider.loadServices(),
                  ),
                )
              else if (serviceProvider.filteredServices.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: Icons.search_off_rounded,
                      title: 'No Services Found',
                      message:
                      'No matches for your current filter or search criteria. Try a different category or search keyword.',
                      buttonText: 'Clear Filters',
                      onButtonPressed: () {
                        serviceProvider.selectCategory(null);
                        serviceProvider.setSearchQuery('');
                      },
                    ),
                  )
                else if (isFiltering) ...[
                    _sectionTitle(context, 'Results',
                        trailing: '${serviceProvider.filteredServices.length} found'),
                    _grid(context, serviceProvider.filteredServices, 'search'),
                    SliverToBoxAdapter(child: SizedBox(height: 32.h)),
                  ] else ...[
                    if (serviceProvider.popularServices.isNotEmpty) ...[
                      _sectionTitle(context, 'Popular Services'),
                      _carousel(context, serviceProvider.popularServices, 'popular'),
                    ],
                    if (serviceProvider.providerServices.isNotEmpty) ...[
                      _sectionTitle(context, 'New from providers',
                          trailing:
                          '${serviceProvider.providerServices.length} listings'),
                      _carousel(context, serviceProvider.providerServices, 'provider'),
                    ],
                    _sectionTitle(context, 'All Services',
                        trailing: '${serviceProvider.services.length} total'),
                    _grid(context, serviceProvider.services, 'all'),
                    SliverToBoxAdapter(child: SizedBox(height: 32.h)),
                  ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, {String? trailing}) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            AppSizes.s20, AppSizes.s24, AppSizes.s20, AppSizes.s12),
        child: Row(
          children: [
            Container(
              width: 4.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (trailing != null)
              StatusPill(
                label: trailing,
                color: theme.colorScheme.primary,
                showDot: false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _carousel(
      BuildContext context, List<ServiceModel> services, String tagPrefix) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 190.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSizes.s20),
          itemCount: services.length,
          itemBuilder: (context, idx) {
            final service = services[idx];
            final tag = '${tagPrefix}_${service.id}';
            return ServiceCard(
              service: service,
              isHorizontal: true,
              heroTag: tag,
              onTap: () => _navigateToDetails(context, service, heroTag: tag),
            );
          },
        ),
      ),
    );
  }

  Widget _grid(
      BuildContext context, List<ServiceModel> services, String tagPrefix) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.s20),
      sliver: SliverGrid(
        gridDelegate: _gridDelegate,
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final service = services[index];
            final tag = '${tagPrefix}_${service.id}';
            return ServiceCard(
              service: service,
              heroTag: tag,
              onTap: () => _navigateToDetails(context, service, heroTag: tag),
            );
          },
          childCount: services.length,
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context, ServiceModel service,
      {String? heroTag}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailsScreen(service: service, heroTag: heroTag),
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    final provider = context.read<ServiceProvider>();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) {
        Widget tile(String title, IconData icon, ServiceSort sort) {
          return _buildSortTile(
            ctx,
            title: title,
            icon: icon,
            selected: provider.currentSort == sort,
            onTap: () {
              provider.setSort(sort);
              Navigator.pop(ctx);
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppSizes.s20, vertical: AppSizes.s12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.onSurface.withAlpha(50),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.s16),
                Text(
                  'Sort Services By',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSizes.s12),
                tile('Price: Low to High', Icons.arrow_upward_rounded,
                    ServiceSort.priceAsc),
                tile('Price: High to Low', Icons.arrow_downward_rounded,
                    ServiceSort.priceDesc),
                tile('Duration: Shortest First', Icons.schedule_rounded,
                    ServiceSort.durationAsc),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortTile(
      BuildContext context, {
        required String title,
        required IconData icon,
        required bool selected,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final c = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withAlpha(160);
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      leading: CircleAvatar(
        radius: 18.r,
        backgroundColor: c.withAlpha(28),
        child: Icon(icon, color: c, size: 18.sp),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String tooltip;
  final int badgeCount;
  final VoidCallback onPressed;

  const _HeaderCircleButton({
    required this.icon,
    required this.tooltip,
    required this.badgeCount,
    required this.onPressed,
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
                    size: 22.sp,
                    color: iconColor ?? theme.colorScheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final int alpha;
  const _Circle({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withAlpha(alpha),
    ),
  );
}