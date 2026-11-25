import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/app_text_field.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final success = await context.read<AuthProvider>().changePassword(
            _currentCtrl.text,
            _newCtrl.text,
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update password. Check current password.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.screenPadding,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Banner Card
                Container(
                  padding: EdgeInsets.all(AppSizes.s20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(40),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.shield_rounded, color: Colors.white),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Security',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Choose a strong password with at least 6 characters.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.s24),

                AppTextField(
                  label: 'Current Password',
                  hint: 'Enter your current password',
                  icon: Icons.lock_outline_rounded,
                  controller: _currentCtrl,
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Current password is required' : null,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: AppSizes.s16),

                AppTextField(
                  label: 'New Password',
                  hint: 'Min 6 characters',
                  icon: Icons.lock_reset_rounded,
                  controller: _newCtrl,
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: AppSizes.s16),

                AppTextField(
                  label: 'Confirm New Password',
                  hint: 'Re-enter your new password',
                  icon: Icons.check_circle_outline_rounded,
                  controller: _confirmCtrl,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (v != _newCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
                SizedBox(height: AppSizes.s24),

                CustomButton(
                  label: 'Update Password',
                  icon: Icons.security_rounded,
                  isLoading: _saving,
                  onPressed: _saving ? null : _updatePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
