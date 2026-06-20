import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/career_service.dart';
import '../../../shared/widgets/career_card.dart';
import '../../career/roadmap_screen.dart';

class CareerTab extends StatefulWidget {
  const CareerTab({super.key});

  @override
  State<CareerTab> createState() => _CareerTabState();
}

class _CareerTabState extends State<CareerTab> {
  final _service = CareerService();
  List<CareerSuggestion> _all = [];
  List<CareerSuggestion> _filtered = [];
  String _query = '';
  bool _loading = true;
  bool _fromCache = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.getSuggestions(forceRefresh: forceRefresh);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _all = result.careers!;
        _fromCache = result.fromCache;
        _applyFilter();
      } else {
        _error = result.errorMessage;
      }
    });
  }

  void _applyFilter() {
    final q = _query.toLowerCase();
    _filtered = q.isEmpty
        ? List.of(_all)
        : _all
            .where((c) =>
                c.title.toLowerCase().contains(q) ||
                c.description.toLowerCase().contains(q) ||
                c.category.toLowerCase().contains(q))
            .toList();
  }

  void _onSearch(String q) {
    setState(() {
      _query = q;
      _applyFilter();
    });
  }

  void _openRoadmap(BuildContext context, CareerSuggestion career) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoadmapScreen(
          careerTitle: career.title,
          careerColor: _categoryColor(career.category),
          careerIcon: _categoryIcon(career.category),
          matchPercent: career.match,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.only(
              left: AppConstants.horizontalPadding,
              right: AppConstants.horizontalPadding,
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.explore_rounded,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Text('Career Explorer', style: AppTextStyles.headlineLarge),
                    const Spacer(),
                    if (!_loading)
                      IconButton(
                        tooltip: 'Refresh suggestions',
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.primary, size: 22),
                        onPressed: () => _load(forceRefresh: true),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'AI-personalised picks based on your profile',
                  style: AppTextStyles.bodyMedium,
                ),

                if (_fromCache) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.offline_bolt_rounded,
                          color: Color(0xFF1A6B4A), size: 14),
                      const SizedBox(width: 6),
                      Text('From cache — ',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: const Color(0xFF1A6B4A))),
                      GestureDetector(
                        onTap: () => _load(forceRefresh: true),
                        child: Text('Refresh',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Search bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                    border: Border.all(
                        color: const Color(0xFFDDE8F5), width: 1.5),
                  ),
                  child: TextField(
                    onChanged: _onSearch,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search careers...',
                      hintStyle: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                      icon: const Icon(Icons.search_rounded,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Body ────────────────────────────────────────────────────────────
        if (_loading)
          const SliverFillRemaining(child: _LoadingView())
        else if (_error != null)
          SliverFillRemaining(
              child: _ErrorView(error: _error!, onRetry: _load))
        else if (_filtered.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text('No careers match "$_query"',
                  style: AppTextStyles.bodyMedium),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final career = _filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CareerCard(
                      title: career.title,
                      matchPercent: career.match,
                      description: career.description,
                      color: _categoryColor(career.category),
                      icon: _categoryIcon(career.category),
                      onViewRoadmap: () => _openRoadmap(context, career),
                    )
                        .animate(delay: Duration(milliseconds: index * 80))
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                  );
                },
                childCount: _filtered.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return const Color(0xFF052659);
      case 'business':
        return const Color(0xFF1A6B4A);
      case 'healthcare':
        return const Color(0xFFE53935);
      case 'design':
        return const Color(0xFF7C4DFF);
      case 'education':
        return const Color(0xFF9C27B0);
      case 'science':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF5483B3);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return Icons.code_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'healthcare':
        return Icons.local_hospital_rounded;
      case 'design':
        return Icons.design_services_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'science':
        return Icons.science_rounded;
      default:
        return Icons.work_rounded;
    }
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 3),
            const SizedBox(height: 20),
            Text('Finding careers for you...', style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            Text('AI is personalising based on your profile',
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1200.ms, color: AppColors.lightAccent),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: Color(0xFFFFF0F0), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFE53935), size: 32),
            ),
            const SizedBox(height: 16),
            Text('Oops!', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(error,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
