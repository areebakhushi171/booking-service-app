import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_colors.dart';
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

    final isFiltering = serviceProvider.hasActiveFilters ||
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

              // Search + Filter Button
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
                        message: 'Filter & Sort',
                        child: Material(
                          color: serviceProvider.hasActiveFilters
                              ? AppColors.primary
                              : theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _showFilterBottomSheet(context),
                            child: SizedBox(
                              width: 50.r,
                              height: 50.r,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    color: theme.colorScheme.onPrimary,
                                    size: 22.sp,
                                  ),
                                  if (serviceProvider.hasActiveFilters)
                                    Positioned(
                                      top: 10.r,
                                      right: 10.r,
                                      child: Container(
                                        width: 10.r,
                                        height: 10.r,
                                        decoration: const BoxDecoration(
                                          color: Colors.amberAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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
                      'No matches for your current filter or search criteria. Try a different category or price/duration range.',
                      buttonText: 'Clear Filters',
                      onButtonPressed: () {
                        serviceProvider.resetFilters();
                      },
                    ),
                  )
                else if (isFiltering) ...[
                    _sectionTitle(context, 'Filtered Services',
                        trailing: '${serviceProvider.filteredServices.length} found'),
                    _grid(context, serviceProvider.filteredServices, 'filter'),
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) => const _FilterBottomSheet(),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet();

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late ServiceSort _sort;
  late String? _category;
  late double? _minPrice;
  late double? _maxPrice;
  late int? _maxDuration;

  @override
  void initState() {
    super.initState();
    final p = context.read<ServiceProvider>();
    _sort = p.currentSort;
    _category = p.selectedCategory;
    _minPrice = p.minPrice;
    _maxPrice = p.maxPrice;
    _maxDuration = p.maxDurationMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.read<ServiceProvider>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSizes.s20,
          AppSizes.s12,
          AppSizes.s20,
          MediaQuery.of(context).viewInsets.bottom + AppSizes.s16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(50),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter & Arrange Services',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _sort = ServiceSort.priceAsc;
                        _category = null;
                        _minPrice = null;
                        _maxPrice = null;
                        _maxDuration = null;
                      });
                      p.resetFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.s16),

              // Sort Section
              Text(
                'Sort By',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _sortChip('Price: Low to High', ServiceSort.priceAsc),
                  _sortChip('Price: High to Low', ServiceSort.priceDesc),
                  _sortChip('Duration: Shortest', ServiceSort.durationAsc),
                  _sortChip('Name: A to Z', ServiceSort.nameAsc),
                ],
              ),
              SizedBox(height: AppSizes.s20),

              // Category Section
              Text(
                'Category',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  FilterChip(
                    label: const Text('All Categories'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  ...AppCategories.all.map((c) {
                    final id = c['id'] as String;
                    final name = c['name'] as String;
                    return FilterChip(
                      label: Text(name),
                      selected: _category == id,
                      onSelected: (selected) {
                        setState(() {
                          _category = selected ? id : null;
                        });
                      },
                    );
                  }),
                ],
              ),
              SizedBox(height: AppSizes.s20),

              // Price Filter Section
              Text(
                'Price Range (Rs)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _priceChip('Any Price', null, null),
                  _priceChip('Under Rs 1,500', null, 1500),
                  _priceChip('Rs 1,500 - Rs 3,500', 1500, 3500),
                  _priceChip('Above Rs 3,500', 3500, null),
                ],
              ),
              SizedBox(height: AppSizes.s20),

              // Duration Section
              Text(
                'Max Duration',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _durationChip('Any Duration', null),
                  _durationChip('Under 30 mins', 30),
                  _durationChip('Under 60 mins', 60),
                  _durationChip('Under 120 mins', 120),
                ],
              ),
              SizedBox(height: AppSizes.s24),

              // Apply Button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: () {
                    p.applyFilterSheet(
                      category: _category,
                      sort: _sort,
                      minPrice: _minPrice,
                      maxPrice: _maxPrice,
                      maxDuration: _maxDuration,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortChip(String label, ServiceSort sortVal) {
    final selected = _sort == sortVal;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) setState(() => _sort = sortVal);
      },
    );
  }

  Widget _priceChip(String label, double? minP, double? maxP) {
    final selected = _minPrice == minP && _maxPrice == maxP;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _minPrice = minP;
            _maxPrice = maxP;
          });
        }
      },
    );
  }

  Widget _durationChip(String label, int? maxD) {
    final selected = _maxDuration == maxD;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _maxDuration = maxD;
          });
        }
      },
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