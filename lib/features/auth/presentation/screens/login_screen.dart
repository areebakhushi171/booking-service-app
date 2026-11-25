import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_routes.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/utils/validators.dart';
import 'package:bookease/core/widgets/app_text_field.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/features/auth/data/models/user_model.dart';
import 'package:bookease/features/auth/presentation/screens/signup_screen.dart';
import 'package:bookease/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
      expectedRole: widget.role,
    );
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
    final isProvider = widget.role == UserRole.provider;

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
                      title: 'Welcome back',
                      subtitle: isProvider
                          ? 'Log in to manage your services and booking requests.'
                          : 'Log in to book services and track your appointments.',
                    ),
                    SizedBox(height: 28.h),
                    if (auth.errorMessage != null) ...[
                      AuthErrorBanner(message: auth.errorMessage!),
                      SizedBox(height: 16.h),
                    ],
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
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock_outline_rounded,
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password is required'
                          : null,
                    ),
                    SizedBox(height: 28.h),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Log In',
                        backgroundColor: color,
                        isLoading: auth.isLoading,
                        onPressed: _submit,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?",
                            style: theme.textTheme.bodyMedium),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => SignupScreen(role: widget.role)),
                          ),
                          child: Text('Sign up',
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
