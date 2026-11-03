import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../providers/service_provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/service_card.dart';
import '../widgets/shimmer_loading.dart';
import 'favorites_screen.dart';
import 'service_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final serviceProvider = context.watch<ServiceProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => serviceProvider.loadServices(),
          child: CustomScrollView(
            slivers: [
              // Top Greeting & Avatar
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${userProvider.user.name.split(' ').first} 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'What service do you need today?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Badge(
                              isLabelVisible:
                                  serviceProvider.hasUnreadFavorites,
                              label: Text(
                                  '${serviceProvider.favorites.length}'),
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
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                theme.colorScheme.primary.withAlpha(30),
                            child: Text(
                              userProvider.user.initials,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Offline Banner if running from cache
              if (serviceProvider.isOfflineMode)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Offline Mode: Viewing locally cached catalog.',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => serviceProvider.loadServices(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Search bar & Sort Filter button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) =>
                              serviceProvider.setSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: 'Search salon, AC, tutor, massage...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: serviceProvider
                                    .searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () =>
                                        serviceProvider.setSearchQuery(''),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(14),
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

              // Category Filter Horizontal List
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: AppConstants.categories.length + 1,
                      itemBuilder: (context, idx) {
                        if (idx == 0) {
                          final isSelected =
                              serviceProvider.selectedCategory == null;
                          return CategoryChip(
                            label: 'All',
                            icon: Icons.grid_view_rounded,
                            isSelected: isSelected,
                            onTap: () => serviceProvider.selectCategory(null),
                          );
                        }
                        final cat = AppConstants.categories[idx - 1];
                        final catId = cat['id'] as String;
                        final isSelected =
                            serviceProvider.selectedCategory == catId;

                        return CategoryChip(
                          label: cat['name'] as String,
                          icon: cat['icon'] as IconData,
                          isSelected: isSelected,
                          onTap: () =>
                              serviceProvider.selectCategory(catId),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Content State (Loading, Error, or Lists)
              if (serviceProvider.isLoading &&
                  serviceProvider.services.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerPlaceholder(width: 160, height: 24),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (_, __) =>
                                const ServiceCardSkeleton(),
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
              else ...[
                // If user has filtered or searched, show direct results grid
                if (serviceProvider.selectedCategory != null ||
                    serviceProvider.searchQuery.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text(
                        'Results (${serviceProvider.filteredServices.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 340,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final service =
                              serviceProvider.filteredServices[index];
                          return ServiceCard(
                            service: service,
                            heroTag: 'search_${service.id}',
                            onTap: () => _navigateToDetails(context, service, heroTag: 'search_${service.id}'),
                          );
                        },
                        childCount: serviceProvider.filteredServices.length,
                      ),
                    ),
                  ),
                ] else ...[
                  // 1. Popular Services Carousel
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Popular Services',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'See All',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: serviceProvider.popularServices.length,
                        itemBuilder: (context, idx) {
                          final service =
                              serviceProvider.popularServices[idx];
                          return ServiceCard(
                            service: service,
                            isHorizontal: true,
                            heroTag: 'popular_${service.id}',
                            onTap: () => _navigateToDetails(context, service, heroTag: 'popular_${service.id}'),
                          );
                        },
                      ),
                    ),
                  ),

                  // 2. Top Rated Services
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Top Rated',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${serviceProvider.topRatedServices.length} offerings',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withAlpha(140),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 340,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final service =
                              serviceProvider.topRatedServices[index];
                          return ServiceCard(
                            service: service,
                            heroTag: 'top_${service.id}',
                            onTap: () => _navigateToDetails(context, service, heroTag: 'top_${service.id}'),
                          );
                        },
                        childCount: serviceProvider.topRatedServices.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context, ServiceModel service, {String? heroTag}) {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                const SizedBox(height: 16),
                _buildSortTile(
                  ctx,
                  title: 'Top Rated (Highest First)',
                  icon: Icons.star_rounded,
                  selected: provider.currentSort == ServiceSort.ratingDesc,
                  onTap: () {
                    provider.setSort(ServiceSort.ratingDesc);
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortTile(
                  ctx,
                  title: 'Price: Low to High',
                  icon: Icons.arrow_upward_rounded,
                  selected: provider.currentSort == ServiceSort.priceAsc,
                  onTap: () {
                    provider.setSort(ServiceSort.priceAsc);
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortTile(
                  ctx,
                  title: 'Price: High to Low',
                  icon: Icons.arrow_downward_rounded,
                  selected: provider.currentSort == ServiceSort.priceDesc,
                  onTap: () {
                    provider.setSort(ServiceSort.priceDesc);
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortTile(
                  ctx,
                  title: 'Duration: Shortest First',
                  icon: Icons.schedule_rounded,
                  selected: provider.currentSort == ServiceSort.durationAsc,
                  onTap: () {
                    provider.setSort(ServiceSort.durationAsc);
                    Navigator.pop(ctx);
                  },
                ),
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
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded,
              color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
