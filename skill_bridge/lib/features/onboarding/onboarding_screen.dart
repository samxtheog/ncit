import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../shared/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Find Your Future',
      description:
          'Discover careers that match your interests and strengths. Build the path that leads to your dream job.',
      imageUrl:
          'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600&q=80',
      accentColor: AppColors.primary,
      decorIcons: [
        Icons.business_center_rounded,
        Icons.star_rounded,
        Icons.bar_chart_rounded,
        Icons.map_rounded,
      ],
      decorColors: [
        Color(0xFF2196F3),
        Color(0xFFFFB300),
        Color(0xFF4CAF50),
        Color(0xFFFF5722),
      ],
    ),
    _OnboardingPageData(
      title: 'Learn Smarter\nwith AI',
      description:
          'Upload PDFs, chat with your notes, and understand complex concepts faster with your AI learning assistant.',
      imageUrl:
          'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=600&q=80',
      accentColor: AppColors.secondary,
      decorIcons: [
        Icons.description_rounded,
        Icons.lightbulb_rounded,
        Icons.psychology_rounded,
        Icons.auto_awesome_rounded,
      ],
      decorColors: [
        Color(0xFF5483B3),
        Color(0xFFFFB300),
        Color(0xFF7C4DFF),
        Color(0xFF00BCD4),
      ],
    ),
    _OnboardingPageData(
      title: 'Earn While\nLearning',
      description:
          'Complete quizzes, earn XP points, and unlock powerful AI learning tools as you grow your skills.',
      imageUrl:
          'https://images.unsplash.com/photo-1567427017947-545c5f8d16ad?w=600&q=80',
      accentColor: Color(0xFF1A6B4A),
      decorIcons: [
        Icons.star_rounded,
        Icons.military_tech_rounded,
        Icons.diamond_rounded,
        Icons.rocket_launch_rounded,
      ],
      decorColors: [
        Color(0xFFFFB300),
        Color(0xFF1A6B4A),
        Color(0xFF00BCD4),
        Color(0xFFE53935),
      ],
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
    if (mounted) context.go(AppRoutes.login);
  }

  void _nextPage() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step counter pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${_pages.length}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!_isLastPage)
                    GestureDetector(
                      onTap: _completeOnboarding,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: Text(
                          'Skip',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
        left: AppConstants.horizontalPadding,
        right: AppConstants.horizontalPadding,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmoothPageIndicator(
            controller: _pageController,
            count: _pages.length,
            effect: ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 4,
              activeDotColor: AppColors.primary,
              dotColor: AppColors.lightAccent,
              spacing: 6,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              if (_currentPage > 0) ...[
                AppButton(
                  label: 'Back',
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                  variant: AppButtonVariant.outline,
                  width: 100,
                  height: 52,
                  borderRadius: 14,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AppButton(
                  label: _isLastPage ? 'Get Started' : 'Next',
                  onTap: _nextPage,
                  variant: _isLastPage
                      ? AppButtonVariant.gradient
                      : AppButtonVariant.primary,
                  height: 52,
                  borderRadius: 14,
                  icon: _isLastPage
                      ? const Icon(Icons.rocket_launch_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ],
          ),
          if (!_isLastPage) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.go(AppRoutes.login),
              child: Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: AppTextStyles.bodySmall,
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Page widget ──────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 80),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildIllustration(),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.horizontalPadding),
                child: _buildContent(),
              ),
            ),
            const SizedBox(height: 180),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    // Offsets for 4 corner badges around the central circle
    const offsets = [
      Offset(-115, -70),
      Offset(105, -80),
      Offset(-120, 55),
      Offset(108, 55),
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer tinted ring
        Container(
          width: 290,
          height: 290,
          decoration: BoxDecoration(
            color: data.accentColor.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
        ),

        // Real photo clipped to circle
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: data.accentColor.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              data.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: data.accentColor.withOpacity(0.12),
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 60,
                  color: data.accentColor,
                ),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: data.accentColor.withOpacity(0.08),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: data.accentColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              },
            ),
          ),
        )
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
            )
            .fade(duration: 400.ms),

        // 4 floating icon badges
        ...List.generate(data.decorIcons.length, (i) {
          return Positioned(
            left: 145 + offsets[i].dx,
            top: 145 + offsets[i].dy,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow,
              ),
              child: Icon(
                data.decorIcons[i],
                color: data.decorColors[i],
                size: 20,
              ),
            )
                .animate(
                  onPlay: (ctrl) => ctrl.repeat(reverse: true),
                  delay: Duration(milliseconds: 300 + i * 200),
                )
                .moveY(
                  begin: 0,
                  end: -6,
                  duration: 1400.ms,
                  curve: Curves.easeInOut,
                )
                .animate(delay: Duration(milliseconds: 200 + i * 120))
                .fade(duration: 400.ms)
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                ),
          );
        }),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          data.title,
          style: AppTextStyles.displayMedium.copyWith(height: 1.2),
        )
            .animate()
            .fade(duration: 500.ms, delay: 200.ms)
            .slideX(
                begin: -0.2,
                end: 0,
                duration: 500.ms,
                delay: 200.ms,
                curve: Curves.easeOut),
        const SizedBox(height: 16),
        Text(
          data.description,
          style: AppTextStyles.bodyLarge.copyWith(height: 1.7),
        )
            .animate()
            .fade(duration: 500.ms, delay: 350.ms)
            .slideX(
                begin: -0.2,
                end: 0,
                duration: 500.ms,
                delay: 350.ms,
                curve: Curves.easeOut),
      ],
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _OnboardingPageData {
  final String title;
  final String description;
  final String imageUrl;
  final Color accentColor;
  final List<IconData> decorIcons;
  final List<Color> decorColors;

  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.accentColor,
    required this.decorIcons,
    required this.decorColors,
  });
}
