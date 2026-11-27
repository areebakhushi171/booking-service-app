import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/core/widgets/shimmer_loading.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
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
      final user = context.read<AuthProvider>().user;
      context.read<ProviderServicesProvider>().load(user.id);
      context.read<ServiceProvider>().loadServices();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null
              ? 'Service published successfully.'
              : 'Service updated successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, ServiceModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        icon: CircleAvatar(
          radius: 28.r,
          backgroundColor: AppColors.error.withAlpha(30),
          child: Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 28.sp),
        ),
        title: const Text('Delete service?', textAlign: TextAlign.center),
        content: Text(
          '"${s.name}" will be removed for customers and deleted from backend. Existing bookings are kept.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      final user = context.read<AuthProvider>().user;
      await context.read<ProviderServicesProvider>().delete(s.id);
      if (context.mounted) {
        await context.read<ProviderServicesProvider>().load(user.id);
        context.read<ServiceProvider>().loadServices();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete service: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          return ListView.builder(
            padding: EdgeInsets.all(AppSizes.s20),
            itemCount: 4,
            itemBuilder: (_, __) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: ShimmerPlaceholder(width: double.infinity, height: 150.h),
            ),
          );
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
              itemCount: state.services.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSizes.s12),
                    child: Wrap(
                      spacing: 8.w,
                      children: [
                        StatusPill(
                          label: '${state.services.length} services',
                          color: theme.colorScheme.primary,
                          showDot: false,
                        ),
                        StatusPill(
                          label: '${state.activeCount} live',
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  );
                }
                final s = state.services[i - 1];
                return FadeSlideIn(
                  index: i,
                  child: ProviderServiceTile(
                    service: s,
                    onEdit: () => _openForm(context, s),
                    onDelete: () => _confirmDelete(context, s),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}