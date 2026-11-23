import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/services/providers/service_provider.dart';
import 'package:bookease/features/provider/presentation/screens/service_form_screen.dart';
import 'package:bookease/features/provider/presentation/widgets/provider_service_tile.dart';
import 'package:bookease/features/provider/providers/provider_services_provider.dart';

/// Provider's listings: add, edit, hide/show and delete services.
class MyServicesScreen extends StatelessWidget {
  const MyServicesScreen({super.key});

  Future<void> _openForm(BuildContext context, [ServiceModel? existing]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ServiceFormScreen(existing: existing)),
    );
    if (saved == true && context.mounted) {
      // Customers must see the change right away.
      context.read<ServiceProvider>().loadServices();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null
              ? 'Service published. Customers can book it now.'
              : 'Service updated.'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, ServiceModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text(
            '"${s.name}" will be removed for customers. Existing bookings are kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<ProviderServicesProvider>().delete(s.id);
    if (context.mounted) context.read<ServiceProvider>().loadServices();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProviderServicesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: state.services.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add service'),
            ),
      body: Builder(builder: (context) {
        if (state.isLoading && state.services.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.services.isEmpty) {
          return EmptyStateView(
            icon: Icons.add_business_rounded,
            title: 'No services yet',
            message:
                'Upload your first service with a price, duration and photo. Customers will be able to book it instantly.',
            buttonText: 'Add your first service',
            onButtonPressed: () => _openForm(context),
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                  AppSizes.s20, AppSizes.s8, AppSizes.s20, 96.h),
              itemCount: state.services.length,
              itemBuilder: (context, i) {
                final s = state.services[i];
                return ProviderServiceTile(
                  service: s,
                  onEdit: () => _openForm(context, s),
                  onDelete: () => _confirmDelete(context, s),
                  onActiveChanged: (v) async {
                    await context
                        .read<ProviderServicesProvider>()
                        .setActive(s, v);
                    if (context.mounted) {
                      context.read<ServiceProvider>().loadServices();
                    }
                  },
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
