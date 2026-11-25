import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_routes.dart';
import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/utils/validators.dart';
import 'package:bookease/core/widgets/app_text_field.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/features/auth/data/datasources/auth_datasource.dart';
import 'package:bookease/features/auth/data/models/user_model.dart';
import 'package:bookease/features/auth/presentation/screens/login_screen.dart';
import 'package:bookease/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  final UserRole role;
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _category;

  bool get _isProvider => widget.role == UserRole.provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final ok = await auth.signup(SignupRequest(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      role: widget.role,
      businessName: _isProvider ? _businessController.text : null,
      businessCategory: _isProvider ? _category : null,
    ));
    if (ok && mounted) Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home(isProvider: auth.user.isProvider),
        (route) => false,
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final color = roleColor(widget.role);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSizes.authPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppSizes.maxFormWidth),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthHeader(
                      role: widget.role,
                      title: 'Create your account',
                      subtitle: _isProvider
                          ? 'Set up your provider profile and start getting bookings.'
                          : 'Sign up to discover and book trusted services.',
                    ),
                    SizedBox(height: 28.h),
                    if (auth.errorMessage != null) ...[
                      AuthErrorBanner(message: auth.errorMessage!),
                      SizedBox(height: 16.h),
                    ],
                    AppTextField(
                      label: 'Full Name',
                      hint: 'e.g. Ayesha Khan',
                      icon: Icons.person_outline_rounded,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validateName,
                    ),
                    SizedBox(height: 20.h),
                    AppTextField(
                      label: 'Email Address',
                      hint: 'e.g. name@example.com',
                      icon: Icons.mail_outline_rounded,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validateEmail,
                    ),
                    SizedBox(height: 20.h),
                    AppTextField(
                      label: 'Phone Number (PK)',
                      hint: 'e.g. +92 300 1234567',
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validatePhone,
                    ),
                    if (_isProvider) ...[
                      SizedBox(height: 20.h),
                      AppTextField(
                        label: 'Business / Service Name',
                        hint: 'e.g. Glow Salon & Spa',
                        icon: Icons.storefront_outlined,
                        controller: _businessController,
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.validateRequired(v,
                            field: 'Business name'),
                      ),
                      SizedBox(height: 20.h),
                      Text('Main Category',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      SizedBox(height: 8.h),
                      DropdownButtonFormField<String>(
                        value: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Select your category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: AppCategories.all
                            .map((c) => DropdownMenuItem<String>(
                                  value: c['id'] as String,
                                  child: Text(c['name'] as String),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v),
                        validator: (v) =>
                            v == null ? 'Please select a category' : null,
                      ),
                    ],
                    SizedBox(height: 20.h),
                    AppTextField(
                      label: 'Password',
                      hint: 'At least 8 characters',
                      icon: Icons.lock_outline_rounded,
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validatePassword,
                    ),
                    SizedBox(height: 20.h),
                    AppTextField(
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      icon: Icons.lock_outline_rounded,
                      controller: _confirmController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) => Validators.validateConfirmPassword(
                          _passwordController.text)(v),
                    ),
                    SizedBox(height: 28.h),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Create Account',
                        backgroundColor: color,
                        isLoading: auth.isLoading,
                        onPressed: _submit,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account?',
                            style: theme.textTheme.bodyMedium),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => LoginScreen(role: widget.role)),
                          ),
                          child: Text('Log in',
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
