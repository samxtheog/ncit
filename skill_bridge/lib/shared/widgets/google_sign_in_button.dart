import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// A "Continue with Google" button that matches the app style.
/// Handles its own loading state internally.
class GoogleSignInButton extends StatefulWidget {
  final Future<void> Function() onPressed;

  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _loading = false;

  Future<void> _handle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _loading ? null : _handle,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          side: BorderSide(
              color: AppColors.primary.withOpacity(0.2), width: 1.5),
          backgroundColor: Colors.white,
        ),
        child: _loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo — SVG-free, painted with CustomPaint
                  const _GoogleLogo(size: 20),
                  const SizedBox(width: 10),
                  Text('Continue with Google',
                      style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

// ── Minimal Google "G" icon drawn with Canvas ─────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GPainter(),
    );
  }
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // Draw four colored arcs to approximate the Google G
    final colors = [
      const Color(0xFF4285F4), // blue   — top-right
      const Color(0xFF34A853), // green  — bottom-right
      const Color(0xFFFBBC05), // yellow — bottom-left
      const Color(0xFFEA4335), // red    — top-left
    ];

    final paint = Paint()
      ..style    = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap   = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.75),
        -3.14 / 2 + i * 3.14 / 2,      // start angle
        3.14 / 2 - 0.15,                 // sweep — small gap between arcs
        false,
        paint,
      );
    }

    // Horizontal bar of the G
    final barPaint = Paint()
      ..color       = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.18
      ..strokeCap   = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.72, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(_GPainter old) => false;
}
