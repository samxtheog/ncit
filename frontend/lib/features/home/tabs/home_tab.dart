import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/services/career_service.dart';
import '../../quiz/quiz_screen.dart';
import '../../career/roadmap_screen.dart';
import '../../chat/ai_chat_screen.dart';

// Top career is fixed as the first entry in AppConstants.careerResults
final _topCareer = AppConstants.careerResults.first;

class HomeTab extends StatefulWidget {
  final void Function(int index)? onNavigateToTab;
  const HomeTab({super.key, this.onNavigateToTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _userName   = 'Sam';
  int    _xp         = 0;
  int    _quizCount  = 0;

  // Recommended path — derived from the top career's cached roadmap steps
  List<_PathItem> _pathSteps  = [];
  bool            _pathLoading = false;
  String?         _pathError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final xp    = await QuizService.getXP();
    if (!mounted) return;
    setState(() {
      _userName  = prefs.getString(AppConstants.keyUserName) ?? 'Sam';
      _xp        = xp;
      _quizCount = prefs.getInt(AppConstants.keyQuizCount)   ?? 0;
    });
    if (_pathSteps.isEmpty) _loadPath();
  }

  // ── Load path from cached career roadmap ───────────────────────────────────

  Future<void> _loadPath({bool forceRefresh = false}) async {
    final careerTitle = _topCareer['title'] as String;

    // 1. Try reading from the roadmap cache (set by roadmap_screen or here)
    if (!forceRefresh) {
      final cached = await CareerService.getCachedRoadmap(careerTitle);
      if (cached != null && cached.steps.isNotEmpty) {
        _applySteps(cached.steps);
        return;
      }
    }

    // 2. No cache — fetch from AI (same call the roadmap screen makes)
    if (!mounted) return;
    setState(() { _pathLoading = true; _pathError = null; });

    final result = await CareerService().getRoadmap(careerTitle,
        forceRefresh: forceRefresh);
    if (!mounted) return;

    if (result.isSuccess) {
      _applySteps(result.roadmap!.steps);
    } else {
      setState(() {
        _pathLoading = false;
        _pathError   = result.errorMessage ?? 'Could not load path.';
      });
    }
  }

  void _applySteps(List<RoadmapStep> steps) {
    setState(() {
      _pathSteps   = steps.map((s) => _PathItem(
            step:     s.step,
            title:    s.title,
            subtitle: s.duration,   // e.g. "3 months"
          )).toList();
      _pathLoading = false;
    });
  }

  Future<void> _refreshPath() async {
    await CareerService.clearCache(_topCareer['title'] as String);
    _loadPath(forceRefresh: true);
  }

  void _openRoadmap() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RoadmapScreen(
        careerTitle:  _topCareer['title']  as String,
        careerColor:  Color(_topCareer['color']  as int),
        careerIcon:   _topCareer['icon']   as IconData,
        matchPercent: _topCareer['match']  as int,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      displacement: 60,
      onRefresh: () async {
        await _loadData();
        await _loadPath(forceRefresh: false);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _buildCareerMatchBanner(),
                const SizedBox(height: 20),
                _buildStatsRow(),
                const SizedBox(height: 20),
                _buildQuickActionsSection(),
                const SizedBox(height: 20),
                _buildLearningPath(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.horizontalPadding,
        right: AppConstants.horizontalPadding,
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 20,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting row — icon instead of 👋
                Row(
                  children: [
                    Text(
                      'Hello, $_userName',
                      style: AppTextStyles.headlineMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.waving_hand_rounded,
                        color: Color(0xFFFFB300), size: 24),
                  ],
                ).animate().fade(duration: 500.ms).slideX(
                    begin: -0.15, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 4),
                Text(
                  'Ready to bridge your skills today?',
                  style: AppTextStyles.bodyMedium,
                ).animate().fade(duration: 500.ms, delay: 100.ms),
              ],
            ),
          ),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ).animate().fade(duration: 400.ms, delay: 300.ms),
        ],
      ),
    );
  }

  // ── Career match banner ────────────────────────────────────────────────────

  Widget _buildCareerMatchBanner() {
    final title       = _topCareer['title']  as String;
    final matchPct    = _topCareer['match']  as int;
    final icon        = _topCareer['icon']   as IconData;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFE082), size: 14),
                      const SizedBox(width: 4),
                      Text('Top Match',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(title,
                    style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$matchPct% match with your profile',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _openRoadmap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Roadmap',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.primary)),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.primary, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
        ],
      ),
    )
        .animate()
        .fade(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 200.ms,
            curve: Curves.easeOut);
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.bolt_rounded,
            value: _xp.toString(),
            subtitle: 'XP Points',
            color: const Color(0xFF1A6B4A),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            icon: Icons.quiz_rounded,
            value: _quizCount.toString(),
            subtitle: 'Quizzes',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            icon: Icons.picture_as_pdf_rounded,
            value: (_xp ~/ 2).toString(),
            subtitle: 'PDFs',
            color: AppColors.secondary,
          ),
        ),
      ],
    )
        .animate()
        .fade(duration: 500.ms, delay: 350.ms)
        .slideY(
            begin: 0.2,
            end: 0,
            duration: 500.ms,
            delay: 350.ms,
            curve: Curves.easeOut);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.displaySmall.copyWith(
                color: color, fontWeight: FontWeight.w800),
          ),
          Text(subtitle, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildActionButton(
              icon: Icons.upload_file_rounded,
              label: 'Upload PDF',
              color: const Color(0xFF5483B3),
              onTap: () => widget.onNavigateToTab?.call(2),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.smart_toy_rounded,
              label: 'AI Chat',
              color: AppColors.secondary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiChatScreen()),
              ),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.quiz_rounded,
              label: 'Take Quiz',
              color: const Color(0xFF1A6B4A),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuizScreen()),
                );
                _loadData(); // refresh XP after quiz
              },
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.map_rounded,
              label: 'Roadmap',
              color: const Color(0xFFD4732A),
              onTap: _openRoadmap,
            ),
          ],
        ),
      ],
    ).animate().fade(duration: 500.ms, delay: 450.ms);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall
                    .copyWith(color: color, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Learning path ──────────────────────────────────────────────────────────

  Widget _buildLearningPath() {
    final careerTitle = _topCareer['title'] as String;
    final careerColor = Color(_topCareer['color'] as int);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommended Path', style: AppTextStyles.headlineSmall),
                Text('for $careerTitle',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
            if (_pathLoading)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            else
              GestureDetector(
                onTap: _pathSteps.isNotEmpty ? _openRoadmap : _refreshPath,
                child: Text(
                  _pathSteps.isNotEmpty ? 'Full Roadmap' : 'Retry',
                  style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Skeleton ───────────────────────────────────────────────────────
        if (_pathSteps.isEmpty && _pathLoading)
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.cardShadow,
              ),
            ),
          ))

        // ── Error ──────────────────────────────────────────────────────────
        else if (_pathError != null && _pathSteps.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                const Icon(Icons.wifi_off_rounded,
                    color: AppColors.textMuted, size: 32),
                const SizedBox(height: 10),
                Text('Could not load path', style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(_pathError!,
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _refreshPath,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          )

        // ── Steps ──────────────────────────────────────────────────────────
        else
          ..._pathSteps.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LearningItem(
              step:        entry.value.step,
              title:       entry.value.title,
              subtitle:    entry.value.subtitle,
              color:       careerColor,
              isActive:    entry.key == 0,
            ),
          )),
      ],
    ).animate().fade(duration: 500.ms, delay: 550.ms);
  }
}

// ── Path item data class ───────────────────────────────────────────────────

class _PathItem {
  final int step;
  final String title;
  final String subtitle; // duration from roadmap step
  const _PathItem({required this.step, required this.title, required this.subtitle});
}

// ── Learning path item ─────────────────────────────────────────────────────

class _LearningItem extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final Color color;
  final bool isActive;

  const _LearningItem({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = isActive ? color : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.04) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? color.withOpacity(0.35) : const Color(0xFFEEF4FB),
          width: 1.5,
        ),
        boxShadow: isActive ? AppColors.cardShadow : [],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: itemColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$step',
                style: AppTextStyles.titleMedium.copyWith(
                    color: itemColor, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(subtitle,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(20)),
              child: Text('Active',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          else
            Icon(Icons.lock_outline_rounded,
                color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}
