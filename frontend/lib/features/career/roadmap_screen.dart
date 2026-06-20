import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/career_service.dart';

class RoadmapScreen extends StatefulWidget {
  final String careerTitle;
  final Color careerColor;
  final IconData careerIcon;
  final int matchPercent;

  const RoadmapScreen({
    super.key,
    required this.careerTitle,
    required this.careerColor,
    required this.careerIcon,
    required this.matchPercent,
  });

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final _service = CareerService();
  CareerRoadmap? _roadmap;
  String? _error;
  bool _loading = true;
  bool _fromCache = false;

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
    final result = await _service.getRoadmap(widget.careerTitle,
        forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _roadmap    = result.roadmap;
        _fromCache  = result.fromCache;
      } else {
        _error = result.errorMessage;
      }
    });
  }

  Future<void> _refresh() async {
    // Confirm before hitting AI again (costs time)
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Regenerate Roadmap?',
            style: AppTextStyles.titleLarge),
        content: Text(
          'This will ask the AI to generate a fresh roadmap for ${widget.careerTitle}. The current one will be replaced.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style:
                    AppTextStyles.titleSmall.copyWith(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Regenerate',
                style: AppTextStyles.titleSmall
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (go == true) _load(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_loading)
            const SliverFillRemaining(child: _LoadingView())
          else if (_error != null)
            SliverFillRemaining(child: _ErrorView(error: _error!, onRetry: _load))
          else
            _buildContent(),
        ],
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: widget.careerColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        // Refresh / regenerate button — only shown when not loading
        if (!_loading)
          IconButton(
            tooltip: 'Regenerate roadmap',
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 22),
            onPressed: _refresh,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.careerColor, widget.careerColor.withOpacity(0.75)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(widget.careerIcon,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.careerTitle,
                              style: AppTextStyles.headlineMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded,
                                      color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI Generated Roadmap',
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Match badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${widget.matchPercent}%',
                              style: AppTextStyles.titleLarge.copyWith(
                                  color: widget.careerColor,
                                  fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Match',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: widget.careerColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent() {
    final r = _roadmap!;
    return SliverPadding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Cache badge
          if (_fromCache)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A6B4A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF1A6B4A).withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.offline_bolt_rounded,
                            color: Color(0xFF1A6B4A), size: 14),
                        const SizedBox(width: 6),
                        Text('Loaded from cache',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: const Color(0xFF1A6B4A),
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _refresh,
                          child: Text('Refresh',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Overview
          _SectionCard(
            icon: Icons.info_outline_rounded,
            color: widget.careerColor,
            title: 'Overview',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.overview,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.careerColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.gps_fixed_rounded,
                          color: widget.careerColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r.matchReason,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: widget.careerColor, height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Quick stats
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.attach_money_rounded,
                  label: 'Salary',
                  value: r.salaryRange,
                  color: const Color(0xFF1A6B4A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  icon: Icons.trending_up_rounded,
                  label: 'Job Demand',
                  value: r.jobDemand,
                  color: _demandColor(r.jobDemand),
                ),
              ),
            ],
          ).animate(delay: 100.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Top skills
          _SectionCard(
            icon: Icons.psychology_rounded,
            color: const Color(0xFF7C4DFF),
            title: 'Top Skills Needed',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: r.topSkillsNeeded
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C4DFF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF7C4DFF).withOpacity(0.3)),
                        ),
                        child: Text(s,
                            style: AppTextStyles.labelMedium.copyWith(
                                color: const Color(0xFF7C4DFF))),
                      ))
                  .toList(),
            ),
          ).animate(delay: 150.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Roadmap steps
          _SectionCard(
            icon: Icons.map_rounded,
            color: widget.careerColor,
            title: 'Learning Roadmap',
            child: Column(
              children: r.steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                final isLast = i == r.steps.length - 1;
                return _RoadmapStepTile(
                  step: step,
                  color: widget.careerColor,
                  isLast: isLast,
                );
              }).toList(),
            ),
          ).animate(delay: 200.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Pros & Cons
          _SectionCard(
            icon: Icons.balance_rounded,
            color: const Color(0xFF1A6B4A),
            title: 'Pros & Cons',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pros
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.thumb_up_rounded,
                              color: Color(0xFF4CAF50), size: 13),
                          const SizedBox(width: 5),
                          Text('Pros',
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: const Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...r.pros.map((p) => _ProConTile(
                      item: p,
                      isPro: true,
                    )),
                const SizedBox(height: 16),
                // Cons
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.thumb_down_rounded,
                              color: Color(0xFFE53935), size: 13),
                          const SizedBox(width: 5),
                          Text('Cons',
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: const Color(0xFFE53935),
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...r.cons.map((c) => _ProConTile(
                      item: c,
                      isPro: false,
                    )),
              ],
            ),
          ).animate(delay: 250.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  Color _demandColor(String demand) {
    switch (demand.toLowerCase()) {
      case 'high':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFFFB300);
      default:
        return const Color(0xFFE53935);
    }
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: AppTextStyles.titleLarge
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelSmall),
                Text(value,
                    style: AppTextStyles.titleSmall.copyWith(
                        color: color, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapStepTile extends StatelessWidget {
  final RoadmapStep step;
  final Color color;
  final bool isLast;

  const _RoadmapStepTile({
    required this.step,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(
                    '${step.step}',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withOpacity(0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(step.title,
                            style: AppTextStyles.titleMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(step.duration,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(step.description,
                      style:
                          AppTextStyles.bodySmall.copyWith(height: 1.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: step.resources
                        .map((r) => ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.lightAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.link_rounded,
                                        size: 11,
                                        color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        r,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(color: AppColors.primary),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProConTile extends StatelessWidget {
  final ProCon item;
  final bool isPro;

  const _ProConTile({required this.item, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final color =
        isPro ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPro
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              color: color,
              size: 12,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppTextStyles.titleSmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(item.description,
                    style:
                        AppTextStyles.bodySmall.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading view ──────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text('Generating your roadmap...',
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 6),
                Text('AI is personalising this for your profile',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 1200.ms, color: AppColors.lightAccent),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

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
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                shape: BoxShape.circle,
              ),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
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
