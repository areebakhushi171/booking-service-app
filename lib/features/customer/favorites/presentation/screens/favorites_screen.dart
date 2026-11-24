import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/customer/favorites/providers/favorites_provider.dart';
import 'package:bookease/features/customer/services/providers/service_provider.dart';
import 'package:bookease/features/customer/services/presentation/widgets/service_card.dart';
import 'package:bookease/features/customer/services/presentation/screens/service_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().markFavoritesAsViewed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceProvider = context.watch<ServiceProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final favorites = serviceProvider.services
        .where((s) => favoritesProvider.favorites.contains(s.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Services')),
      body: favorites.isEmpty
          ? const EmptyStateView(
        icon: Icons.favorite_border_rounded,
        title: 'No Favorite Services Yet',
        message:
        'Tap the heart icon on any service card to save it to your favorites for quick access.',
      )
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
              child: Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(28),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.favorite_rounded,
                        color: Colors.redAccent, size: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Your saved services',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  StatusPill(
                    label: '${favorites.length} saved',
                    color: Colors.redAccent,
                    showDot: false,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(20.r),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final service = favorites[index];
                  return FadeSlideIn(
                    index: index,
                    child: ServiceCard(
                      service: service,
                      heroTag: 'fav_${service.id}',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ServiceDetailsScreen(
                              service: service,
                              heroTag: 'fav_${service.id}',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: favorites.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}