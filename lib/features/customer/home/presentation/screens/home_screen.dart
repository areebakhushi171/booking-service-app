import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/category_chip.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/core/widgets/shimmer_loading.dart';
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
      SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 340,
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    childAspectRatio: 0.78,
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
              // Greeting, notifications, favorites and avatar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.s20, vertical: AppSizes.s16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22.r,
                        backgroundColor:
                            theme.colorScheme.primary.withAlpha(30),
                        child: Text(
                          userProvider.user.initials,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
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
                                color:
                                    theme.colorScheme.onSurface.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Badge(
                          isLabelVisible: notificationProvider.unreadCount > 0,
                          label: Text('${notificationProvider.unreadCount}'),
                          child: const Icon(Icons.notifications_outlined),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Badge(
                          isLabelVisible: favoritesProvider.hasUnreadFavorites,
                          label: Text('${favoritesProvider.favorites.length}'),
                          child: const Icon(Icons.favorite_rounded,
                              color: Colors.redAccent),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FavoritesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Promo banner (hidden while searching / filtering)
              if (!isFiltering)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.s20, vertical: AppSizes.s4),
                    child: Container(
                      padding: EdgeInsets.all(AppSizes.s20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Book trusted pros\nin a few taps',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  '${serviceProvider.services.length} services available near you',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.event_available_rounded,
                              size: 54.sp, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                ),

              // Search bar & sort button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.s20, vertical: AppSizes.s12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) =>
                              serviceProvider.setSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: 'Search salon, AC, tutor, massage...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: serviceProvider.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () =>
                                        serviceProvider.setSearchQuery(''),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune_rounded,
                              color: Colors.white),
                          onPressed: () => _showSortBottomSheet(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category filter chips
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
                            isSelected:
                                serviceProvider.selectedCategory == null,
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

              // Content: loading / error / empty / lists
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
                _sectionTitle(
                  context,
                  'Results (${serviceProvider.filteredServices.length})',
                ),
                _grid(context, serviceProvider.filteredServices, 'search'),
                SliverToBoxAdapter(child: SizedBox(height: 32.h)),
              ] else ...[
                // Popular
                if (serviceProvider.popularServices.isNotEmpty) ...[
                  _sectionTitle(context, 'Popular Services'),
                  _carousel(context, serviceProvider.popularServices, 'popular'),
                ],

                // Uploaded by provider accounts
                if (serviceProvider.providerServices.isNotEmpty) ...[
                  _sectionTitle(context, 'New from providers',
                      trailing:
                          '${serviceProvider.providerServices.length} listings'),
                  _carousel(
                      context, serviceProvider.providerServices, 'provider'),
                ],

                // All Services Grid
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(140),
                ),
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
        height: 250.h,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                horizontal: AppSizes.s20, vertical: AppSizes.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort Services By',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppSizes.s16),
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
    return ListTile(
      leading: Icon(icon,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withAlpha(160)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color:
              selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
