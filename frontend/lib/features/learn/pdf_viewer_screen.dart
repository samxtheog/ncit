import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/pdf_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final PdfDoc pdf;
  final String initialText;
  final List<ChatMessage> initialMessages;

  const PdfViewerScreen({
    super.key,
    required this.pdf,
    required this.initialText,
    required this.initialMessages,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

enum _Mode { read, chat }

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _service    = PdfService();
  final _chatCtrl   = TextEditingController();
  final _chatScroll = ScrollController();
  final _tts        = FlutterTts();

  late List<ChatMessage> _messages;
  bool _sending     = false;
  bool _reading     = false;  // TTS active?
  bool _ttsReady    = false;
  double _speed     = 0.45;   // current TTS speed

  // Paragraphs split from raw text
  late final List<String> _paragraphs;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _messages = List.from(widget.initialMessages);
    _paragraphs = _splitParagraphs(widget.initialText);
    _initTts();
  }

  List<String> _splitParagraphs(String text) {
    return text
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.length > 20)
        .toList();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _reading = false);
    });
    _tts.setErrorHandler((msg) {
      if (mounted) setState(() => _reading = false);
    });
    setState(() => _ttsReady = true);
  }

  Future<void> _toggleRead() async {
    if (_reading) {
      await _tts.stop();
      setState(() => _reading = false);
    } else {
      final fullText = _paragraphs.join('\n\n');
      if (fullText.isEmpty) return;
      setState(() => _reading = true);
      await _tts.setSpeechRate(_speed);
      await _tts.speak(fullText);
    }
  }

  Future<void> _onSpeedChanged(double speed) async {
    setState(() => _speed = speed);
    await _tts.setSpeechRate(speed);
    // If already reading, restart with new speed
    if (_reading) {
      await _tts.stop();
      final fullText = _paragraphs.join('\n\n');
      await _tts.speak(fullText);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _tabCtrl.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final txt = _chatCtrl.text.trim();
    if (txt.isEmpty || _sending) return;
    _chatCtrl.clear();
    setState(() {
      _messages.add(ChatMessage.local('user', txt));
      _sending = true;
    });
    _scrollToBottom();
    try {
      final reply = await _service.chat(widget.pdf.id, txt);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage.local('assistant', reply));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage.local('assistant', 'Error: ${e.toString()}'));
        _sending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pdf.originalName.replaceAll('.pdf', ''),
              style: AppTextStyles.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.pdf.pages} pages · ${widget.pdf.sizeLabel}',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle:
              AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTextStyles.labelLarge,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Read'),
            Tab(icon: Icon(Icons.smart_toy_rounded,  size: 18), text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ReadTab(
            paragraphs: _paragraphs,
            reading:    _reading,
            ttsReady:   _ttsReady,
            onToggleRead:   _toggleRead,
            onSpeedChanged: _onSpeedChanged,
            speed:      _speed,
            pdfName:    widget.pdf.originalName,
          ),
          _ChatTab(
            messages:   _messages,
            sending:    _sending,
            ctrl:       _chatCtrl,
            scrollCtrl: _chatScroll,
            onSend:     _send,
            pdfName:    widget.pdf.originalName,
          ),
        ],
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  Read tab                                                                   ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

class _ReadTab extends StatefulWidget {
  final List<String> paragraphs;
  final bool reading;
  final bool ttsReady;
  final VoidCallback onToggleRead;
  final ValueChanged<double> onSpeedChanged;
  final double speed;
  final String pdfName;

  const _ReadTab({
    required this.paragraphs,
    required this.reading,
    required this.ttsReady,
    required this.onToggleRead,
    required this.onSpeedChanged,
    required this.speed,
    required this.pdfName,
  });

  @override
  State<_ReadTab> createState() => _ReadTabState();
}

class _ReadTabState extends State<_ReadTab> {
  static const _speeds = [
    (label: '0.5×', value: 0.25),
    (label: '1×',   value: 0.45),
    (label: '1.5×', value: 0.65),
    (label: '2×',   value: 0.9),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.paragraphs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_not_supported_rounded,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('No extractable text found',
                  style: AppTextStyles.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'This PDF may be scanned or image-based. You can still use Chat mode to ask general questions.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ── Toolbar ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: Color(0xFFEEF4FB))),
          ),
          child: Row(
            children: [
              const Icon(Icons.article_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text('${widget.paragraphs.length} paragraphs',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textMuted)),
              const Spacer(),

              // ── Speed chips ────────────────────────────────────────────
              if (widget.ttsReady) ...[
                ...List.generate(_speeds.length, (i) {
                  final s = _speeds[i];
                  final selected = (widget.speed - s.value).abs() < 0.01;
                  return GestureDetector(
                    onTap: () => widget.onSpeedChanged(s.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: selected ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 6),

                // ── Play/Stop button ───────────────────────────────────
                GestureDetector(
                  onTap: widget.onToggleRead,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.reading
                          ? const Color(0xFFE53935)
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.reading
                              ? Icons.stop_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white, size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.reading ? 'Stop' : 'Read',
                          style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Paragraphs ────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: widget.paragraphs.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('¶ ${i + 1}',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.paragraphs[i],
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.75),
                    ),
                  ],
                ),
              )
                  .animate(delay: Duration(milliseconds: i * 30))
                  .fade(duration: 250.ms),
            ),
          ),
        ),
      ],
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  Chat tab                                                                   ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

class _ChatTab extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool sending;
  final TextEditingController ctrl;
  final ScrollController scrollCtrl;
  final VoidCallback onSend;
  final String pdfName;

  const _ChatTab({
    required this.messages,
    required this.sending,
    required this.ctrl,
    required this.scrollCtrl,
    required this.onSend,
    required this.pdfName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Hint banner ───────────────────────────────────────────────────
        if (messages.isEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ask anything about this PDF',
                          style: AppTextStyles.titleMedium
                              .copyWith(color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        'The AI has read "$pdfName" and will answer only from its content.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),

        // ── Messages ──────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: messages.length + (sending ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == messages.length && sending) {
                return _TypingBubble();
              }
              final msg = messages[i];
              return _ChatBubble(message: msg)
                  .animate(delay: 50.ms)
                  .fade(duration: 250.ms)
                  .slideY(begin: 0.05, end: 0);
            },
          ),
        ),

        // ── Input ─────────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: Color(0xFFEEF4FB))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  onSubmitted: (_) => onSend(),
                  textInputAction: TextInputAction.send,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Ask about this PDF...',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: Color(0xFFDDE8F5))),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: sending ? null : onSend,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: sending
                        ? AppColors.primary.withOpacity(0.5)
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: sending
                      ? const Center(
                          child: SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4  : 18),
          ),
          boxShadow: isUser ? [] : AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy_rounded,
                        size: 13, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text('AI',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            Text(
              message.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: isUser ? Colors.white : AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(18),
            topRight:    Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft:  Radius.circular(4),
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => _Dot(delay: Duration(milliseconds: i * 180)),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Duration delay;
  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) => Container(
    width: 7, height: 7,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: const BoxDecoration(
        color: AppColors.textMuted, shape: BoxShape.circle),
  )
      .animate(onPlay: (c) => c.repeat(reverse: true), delay: delay)
      .scaleXY(begin: 0.5, end: 1.0, duration: 400.ms, curve: Curves.easeInOut)
      .fadeIn(duration: 400.ms);
}
