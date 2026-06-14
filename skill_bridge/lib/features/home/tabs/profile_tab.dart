import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/quiz_service.dart';
import '../../quiz/quiz_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String _userName  = '';
  String _email     = '';
  String _faculty   = '';
  String _grade     = '';
  String _goal      = '';
  List<String> _interests = [];
  List<String> _skills    = [];
  int  _xp        = 0;
  int  _quizCount = 0;
  bool _loaded    = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final xp    = await QuizService.getXP();
    if (!mounted) return;
    // getStringList returns null on web when key absent — cast safely
    final rawInterests = prefs.getStringList(AppConstants.keyInterests);
    final rawSkills    = prefs.getStringList(AppConstants.keySkills);
    setState(() {
      _userName   = prefs.getString(AppConstants.keyUserName)  ?? 'Student';
      _email      = prefs.getString(AppConstants.keyUserEmail) ?? '';
      _faculty    = prefs.getString(AppConstants.keyFaculty)   ?? '';
      _grade      = prefs.getString(AppConstants.keyGrade)     ?? '';
      _goal       = prefs.getString(AppConstants.keyGoal)      ?? '';
      _interests  = rawInterests == null
          ? <String>[]
          : List<String>.from(rawInterests);
      _skills     = rawSkills == null
          ? <String>[]
          : List<String>.from(rawSkills);
      _xp         = xp;
      _quizCount  = prefs.getInt(AppConstants.keyQuizCount) ?? 0;
      _loaded     = true;
    });
  }

  String get _initials {
    final parts = _userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S';
  }

  String get _subtitle {
    final parts = <String>[];
    if (_faculty.isNotEmpty) parts.add(_faculty);
    if (_grade.isNotEmpty)   parts.add(_grade);
    return parts.isNotEmpty ? parts.join(' · ') : 'Complete your profile';
  }

  // ── Dialogs / sheets ──────────────────────────────────────────────────────

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign out?', style: AppTextStyles.titleLarge),
        content: Text('You\'ll need to log in again.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Sign out',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyIsLoggedIn);
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserEmail);
    if (mounted) context.go(AppRoutes.onboarding);
  }

  void _openEditProfile() {
    final nameCtrl  = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _email);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDDE8F5),
                      borderRadius: BorderRadius.circular(100)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Edit Profile', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 20),
              _field(nameCtrl, 'Name', Icons.person_outline_rounded),
              const SizedBox(height: 14),
              _field(emailCtrl, 'Email', Icons.email_outlined,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    if (nameCtrl.text.trim().isNotEmpty) {
                      await prefs.setString(
                          AppConstants.keyUserName, nameCtrl.text.trim());
                    }
                    if (emailCtrl.text.trim().isNotEmpty) {
                      await prefs.setString(
                          AppConstants.keyUserEmail, emailCtrl.text.trim());
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  },
                  child: Text('Save',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? type}) {
    return TextField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  void _openQuizHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDE8F5),
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Quiz Stats', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        value: _quizCount.toString(),
                        label: 'Quizzes',
                        icon: Icons.quiz_rounded,
                        color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        value: _xp.toString(),
                        label: 'XP Earned',
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFF1A6B4A))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Take Today\'s Quiz'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const QuizScreen()));
                  _load();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Help & Support', style: AppTextStyles.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _helpRow(Icons.quiz_rounded, 'Daily Quiz',
                'Take one quiz per day to earn XP points.'),
            _helpRow(Icons.map_rounded, 'Career Roadmap',
                'Explore AI-generated roadmaps for your chosen career.'),
            _helpRow(Icons.bolt_rounded, 'XP Points',
                'Earn 1 XP per correct quiz answer. Upload a PDF costs 2 XP.'),
            _helpRow(Icons.warning_rounded, 'Tab Switch',
                'Switching tabs during a quiz clears all your points.'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Got it',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.primary))),
        ],
      ),
    );
  }

  Widget _helpRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.titleSmall
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(desc, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.connecting_airports_rounded,
                  color: Colors.white, size: 38),
            ),
            const SizedBox(height: 16),
            Text(AppConstants.appName,
                style: AppTextStyles.headlineMedium
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Version ${AppConstants.appVersion}',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            Text(AppConstants.appTagline,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Skill Bridge helps Nepal NEB students discover career paths, take AI-powered quizzes, and build a personalised learning roadmap.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.primary))),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _loaded
                ? _buildBody()
                : const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildHero(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding),
          child: Column(
            children: [
              _buildXpCard(),
              const SizedBox(height: 14),
              if (_faculty.isNotEmpty ||
                  _grade.isNotEmpty ||
                  (_interests.isNotEmpty == true) ||
                  (_skills.isNotEmpty == true)) ...[
                _buildProfileDetailsCard(),
                const SizedBox(height: 14),
              ],
              _buildMenu(),
              const SizedBox(height: 14),
              _buildSignOut(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 32,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Stack(
        children: [
          // Bg circles
          Positioned(top: -30, right: -40,
            child: Container(width: 150, height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle))),
          Positioned(bottom: -20, left: -50,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                shape: BoxShape.circle))),

          // Avatar → name → details stacked centre
          Center(
            child: Column(
              children: [
                // Avatar with edit badge
                GestureDetector(
                  onTap: _openEditProfile,
                  child: Stack(
                    children: [
                      Container(
                        width: 92, height: 92,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.55),
                              width: 2.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Center(
                          child: Text(_initials,
                              style: AppTextStyles.headlineMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      Positioned(
                        bottom: 1, right: 1,
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 4)
                            ],
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 13, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .scale(
                        begin: const Offset(0.75, 0.75),
                        end: const Offset(1, 1),
                        duration: 550.ms,
                        curve: Curves.elasticOut)
                    .fade(duration: 300.ms),

                const SizedBox(height: 16),

                // Name
                Text(
                  _loaded ? _userName : '—',
                  style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ).animate().fade(duration: 400.ms, delay: 150.ms),

                const SizedBox(height: 4),

                // Faculty · Grade
                Text(
                  _subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.75)),
                  textAlign: TextAlign.center,
                ).animate().fade(duration: 400.ms, delay: 210.ms),

                if (_email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    _email,
                    style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.5)),
                    textAlign: TextAlign.center,
                  ).animate().fade(duration: 400.ms, delay: 260.ms),
                ],

                if (_goal.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gps_fixed_rounded,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 6),
                        Text(_goal,
                            style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ).animate().fade(duration: 400.ms, delay: 310.ms),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── XP card ───────────────────────────────────────────────────────────────

  Widget _buildXpCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          _StatPill(
            value: _xp.toString(),
            label: 'XP',
            icon: Icons.bolt_rounded,
            color: const Color(0xFF1A6B4A),
          ),
          _vDivider(),
          _StatPill(
            value: _quizCount.toString(),
            label: 'Quizzes',
            icon: Icons.quiz_rounded,
            color: AppColors.primary,
          ),
          _vDivider(),
          _StatPill(
            value: _grade.isNotEmpty ? _grade.replaceAll('Grade ', '') : '—',
            label: 'Grade',
            icon: Icons.school_rounded,
            color: AppColors.secondary,
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms, delay: 250.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40, color: const Color(0xFFEEF4FB));

  // ── Profile details ───────────────────────────────────────────────────────

  Widget _buildProfileDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.person_pin_rounded,
                    color: AppColors.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Text('About Me',
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: _openEditProfile,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Edit',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF0F4FF), height: 1),
          const SizedBox(height: 14),

          if (_faculty.isNotEmpty)
            _detailRow('Faculty', _faculty, Icons.account_balance_rounded),
          if (_grade.isNotEmpty)
            _detailRow('Grade', _grade, Icons.grade_rounded),
          if (_goal.isNotEmpty)
            _detailRow('Goal', _goal, Icons.gps_fixed_rounded),
          if (_interests.isNotEmpty == true)
            _chipsRow('Interests', List<String>.from(_interests), AppColors.primary),
          if (_skills.isNotEmpty == true)
            _chipsRow('Skills', List<String>.from(_skills), AppColors.secondary),
        ],
      ),
    ).animate().fade(duration: 400.ms, delay: 300.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(label,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _chipsRow(String label, List<String> items, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withOpacity(0.2), width: 1),
                      ),
                      child: Text(t,
                          style: AppTextStyles.labelSmall.copyWith(
                              color: color, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Menu ──────────────────────────────────────────────────────────────────

  Widget _buildMenu() {
    final items = [
      _MenuItem(
        icon: Icons.person_outline_rounded,
        label: 'Edit Profile',
        subtitle: 'Name, email & details',
        color: AppColors.primary,
        onTap: _openEditProfile,
      ),
      _MenuItem(
        icon: Icons.bar_chart_rounded,
        label: 'Quiz History',
        subtitle: '$_quizCount quizzes · $_xp XP',
        color: const Color(0xFF1A6B4A),
        onTap: _openQuizHistory,
      ),
      _MenuItem(
        icon: Icons.help_outline_rounded,
        label: 'Help & Support',
        subtitle: 'How SkillBridge works',
        color: AppColors.secondary,
        onTap: _openHelp,
      ),
      _MenuItem(
        icon: Icons.info_outline_rounded,
        label: 'About',
        subtitle: 'Version ${AppConstants.appVersion}',
        color: AppColors.textMuted,
        onTap: _openAbout,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              _MenuTile(item: e.value),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(color: Color(0xFFF0F4FF), height: 1),
                ),
            ],
          );
        }).toList(),
      ),
    ).animate().fade(duration: 400.ms, delay: 350.ms).slideY(begin: 0.06, end: 0);
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Widget _buildSignOut() {
    return Material(
      color: const Color(0xFFFFF3F3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.error.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.error.withOpacity(0.15), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 18),
              ),
              const SizedBox(width: 14),
              Text('Sign Out',
                  style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.error.withOpacity(0.5), size: 13),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms, delay: 420.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatPill({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800, color: color)),
              Text(label, style: AppTextStyles.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: item.color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(item.icon, color: item.color, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  if (item.subtitle.isNotEmpty)
                    Text(item.subtitle,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
