import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bookease/features/customer/favorites/providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import 'package:bookease/features/customer/services/providers/service_provider.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
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
    final serviceProvider = context.watch<ServiceProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final favorites = serviceProvider.services
        .where((s) => favoritesProvider.favorites.contains(s.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Services'),
      ),
      body: favorites.isEmpty
          ? const EmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'No Favorite Services Yet',
              message:
                  'Tap the heart icon on any service card to save it to your favorites for quick access.',
            )
          : GridView.builder(
              padding: EdgeInsets.all(20.r),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final service = favorites[index];
                return ServiceCard(
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
                );
              },
            ),
    );
  }
}
