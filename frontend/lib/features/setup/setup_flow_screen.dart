import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/api_constants.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/career_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/selection_card.dart';
import '../../shared/widgets/career_card.dart';
import '../career/roadmap_screen.dart';

class SetupFlowScreen extends StatefulWidget {
  const SetupFlowScreen({super.key});

  @override
  State<SetupFlowScreen> createState() => _SetupFlowScreenState();
}

class _SetupFlowScreenState extends State<SetupFlowScreen> {
  int _currentStep = 0;
  final int _totalSteps = 6;

  String? _selectedFaculty;
  String? _selectedGrade;
  final Set<String> _selectedInterests = {};
  final Set<String> _selectedSkills = {};
  String? _selectedGoal;

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedFaculty != null;
      case 1:
        return _selectedGrade != null;
      case 2:
        return _selectedInterests.isNotEmpty;
      case 3:
        return _selectedSkills.isNotEmpty;
      case 4:
        return _selectedGoal != null;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keySetupDone, true);
    await prefs.setString(AppConstants.keyFaculty, _selectedFaculty ?? '');
    await prefs.setString(AppConstants.keyGrade, _selectedGrade ?? '');
    await prefs.setStringList(AppConstants.keyInterests, _selectedInterests.toList());
    await prefs.setStringList(AppConstants.keySkills, _selectedSkills.toList());
    await prefs.setString(AppConstants.keyGoal, _selectedGoal ?? '');

    // Clear career suggestions cache so the tab regenerates with new profile
    await prefs.remove('career_suggestions_cache');

    final token = prefs.getString(AppConstants.keyAuthToken);
    if (token != null) {
      await AuthService().saveProfile(
        token: token,
        faculty: _selectedFaculty ?? '',
        grade: _selectedGrade ?? '',
        interests: _selectedInterests.toList(),
        skills: _selectedSkills.toList(),
        goal: _selectedGoal ?? '',
      );
    }

    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOut)),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
            if (_currentStep < 5) _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    const stepTitles = [
      'Select Faculty',
      'Your Grade',
      'Your Interests',
      'Your Skills',
      'Your Goal',
      'Career Matches',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.horizontalPadding, 16, AppConstants.horizontalPadding, 0),
      child: Row(
        children: [
          if (_currentStep > 0 && _currentStep < 5)
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: AppColors.cardShadow,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary, size: 16),
              ),
            )
          else
            const SizedBox(width: 42),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style:
                      AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  stepTitles[_currentStep],
                  style: AppTextStyles.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.horizontalPadding, 16, AppConstants.horizontalPadding, 0),
      child: Row(
        children: List.generate(
          _totalSteps,
          (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 4 : 0),
              height: 5,
              decoration: BoxDecoration(
                color: i <= _currentStep
                    ? AppColors.primary
                    : const Color(0xFFDDE8F5),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _FacultyStep(
            selected: _selectedFaculty,
            onSelect: (v) => setState(() => _selectedFaculty = v));
      case 1:
        return _GradeStep(
            selected: _selectedGrade,
            onSelect: (v) => setState(() => _selectedGrade = v));
      case 2:
        return _InterestsStep(
          faculty: _selectedFaculty ?? '',
          grade: _selectedGrade ?? '',
          selected: _selectedInterests,
          onToggle: (v) => setState(() {
            _selectedInterests.contains(v)
                ? _selectedInterests.remove(v)
                : _selectedInterests.add(v);
          }),
        );
      case 3:
        return _SkillsStep(
          selected: _selectedSkills,
          onToggle: (v) => setState(() {
            _selectedSkills.contains(v)
                ? _selectedSkills.remove(v)
                : _selectedSkills.add(v);
          }),
        );
      case 4:
        return _GoalStep(
            selected: _selectedGoal,
            onSelect: (v) => setState(() => _selectedGoal = v));
      case 5:
        return _CareerResultsStep(
          faculty: _selectedFaculty ?? '',
          grade: _selectedGrade ?? '',
          interests: _selectedInterests.toList(),
          skills: _selectedSkills.toList(),
          goal: _selectedGoal ?? '',
          onFinish: _finish,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.horizontalPadding,
        right: AppConstants.horizontalPadding,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AppButton(
        label: _currentStep == 4 ? 'See My Career Matches' : 'Continue',
        icon: _currentStep == 4
            ? const Icon(Icons.gps_fixed_rounded,
                color: Colors.white, size: 18)
            : null,
        onTap: _canProceed ? _nextStep : null,
        isDisabled: !_canProceed,
        variant: _currentStep == 4
            ? AppButtonVariant.gradient
            : AppButtonVariant.primary,
      ),
    );
  }
}

// ─── Step 1: Faculty ──────────────────────────────────────────────────────────

class _FacultyStep extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;
  const _FacultyStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text('What is your field of study?',
                  style: AppTextStyles.headlineLarge),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select the faculty that best describes your academic path.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.5,
            ),
            itemCount: AppConstants.faculties.length,
            itemBuilder: (context, index) {
              final faculty = AppConstants.faculties[index];
              final isSelected = selected == faculty['name'];
              return SelectionCard(
                label: faculty['name'] as String,
                icon: faculty['icon'] as IconData,
                isSelected: isSelected,
                accentColor: Color(faculty['color'] as int),
                onTap: () => onSelect(faculty['name'] as String),
              )
                  .animate(delay: Duration(milliseconds: index * 80))
                  .fade(duration: 300.ms)
                  .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      curve: Curves.easeOut);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Grade ────────────────────────────────────────────────────────────

class _GradeStep extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;
  const _GradeStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.school_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text('What grade are you in?',
                  style: AppTextStyles.headlineLarge),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'This helps us personalise your learning experience.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.0,
            ),
            itemCount: AppConstants.grades.length,
            itemBuilder: (context, index) {
              final grade = AppConstants.grades[index];
              final isSelected = selected == grade['name'];
              return SelectionCard(
                label: grade['name'] as String,
                icon: grade['icon'] as IconData,
                badgeLabel: grade['label'] as String,
                isSelected: isSelected,
                onTap: () => onSelect(grade['name'] as String),
                compact: true,
              )
                  .animate(delay: Duration(milliseconds: index * 80))
                  .fade(duration: 300.ms)
                  .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      curve: Curves.easeOut);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Interests ────────────────────────────────────────────────────────

class _InterestsStep extends StatefulWidget {
  final String faculty;
  final String grade;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _InterestsStep({
    required this.faculty,
    required this.grade,
    required this.selected,
    required this.onToggle,
  });

  @override
  State<_InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<_InterestsStep> {
  List<InterestOption> _options = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    setState(() { _loading = true; _error = null; });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAuthToken) ?? '';

    final result = await fetchInterestSuggestions(
      faculty: widget.faculty,
      grade: widget.grade,
      token: token,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _options = result.interests!;
      } else {
        _error = result.errorMessage;
        // Fallback to static list
        _options = AppConstants.interests
            .map((i) => InterestOption(name: i, iconKey: 'other'))
            .toList();
      }
    });
  }

  IconData _iconFor(String key) {
    switch (key.toLowerCase()) {
      case 'technology':   return Icons.devices_rounded;
      case 'business':     return Icons.business_rounded;
      case 'healthcare':   return Icons.local_hospital_rounded;
      case 'design':       return Icons.palette_rounded;
      case 'education':    return Icons.school_rounded;
      case 'science':      return Icons.science_rounded;
      case 'arts':         return Icons.brush_rounded;
      case 'law':          return Icons.gavel_rounded;
      case 'engineering':  return Icons.engineering_rounded;
      case 'media':        return Icons.movie_rounded;
      case 'environment':  return Icons.eco_rounded;
      case 'psychology':   return Icons.psychology_rounded;
      case 'finance':      return Icons.account_balance_wallet_rounded;
      case 'sports':       return Icons.sports_rounded;
      case 'government':   return Icons.account_balance_rounded;
      default:             return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('What are you interested in?',
                    style: AppTextStyles.headlineLarge),
              ),
              if (!_loading)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.primary, size: 20),
                  tooltip: 'Regenerate',
                  onPressed: _fetchOptions,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('AI-generated based on your faculty & grade — select at least one.',
              style: AppTextStyles.bodyMedium),

          if (widget.selected.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 5),
                  Text('${widget.selected.length} selected',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 3),
                    SizedBox(height: 16),
                    Text('AI is generating interests for your faculty...',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _options.asMap().entries.map((entry) {
                final opt = entry.value;
                final isSelected = widget.selected.contains(opt.name);
                return GestureDetector(
                  onTap: () => widget.onToggle(opt.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFDDE8F5),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? AppColors.buttonShadow
                          : AppColors.cardShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconFor(opt.iconKey),
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(opt.name,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                )
                    .animate(delay: Duration(milliseconds: entry.key * 50))
                    .fade(duration: 300.ms)
                    .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1, 1),
                        curve: Curves.easeOut);
              }).toList(),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ─── Step 4: Skills ───────────────────────────────────────────────────────────

class _SkillsStep extends StatelessWidget {
  final Set<String> selected;
  final void Function(String) onToggle;
  const _SkillsStep({required this.selected, required this.onToggle});

  static const Map<String, IconData> _skillIcons = {
    'Problem Solving': Icons.lightbulb_rounded,
    'Communication': Icons.forum_rounded,
    'Leadership': Icons.groups_rounded,
    'Mathematics': Icons.calculate_rounded,
    'Creativity': Icons.auto_awesome_rounded,
    'Writing': Icons.edit_rounded,
    'Programming': Icons.code_rounded,
    'Research': Icons.search_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text('What are your strengths?',
                  style: AppTextStyles.headlineLarge),
            ],
          ),
          const SizedBox(height: 6),
          Text('Select skills you already have or want to develop.',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 10),
          if (selected.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '${selected.length} selected',
                    style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: AppConstants.skills.length,
            itemBuilder: (context, index) {
              final skill = AppConstants.skills[index];
              final isSelected = selected.contains(skill);
              final icon =
                  _skillIcons[skill] ?? Icons.star_rounded;
              return GestureDetector(
                onTap: () => onToggle(skill),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFDDE8F5),
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          skill,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(
                      delay: Duration(milliseconds: index * 70))
                  .fade(duration: 300.ms)
                  .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      curve: Curves.easeOut);
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ─── Step 5: Goal ─────────────────────────────────────────────────────────────

class _GoalStep extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;
  const _GoalStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.gps_fixed_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text('What is your primary goal?',
                  style: AppTextStyles.headlineLarge),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "We'll tailor your experience around what matters most to you.",
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          ...AppConstants.goals.asMap().entries.map((entry) {
            final goal = entry.value;
            final isSelected = selected == goal['name'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SelectionCard(
                label: goal['name'] as String,
                icon: goal['icon'] as IconData,
                description: goal['desc'] as String,
                isSelected: isSelected,
                onTap: () => onSelect(goal['name'] as String),
              )
                  .animate(
                      delay: Duration(milliseconds: entry.key * 100))
                  .fade(duration: 400.ms)
                  .slideX(
                      begin: -0.15,
                      end: 0,
                      curve: Curves.easeOut,
                      duration: 400.ms),
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ─── Step 6: Career Results ───────────────────────────────────────────────────

class _CareerResultsStep extends StatefulWidget {
  final String faculty;
  final String grade;
  final List<String> interests;
  final List<String> skills;
  final String goal;
  final VoidCallback onFinish;

  const _CareerResultsStep({
    required this.faculty,
    required this.grade,
    required this.interests,
    required this.skills,
    required this.goal,
    required this.onFinish,
  });

  @override
  State<_CareerResultsStep> createState() => _CareerResultsStepState();
}

class _CareerResultsStepState extends State<_CareerResultsStep> {
  final _service = CareerService();
  List<CareerSuggestion> _careers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });

    // Build a temporary prefs-like context using the in-memory profile
    // by temporarily saving to prefs so the service can read them
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyFaculty, widget.faculty);
    await prefs.setString(AppConstants.keyGrade, widget.grade);
    await prefs.setStringList(AppConstants.keyInterests, widget.interests);
    await prefs.setStringList(AppConstants.keySkills, widget.skills);
    await prefs.setString(AppConstants.keyGoal, widget.goal);
    // Always force-refresh here so it uses the just-entered profile
    await prefs.remove('career_suggestions_cache');

    final result = await _service.getSuggestions(forceRefresh: true);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _careers = result.careers!;
      } else {
        _error = result.errorMessage;
      }
    });
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'technology':  return const Color(0xFF052659);
      case 'business':    return const Color(0xFF1A6B4A);
      case 'healthcare':  return const Color(0xFFE53935);
      case 'design':      return const Color(0xFF7C4DFF);
      case 'education':   return const Color(0xFF9C27B0);
      case 'science':     return const Color(0xFF4CAF50);
      default:            return const Color(0xFF5483B3);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technology':  return Icons.code_rounded;
      case 'business':    return Icons.business_center_rounded;
      case 'healthcare':  return Icons.local_hospital_rounded;
      case 'design':      return Icons.design_services_rounded;
      case 'education':   return Icons.school_rounded;
      case 'science':     return Icons.science_rounded;
      default:            return Icons.work_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.celebration_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your Career Matches',
                  style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI-personalised picks based on your profile. Explore and find what excites you!',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ).animate().fade(duration: 500.ms).scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              curve: Curves.easeOut),

          const SizedBox(height: 24),

          if (_loading)
            Center(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 3),
                    const SizedBox(height: 16),
                    Text('Finding your career matches...',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 6),
                    Text('AI is analysing your profile',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 1200.ms, color: AppColors.lightAccent),
            )
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  Text(_error!, style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            )
          else
            ..._careers.asMap().entries.map((entry) {
              final career = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CareerCard(
                  title: career.title,
                  matchPercent: career.match,
                  description: career.description,
                  color: _categoryColor(career.category),
                  icon: _categoryIcon(career.category),
                  onViewRoadmap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RoadmapScreen(
                        careerTitle: career.title,
                        careerColor: _categoryColor(career.category),
                        careerIcon: _categoryIcon(career.category),
                        matchPercent: career.match,
                      ),
                    ));
                  },
                )
                    .animate(delay: Duration(milliseconds: 200 + entry.key * 120))
                    .fade(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
              );
            }),

          const SizedBox(height: 24),

          if (!_loading)
            AppButton(
              label: 'Go to Dashboard',
              icon: const Icon(Icons.rocket_launch_rounded,
                  color: Colors.white, size: 18),
              onTap: widget.onFinish,
              variant: AppButtonVariant.gradient,
            )
                .animate(delay: 800.ms)
                .fade(duration: 500.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
