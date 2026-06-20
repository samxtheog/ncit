import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/api_constants.dart';
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

    final prefs          = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
    final token          = prefs.getString(AppConstants.keyAuthToken);

    if (!mounted) return;

    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
      return;
    }

    // No token stored → definitely not logged in
    if (token == null || token.isEmpty) {
      context.go(AppRoutes.login);
      return;
    }

    // ── Verify token against MongoDB (source of truth) ──────────────────
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.me),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;

        // Refresh local prefs with latest DB values
        await prefs.setBool(AppConstants.keyIsLoggedIn,  true);
        await prefs.setBool(AppConstants.keySetupDone,   user['setupDone'] as bool? ?? false);
        await prefs.setString(AppConstants.keyUserName,  (user['name']  as String? ?? '').split(' ').first);
        await prefs.setString(AppConstants.keyUserEmail, user['email']  as String? ?? '');
        await prefs.setString(AppConstants.keyUserId,    user['id']     as String? ?? '');
        if ((user['faculty'] as String?)?.isNotEmpty == true)
          await prefs.setString(AppConstants.keyFaculty, user['faculty'] as String);
        if ((user['grade'] as String?)?.isNotEmpty == true)
          await prefs.setString(AppConstants.keyGrade,   user['grade']   as String);
        if ((user['interests'] as List?)?.isNotEmpty == true)
          await prefs.setStringList(AppConstants.keyInterests,
              List<String>.from(user['interests'] as List));
        if ((user['skills'] as List?)?.isNotEmpty == true)
          await prefs.setStringList(AppConstants.keySkills,
              List<String>.from(user['skills'] as List));
        if ((user['goal'] as String?)?.isNotEmpty == true)
          await prefs.setString(AppConstants.keyGoal, user['goal'] as String);
        await prefs.setInt(AppConstants.keyXP,        (user['xp']        as num?)?.toInt() ?? 0);
        await prefs.setInt(AppConstants.keyQuizCount, (user['quizCount'] as num?)?.toInt() ?? 0);

        final setupDone = user['setupDone'] as bool? ?? false;
        if (!mounted) return;
        context.go(setupDone ? AppRoutes.home : AppRoutes.setup);
      } else {
        // 401 / 404 — account deleted or token invalid → clear and go to login
        await _clearSession(prefs);
        if (!mounted) return;
        context.go(AppRoutes.login);
      }
    } catch (_) {
      // Network error — fall back to cached session so the app works offline
      final setupDone = prefs.getBool(AppConstants.keySetupDone) ?? false;
      if (!mounted) return;
      context.go(setupDone ? AppRoutes.home : AppRoutes.setup);
    }
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(AppConstants.keyIsLoggedIn);
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keySetupDone);
    await prefs.remove(AppConstants.keyFaculty);
    await prefs.remove(AppConstants.keyGrade);
    await prefs.remove(AppConstants.keyInterests);
    await prefs.remove(AppConstants.keySkills);
    await prefs.remove(AppConstants.keyGoal);
    await prefs.remove(AppConstants.keyXP);
    await prefs.remove(AppConstants.keyQuizCount);
    await prefs.remove(AppConstants.keyLastQuizDate);
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
