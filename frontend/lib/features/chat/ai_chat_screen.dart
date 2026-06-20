import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/chat_service.dart';

// ─────────────────────────────────────────────────────────────────────────────

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _service = ChatService();
  final _ctrl    = TextEditingController();
  final _scroll  = ScrollController();
  final _focus   = FocusNode();

  final List<AiChatMessage> _messages = [];
  bool _sending = false;

  static const _suggestions = [
    (Icons.trending_up_rounded,    'Which career suits my profile?'),
    (Icons.school_rounded,         'How do I prepare for SEE?'),
    (Icons.lightbulb_outline_rounded, 'Share top study techniques'),
    (Icons.explore_rounded,        'What skills should I build now?'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final txt = (preset ?? _ctrl.text).trim();
    if (txt.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() {
      _messages.add(AiChatMessage.local('user', txt));
      _sending = true;
    });
    _scrollToBottom();
    try {
      final reply = await _service.send(txt);
      if (!mounted) return;
      setState(() {
        _messages.add(AiChatMessage.local('assistant', reply));
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(AiChatMessage.local(
            'assistant', 'Something went wrong — please try again.'));
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear conversation', style: AppTextStyles.titleLarge),
        content: Text('All messages will be removed.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style:
                      AppTextStyles.titleSmall.copyWith(color: AppColors.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Clear',
                  style:
                      AppTextStyles.titleSmall.copyWith(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    await _service.clearSession();
    if (mounted) setState(() => _messages.clear());
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Soft warm off-white chat background
    const chatBg = Color(0xFFF2F5FA);
    return Scaffold(
      backgroundColor: chatBg,
      body: Column(
        children: [
          _AppBar(
            hasMessages: _messages.isNotEmpty,
            onBack:  () => Navigator.of(context).pop(),
            onClear: _clearChat,
          ),
          Expanded(
            child: _messages.isEmpty ? _buildWelcome() : _buildMessages(),
          ),
          _InputBar(
            ctrl:     _ctrl,
            focus:    _focus,
            sending:  _sending,
            onSend:   _send,
          ),
        ],
      ),
    );
  }

  // ── Welcome ───────────────────────────────────────────────────────────────

  Widget _buildWelcome() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        // Greeting card
        _WelcomeCard().animate().fade(duration: 400.ms).slideY(begin: 0.08, end: 0),

        const SizedBox(height: 28),

        Text('Suggested questions',
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.textMuted, letterSpacing: 0.5))
            .animate()
            .fade(duration: 300.ms, delay: 200.ms),

        const SizedBox(height: 12),

        ..._suggestions.asMap().entries.map((e) {
          final (icon, text) = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SuggestionTile(
              icon: icon,
              text: text,
              onTap: () => _send(text),
            )
                .animate(delay: Duration(milliseconds: 280 + e.key * 65))
                .fade(duration: 260.ms)
                .slideY(begin: 0.06, end: 0),
          );
        }),
      ],
    );
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length && _sending) {
          return const _TypingRow();
        }
        final msg          = _messages[i];
        final prevSameRole = i > 0 && _messages[i - 1].role == msg.role;
        final nextSameRole = i < _messages.length - 1 &&
            _messages[i + 1].role == msg.role;
        return _BubbleRow(
          message:       msg,
          groupWithPrev: prevSameRole,
          groupWithNext: nextSameRole,
        )
            .animate(delay: 20.ms)
            .fade(duration: 160.ms)
            .slideY(begin: 0.04, end: 0);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final bool hasMessages;
  final VoidCallback onBack;
  final VoidCallback onClear;
  const _AppBar({
    required this.hasMessages,
    required this.onBack,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 4, right: 8, bottom: 0,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        children: [
          // Main row
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),

              // Avatar
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Career Guidance AI',
                        style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: Color(0xFF69F0AE),
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text('Active',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ],
                ),
              ),

              if (hasMessages)
                IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.refresh_rounded,
                      color: Colors.white.withOpacity(0.8), size: 22),
                  tooltip: 'New conversation',
                ),
            ],
          ),

          // Thin divider line at bottom
          Container(
            height: 1,
            margin: const EdgeInsets.only(top: 6),
            color: Colors.white.withOpacity(0.12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome card
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon block
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello! I\'m your AI guide.',
                    style: AppTextStyles.titleLarge
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Ask me anything about careers, NEB exams, study plans, or skills to build.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestion tile
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionTile extends StatelessWidget {
  final IconData icon;
  final String   text;
  final VoidCallback onTap;
  const _SuggestionTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.primary.withOpacity(0.06),
        highlightColor: AppColors.primary.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(text,
                    style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bubble row
// ─────────────────────────────────────────────────────────────────────────────

class _BubbleRow extends StatelessWidget {
  final AiChatMessage message;
  final bool groupWithPrev;
  final bool groupWithNext;

  const _BubbleRow({
    required this.message,
    this.groupWithPrev = false,
    this.groupWithNext = false,
  });

  static final _mdSheet = MarkdownStyleSheet(
    p: const TextStyle(
        fontSize: 14, height: 1.6, color: Color(0xFF052659)),
    strong: const TextStyle(
        fontSize: 14, height: 1.6, color: Color(0xFF052659),
        fontWeight: FontWeight.w700),
    em: const TextStyle(
        fontSize: 14, height: 1.6, color: Color(0xFF052659),
        fontStyle: FontStyle.italic),
    h1: const TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF052659)),
    h2: const TextStyle(
        fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF052659)),
    h3: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF052659)),
    listBullet: const TextStyle(
        fontSize: 14, height: 1.6, color: Color(0xFF052659)),
    code: TextStyle(
        fontSize: 12,
        color: AppColors.primary,
        backgroundColor: AppColors.primary.withOpacity(0.07),
        fontFamily: 'monospace'),
    codeblockDecoration: BoxDecoration(
      color: Color(0xFFF0F4FF),
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    blockquote: const TextStyle(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: Color(0xFF8CA8C8)),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: Color(0xFF5483B3), width: 3)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final topGap    = groupWithPrev ? 2.0 : 12.0;
    final bottomGap = groupWithNext ? 2.0 : 4.0;

    // Corner radii — grouped messages share a flat edge
    const r = Radius.circular(18);
    const s = Radius.circular(4);

    final userRadius = BorderRadius.only(
      topLeft:     r,
      topRight:    groupWithPrev ? r : r,
      bottomLeft:  r,
      bottomRight: groupWithNext ? r : s,
    );
    final assistRadius = BorderRadius.only(
      topLeft:     groupWithPrev ? r : r,
      topRight:    r,
      bottomLeft:  groupWithNext ? r : s,
      bottomRight: r,
    );

    return Padding(
      padding: EdgeInsets.only(top: topGap, bottom: bottomGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Assistant avatar
          if (!isUser) ...[
            if (!groupWithNext)
              _AssistAvatar()
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: isUser ? userRadius : assistRadius,
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppColors.primary.withOpacity(0.18)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white, height: 1.6),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: _mdSheet,
                      shrinkWrap: true,
                    ),
            ),
          ),

          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            if (!groupWithNext)
              _UserAvatar()
            else
              const SizedBox(width: 26),
          ],
        ],
      ),
    );
  }
}

class _AssistAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: AppColors.secondary.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: 16),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_rounded,
          size: 15, color: AppColors.primary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typing indicator
// ─────────────────────────────────────────────────────────────────────────────

class _TypingRow extends StatelessWidget {
  const _TypingRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AssistAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(18),
                topRight:    Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft:  Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  3, (i) => _Dot(delay: Duration(milliseconds: i * 160))),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Duration delay;
  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7, height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.45),
          shape: BoxShape.circle),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true), delay: delay)
        .scaleXY(
            begin: 0.45, end: 1.0,
            duration: 380.ms,
            curve: Curves.easeInOut)
        .fadeIn(duration: 380.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final bool sending;
  final void Function([String?]) onSend;

  const _InputBar({
    required this.ctrl,
    required this.focus,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFECF0F7))),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F5FA),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDDE8F5)),
              ),
              child: TextField(
                controller: ctrl,
                focusNode: focus,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                maxLines: 5,
                minLines: 1,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: sending ? null : AppColors.primaryGradient,
              color: sending ? AppColors.primary.withOpacity(0.25) : null,
              shape: BoxShape.circle,
              boxShadow: sending
                  ? []
                  : [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: sending ? null : () => onSend(),
                customBorder: const CircleBorder(),
                child: Center(
                  child: sending
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_upward_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
