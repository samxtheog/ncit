import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Logo scale + fade
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // App name slide + fade
  late final Animation<double> _nameSlide;
  late final Animation<double> _nameFade;

  // Tagline fade
  late final Animation<double> _tagFade;

  // Bottom bar fade
  late final Animation<double> _barFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo: spring scale 0→1 over 700ms starting at 0ms
    _logoScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );
    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
    );

    // Name: slide up + fade, starts at 300ms
    _nameSlide = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.18, 0.55, curve: Curves.easeOut),
    );
    _nameFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.18, 0.5, curve: Curves.easeIn),
    );

    // Tagline: fade in after name
    _tagFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.38, 0.65, curve: Curves.easeIn),
    );

    // Bottom bar
    _barFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.55, 0.8, curve: Curves.easeIn),
    );

    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
    final isLoggedIn     = prefs.getBool(AppConstants.keyIsLoggedIn)     ?? false;
    final setupDone      = prefs.getBool(AppConstants.keySetupDone)      ?? false;

    if (!mounted) return;

    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
    } else if (!isLoggedIn) {
      context.go(AppRoutes.login);
    } else if (!setupDone) {
      context.go(AppRoutes.setup);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Center content ─────────────────────────────────────────
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo icon
                        AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, __) => Opacity(
                            opacity: _logoFade.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 32,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.connecting_airports_rounded,
                                    color: AppColors.primary,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // App name
                        AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, __) => Opacity(
                            opacity: _nameFade.value,
                            child: Transform.translate(
                              offset: Offset(0, 24 * (1 - _nameSlide.value)),
                              child: Text(
                                AppConstants.appName,
                                style: AppTextStyles.displayLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Tagline
                        AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, __) => Opacity(
                            opacity: _tagFade.value,
                            child: Text(
                              AppConstants.appTagline,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white.withOpacity(0.75),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom loading bar ─────────────────────────────────────
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Opacity(
                  opacity: _barFade.value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 52),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 100,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: null,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              color: Colors.white.withOpacity(0.6),
                              minHeight: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Loading your journey...',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
