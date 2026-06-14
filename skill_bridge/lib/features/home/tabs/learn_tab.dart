import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/quiz_service.dart';
import '../../learn/pdf_viewer_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────

class LearnTab extends StatefulWidget {
  const LearnTab({super.key});
  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  final _service = PdfService();

  List<PdfDoc> _pdfs     = [];
  bool  _loadingList     = true;
  bool  _uploading       = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _loadPdfs();
  }

  // ── Fetch list ────────────────────────────────────────────────────────────

  Future<void> _loadPdfs() async {
    setState(() => _loadingList = true);
    try {
      final list = await _service.listPdfs();
      if (!mounted) return;
      setState(() { _pdfs = list; _loadingList = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  // ── Pick & upload ─────────────────────────────────────────────────────────

  Future<void> _pickAndUpload() async {
    setState(() { _uploading = true; _uploadError = null; });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,               // required for web + in-memory upload
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _uploading = false);
        return;
      }

      final file  = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() { _uploading = false; _uploadError = 'Could not read file.'; });
        return;
      }

      // Enforce 5 MB client-side limit to avoid nginx 413
      const maxBytes = 5 * 1024 * 1024;
      if (bytes.lengthInBytes > maxBytes) {
        setState(() {
          _uploading = false;
          _uploadError = 'File too large. Please upload a PDF under 5 MB.';
        });
        return;
      }

      final uploaded = await _service.uploadPdf(
        bytes:    bytes,
        filename: file.name,
      );

      // Deduct 2 XP for uploading a PDF
      await QuizService.addXP(-2);

      if (!mounted) return;
      setState(() {
        _pdfs.insert(0, uploaded.pdf);
        _uploading = false;
      });

      // Show XP cost snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFFFFE082), size: 18),
                SizedBox(width: 8),
                Text('-2 XP used to upload PDF'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Navigate into viewer — list reloads automatically on return
      _openPdf(uploaded.pdf, fullText: uploaded.text, messages: []);
    } catch (e) {
      if (mounted) {
        setState(() { _uploading = false; _uploadError = e.toString(); });
      }
    }
  }

  // ── Open existing PDF ─────────────────────────────────────────────────────

  Future<void> _openExisting(PdfDoc pdf) async {
    try {
      final detail = await _service.getPdf(pdf.id);
      if (!mounted) return;
      _openPdf(detail.pdf, fullText: detail.text, messages: detail.messages);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _openPdf(PdfDoc pdf,
      {required String fullText,
      required List<ChatMessage> messages}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PdfViewerScreen(
        pdf:             pdf,
        initialText:     fullText,
        initialMessages: messages,
      ),
    )).then((_) => _loadPdfs());
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _delete(int idx) async {
    final pdf = _pdfs[idx];
    setState(() => _pdfs.removeAt(idx));
    try {
      await _service.deletePdf(pdf.id);
    } catch (_) {
      if (mounted) setState(() => _pdfs.insert(idx, pdf));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadPdfs,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppConstants.horizontalPadding,
                right: AppConstants.horizontalPadding,
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          color: AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Text('My Learning',
                          style: AppTextStyles.headlineLarge),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Upload PDFs, read them, and chat with AI',
                      style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 20),

                  // ── Upload banner ──────────────────────────────────────
                  _UploadBanner(
                    uploading: _uploading,
                    onUpload:  _pickAndUpload,
                  ),

                  if (_uploadError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFE53935), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_uploadError!,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: const Color(0xFFE53935))),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Section title ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent PDFs',
                          style: AppTextStyles.headlineSmall),
                      if (_loadingList)
                        const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ── PDF list ─────────────────────────────────────────────────────
          if (!_loadingList && _pdfs.isEmpty)
            SliverToBoxAdapter(child: _EmptyState(onUpload: _pickAndUpload))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PdfCard(
                      pdf:      _pdfs[i],
                      onTap:    () => _openExisting(_pdfs[i]),
                      onDelete: () => _delete(i),
                    ),
                  )
                      .animate(delay: Duration(milliseconds: i * 60))
                      .fade(duration: 350.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                  childCount: _pdfs.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  Upload banner                                                              ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

class _UploadBanner extends StatelessWidget {
  final bool uploading;
  final VoidCallback onUpload;
  const _UploadBanner({required this.uploading, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Study Assistant',
                    style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Upload any PDF → Read it → Chat with AI about its content',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white.withOpacity(0.85)),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: uploading ? null : onUpload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: uploading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.upload_file_rounded,
                                  color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              Text('Upload PDF',
                                  style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 36),
          ),
        ],
      ),
    )
        .animate()
        .fade(duration: 500.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  PDF card                                                                   ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

class _PdfCard extends StatelessWidget {
  final PdfDoc pdf;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _PdfCard(
      {required this.pdf, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            // PDF icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  color: Color(0xFFE53935), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pdf.originalName.replaceAll('.pdf', ''),
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Meta(Icons.auto_stories_rounded,
                          '${pdf.pages} pages'),
                      const SizedBox(width: 10),
                      _Meta(Icons.data_usage_rounded, pdf.sizeLabel),
                      if (pdf.messageCount > 0) ...[
                        const SizedBox(width: 10),
                        _Meta(Icons.chat_bubble_outline_rounded,
                            '${pdf.messageCount} msgs'),
                      ],
                    ],
                  ),
                  if (pdf.preview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      pdf.preview,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.open_in_new_rounded,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Open',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFE53935), size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 12, color: AppColors.textMuted),
      const SizedBox(width: 3),
      Text(label,
          style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.textMuted)),
    ],
  );
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  Empty state                                                                ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

class _EmptyState extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyState({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text('No PDFs yet',
              style: AppTextStyles.headlineSmall
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Upload your first PDF to read it and chat with AI about its content.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
