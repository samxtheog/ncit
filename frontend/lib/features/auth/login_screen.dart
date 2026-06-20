import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/google_auth_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _googleLogin() async {
    try {
      final tokenData = await GoogleAuthService.signIn();
      if (tokenData == null) return;
      if (!mounted) return;
      final success = await ref.read(authProvider.notifier).googleLogin(tokenData: tokenData);
      if (!mounted) return;
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        final setupDone = prefs.getBool(AppConstants.keySetupDone) ?? false;
        if (!mounted) return;
        context.go(setupDone ? AppRoutes.home : AppRoutes.setup);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      final setupDone = prefs.getBool(AppConstants.keySetupDone) ?? false;
      if (!mounted) return;
      context.go(setupDone ? AppRoutes.home : AppRoutes.setup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final errorMessage = authState.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Real photo header ──────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 260,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1513530534585-c7b1394c6d51?w=800&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.lightAccent),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(color: AppColors.lightAccent),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.background],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Scrollable content ─────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 196),

                    // ── Heading ──────────────────────────────────────────
                    Text('Welcome Back', style: AppTextStyles.displaySmall)
                        .animate()
                        .fade(duration: 500.ms, delay: 100.ms)
                        .slideX(
                            begin: -0.2,
                            end: 0,
                            duration: 500.ms,
                            delay: 100.ms,
                            curve: Curves.easeOut),

                    const SizedBox(height: 6),

                    Text(
                      'Sign in to continue your learning journey',
                      style: AppTextStyles.bodyMedium,
                    ).animate().fade(duration: 500.ms, delay: 200.ms),

                    const SizedBox(height: 32),

                    // ── Fields ───────────────────────────────────────────
                    AppTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon:
                          const Icon(Icons.email_outlined, size: 20),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Email is required';
                        if (!val.contains('@'))
                          return 'Enter a valid email';
                        return null;
                      },
                    )
                        .animate()
                        .fade(duration: 500.ms, delay: 280.ms)
                        .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 280.ms),

                    const SizedBox(height: 20),

                    AppTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon:
                          const Icon(Icons.lock_outline, size: 20),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Password is required';
                        if (val.length < 6)
                          return 'Password must be at least 6 characters';
                        return null;
                      },
                    )
                        .animate()
                        .fade(duration: 500.ms, delay: 370.ms)
                        .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 370.ms),

                    // ── API error banner ──────────────────────────────────
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFFCDD2), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Color(0xFFE53935), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFFE53935)),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(duration: 300.ms).slideY(begin: -0.1, end: 0),
                    ],

                    const SizedBox(height: 28),

                    // ── Sign In button ────────────────────────────────────
                    AppButton(
                      label: 'Sign In',
                      onTap: _login,
                      isLoading: isLoading,
                      variant: AppButtonVariant.gradient,
                    )
                        .animate()
                        .fade(duration: 500.ms, delay: 460.ms)
                        .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 460.ms),

                    const SizedBox(height: 16),

                    // ── Divider ───────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFDDE8F5))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.textMuted)),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFDDE8F5))),
                      ],
                    ).animate().fade(duration: 400.ms, delay: 500.ms),

                    const SizedBox(height: 16),

                    // ── Google button ────────────────────────────────────
                    GoogleSignInButton(onPressed: _googleLogin)
                        .animate()
                        .fade(duration: 500.ms, delay: 540.ms)
                        .slideY(begin: 0.15, end: 0),

                    const SizedBox(height: 32),

                    // ── Register link ────────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go(AppRoutes.register),
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: AppTextStyles.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Create Account',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(duration: 500.ms, delay: 550.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
