import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/utils/validators.dart';
import 'package:bookease/core/widgets/app_text_field.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _businessNameCtrl;

  late String? _businessCategory;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user.name);
    _emailCtrl = TextEditingController(text: user.email);
    _phoneCtrl = TextEditingController(text: user.phone);
    _businessNameCtrl = TextEditingController(text: user.businessName ?? '');
    _businessCategory = user.businessCategory;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _businessNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Header
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50.r,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          user.initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16.r,
                          backgroundColor: theme.colorScheme.secondary,
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.s24),

                Text(
                  'Personal Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSizes.s16),

                AppTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline_rounded,
                  controller: _nameCtrl,
                  validator: Validators.validateName,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: AppSizes.s16),

                AppTextField(
                  label: 'Email Address',
                  hint: 'name@example.com',
                  icon: Icons.email_outlined,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: AppSizes.s16),

                AppTextField(
                  label: 'Phone Number',
                  hint: '03001234567',
                  icon: Icons.phone_outlined,
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  textInputAction: TextInputAction.done,
                ),
                SizedBox(height: AppSizes.s24),

                if (user.isProvider) ...[
                  Text(
                    'Business Info (Provider)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSizes.s16),

                  AppTextField(
                    label: 'Business Name',
                    hint: 'e.g. Royal Beauty Salon',
                    icon: Icons.storefront_outlined,
                    controller: _businessNameCtrl,
                  ),
                  SizedBox(height: AppSizes.s16),

                  Text('Business Category',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  SizedBox(height: AppSizes.s8),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: AppCategories.all.map((c) {
                      final id = c['id'] as String;
                      return ChoiceChip(
                        avatar: Icon(c['icon'] as IconData, size: 16.sp),
                        label: Text(c['name'] as String),
                        selected: _businessCategory == id,
                        onSelected: (_) => setState(() => _businessCategory = id),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: AppSizes.s24),
                ],

                CustomButton(
                  label: 'Save Changes',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
                SizedBox(height: AppSizes.s20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
