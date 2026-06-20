import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/quiz_service.dart';

// ── Constants ─────────────────────────────────────────────────────────────────
const int _kSecondsPerQuestion = 30;

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with WidgetsBindingObserver {
  final _service = QuizService();

  // Load state
  Quiz? _quiz;
  String? _error;
  bool _loading = true;
  bool _alreadyDone = false;

  // Quiz progress
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _quizFinished = false;
  int _earnedXP = 0;

  // Timer
  Timer? _timer;
  int _secondsLeft = _kSecondsPerQuestion;

  // Tab-switch penalty
  bool _penalised = false;
  bool _showPenaltyBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // ── App lifecycle — tab switch / background detection ─────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_quiz == null || _quizFinished || _answered || _alreadyDone) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _applyPenalty();
    }
  }

  void _applyPenalty() {
    _timer?.cancel();
    setState(() {
      _score = 0;         // wipe all points
      _penalised = true;
      _showPenaltyBanner = true;
    });
    // Auto-hide banner after 3 seconds then continue quiz (timer resets)
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showPenaltyBanner = false);
      if (!_answered) _startTimer();
    });
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final canTake = await QuizService.canTakeQuizToday();
    if (!canTake) {
      setState(() {
        _loading = false;
        _alreadyDone = true;
      });
      return;
    }
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _service.generateQuiz();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _quiz = result.quiz;
      } else {
        _error = result.errorMessage;
      }
    });
    if (result.isSuccess) _startTimer();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _kSecondsPerQuestion);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        _onTimeUp();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onTimeUp() {
    if (_answered) return;
    // Auto-mark as wrong (no answer selected) and move on
    setState(() {
      _answered = true;
      _selectedAnswer = null; // nothing selected = wrong
    });
  }

  // ── Answer & navigation ───────────────────────────────────────────────────

  void _selectAnswer(String option) {
    if (_answered) return;
    _timer?.cancel();
    setState(() {
      _selectedAnswer = option;
      _answered = true;
      if (!_penalised &&
          option == _quiz!.questions[_currentIndex].correct) {
        _score++;
      }
    });
  }

  void _next() {
    if (_currentIndex < _quiz!.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    _timer?.cancel();
    final xpEarned = _score;
    await QuizService.addXP(xpEarned);
    await QuizService.markQuizDone();
    setState(() {
      _earnedXP = xpEarned;
      _quizFinished = true;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Daily Quiz', style: AppTextStyles.titleLarge),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBody(),
          // Penalty banner
          if (_showPenaltyBanner) _PenaltyBanner(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const _LoadingView();
    if (_alreadyDone) return _AlreadyDoneView(onPop: () => Navigator.of(context).pop());
    if (_error != null) return _ErrorView(error: _error!, onRetry: _loadQuiz);
    if (_quizFinished) {
      return _ResultView(
        score: _score,
        total: _quiz!.questions.length,
        xpEarned: _earnedXP,
        subject: _quiz!.subject,
        penalised: _penalised,
        onPop: () => Navigator.of(context).pop(),
      );
    }
    return _QuizView(
      quiz: _quiz!,
      currentIndex: _currentIndex,
      selectedAnswer: _selectedAnswer,
      answered: _answered,
      secondsLeft: _secondsLeft,
      onSelect: _selectAnswer,
      onNext: _next,
    );
  }
}

// ── Penalty banner ────────────────────────────────────────────────────────────

class _PenaltyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFE53935).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tab Switch Detected!',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    Text('All your points have been removed.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fade(duration: 300.ms)
            .slideY(begin: -0.3, end: 0, curve: Curves.easeOut),
      ),
    );
  }
}

// ── Quiz view ─────────────────────────────────────────────────────────────────

class _QuizView extends StatelessWidget {
  final Quiz quiz;
  final int currentIndex;
  final String? selectedAnswer;
  final bool answered;
  final int secondsLeft;
  final void Function(String) onSelect;
  final VoidCallback onNext;

  const _QuizView({
    required this.quiz,
    required this.currentIndex,
    required this.selectedAnswer,
    required this.answered,
    required this.secondsLeft,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final q = quiz.questions[currentIndex];
    final isLast = currentIndex == quiz.questions.length - 1;
    final progress = (currentIndex + 1) / quiz.questions.length;

    // Timer colour: green > yellow > red
    final timerColor = secondsLeft > 15
        ? const Color(0xFF4CAF50)
        : secondsLeft > 7
            ? const Color(0xFFFFB300)
            : const Color(0xFFE53935);

    return Column(
      children: [
        // ── Top bar: subject + counter + timer ─────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded,
                            color: AppColors.primary, size: 14),
                        const SizedBox(width: 5),
                        Text(quiz.subject,
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  // Timer pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: timerColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: timerColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_rounded, color: timerColor, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '${secondsLeft}s',
                          style: AppTextStyles.labelMedium.copyWith(
                              color: timerColor, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Animated progress bar
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE8F5),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = (constraints.maxWidth * progress).clamp(0.0, constraints.maxWidth);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        height: 6,
                        width: barWidth,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${currentIndex + 1} / ${quiz.questions.length}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),

        // ── Question + options ─────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timer countdown bar inside question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thin time remaining bar at top of card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: secondsLeft / _kSecondsPerQuestion,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Question ${q.id}',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: Colors.white)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        q.question,
                        style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.4),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fade(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                // Options
                ...q.options.entries.map((entry) {
                  final key = entry.key;
                  final val = entry.value;
                  final isSelected = selectedAnswer == key;
                  final isCorrect = key == q.correct;

                  Color borderColor = const Color(0xFFDDE8F5);
                  Color bgColor = AppColors.surface;
                  Color textColor = AppColors.textPrimary;
                  IconData? trailingIcon;

                  if (answered) {
                    if (isCorrect) {
                      borderColor = const Color(0xFF4CAF50);
                      bgColor = const Color(0xFFF1FFF1);
                      textColor = const Color(0xFF2E7D32);
                      trailingIcon = Icons.check_circle_rounded;
                    } else if (isSelected && !isCorrect) {
                      borderColor = const Color(0xFFE53935);
                      bgColor = const Color(0xFFFFF0F0);
                      textColor = const Color(0xFFE53935);
                      trailingIcon = Icons.cancel_rounded;
                    }
                  } else if (isSelected) {
                    borderColor = AppColors.primary;
                    bgColor = AppColors.primary.withOpacity(0.06);
                    textColor = AppColors.primary;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => onSelect(key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 2),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: borderColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(key,
                                    style: AppTextStyles.titleSmall.copyWith(
                                        color: borderColor,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(val,
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: textColor)),
                            ),
                            if (trailingIcon != null)
                              Icon(trailingIcon, color: borderColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Time-up notice (no answer selected)
                if (answered && selectedAnswer == null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFFB300).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_off_rounded,
                            color: Color(0xFFFFB300), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text("Time's up! No answer selected.",
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: const Color(0xFFE65100))),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 300.ms),
                  const SizedBox(height: 8),
                ],

                // Explanation
                if (answered) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(q.explanation,
                              style: AppTextStyles.bodySmall
                                  .copyWith(height: 1.5)),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Next button
        if (answered)
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24,
                MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'Finish Quiz' : 'Next Question',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Icon(isLast
                        ? Icons.flag_rounded
                        : Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ).animate().fade(duration: 300.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }
}

// ── Result view ───────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final int score;
  final int total;
  final int xpEarned;
  final String subject;
  final bool penalised;
  final VoidCallback onPop;

  const _ResultView({
    required this.score,
    required this.total,
    required this.xpEarned,
    required this.subject,
    required this.penalised,
    required this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (score / total * 100).round();
    final isPerfect = score == total && !penalised;
    final isGood = score >= total * 0.7 && !penalised;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy / result icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: penalised
                    ? const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFB71C1C)])
                    : isPerfect
                        ? const LinearGradient(
                            colors: [Color(0xFFFFB300), Color(0xFFFF8F00)])
                        : isGood
                            ? AppColors.primaryGradient
                            : const LinearGradient(colors: [
                                Color(0xFF5483B3),
                                Color(0xFF7DA0CA)
                              ]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                penalised
                    ? Icons.gpp_bad_rounded
                    : isPerfect
                        ? Icons.emoji_events_rounded
                        : isGood
                            ? Icons.thumb_up_rounded
                            : Icons.school_rounded,
                color: Colors.white,
                size: 48,
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    curve: Curves.elasticOut,
                    duration: 700.ms)
                .fade(duration: 400.ms),

            const SizedBox(height: 24),

            Text(
              penalised
                  ? 'Tab Switch Penalty!'
                  : isPerfect
                      ? 'Perfect Score!'
                      : isGood
                          ? 'Great Job!'
                          : 'Keep Practicing!',
              style: AppTextStyles.displaySmall
                  .copyWith(fontWeight: FontWeight.w800),
            ).animate().fade(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 8),

            if (penalised)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'You switched tabs during the quiz.\nAll points were removed.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: const Color(0xFFE53935)),
                  textAlign: TextAlign.center,
                ),
              ).animate().fade(duration: 400.ms, delay: 300.ms)
            else
              Text(subject, style: AppTextStyles.bodyMedium)
                  .animate()
                  .fade(duration: 400.ms, delay: 300.ms),

            const SizedBox(height: 32),

            // Score card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ResultStat(
                    value: '$score/$total',
                    label: 'Correct',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF4CAF50),
                  ),
                  Container(width: 1, height: 50, color: const Color(0xFFEEF4FB)),
                  _ResultStat(
                    value: '$percent%',
                    label: 'Score',
                    icon: Icons.analytics_rounded,
                    color: AppColors.primary,
                  ),
                  Container(width: 1, height: 50, color: const Color(0xFFEEF4FB)),
                  _ResultStat(
                    value: '+$xpEarned',
                    label: 'XP Earned',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFF1A6B4A),
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms, delay: 400.ms),

            const SizedBox(height: 32),

            // XP banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: penalised
                    ? const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFB71C1C)])
                    : const LinearGradient(
                        colors: [Color(0xFF1A6B4A), Color(0xFF2E9E6E)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    penalised
                        ? Icons.block_rounded
                        : Icons.bolt_rounded,
                    color: penalised
                        ? Colors.white
                        : const Color(0xFFFFE082),
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        penalised
                            ? '0 XP — Penalty Applied'
                            : '+$xpEarned XP Points Earned!',
                        style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        penalised
                            ? 'Stay focused next time!'
                            : '1 XP per correct answer',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms, delay: 500.ms),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Back to Dashboard',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: Colors.white)),
              ),
            ).animate().fade(duration: 400.ms, delay: 600.ms),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _ResultStat(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: AppTextStyles.titleLarge
                .copyWith(color: color, fontWeight: FontWeight.w800)),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

// ── Already done view ─────────────────────────────────────────────────────────

class _AlreadyDoneView extends StatelessWidget {
  final VoidCallback onPop;
  const _AlreadyDoneView({required this.onPop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 20),
            Text("Today's Quiz Done!",
                style: AppTextStyles.headlineMedium
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              "You've already completed today's quiz.\nCome back tomorrow for a new one!",
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onPop,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
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
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 3),
                const SizedBox(height: 20),
                Text("Generating today's quiz...",
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 6),
                Text('AI is picking NEB syllabus questions',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
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
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFE53935), size: 48),
            const SizedBox(height: 16),
            Text('Failed to load quiz', style: AppTextStyles.headlineSmall),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
