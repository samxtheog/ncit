import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

class CareerCard extends StatelessWidget {
  final String title;
  final int matchPercent;
  final String description;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onViewRoadmap;

  const CareerCard({
    super.key,
    required this.title,
    required this.matchPercent,
    required this.description,
    this.color,
    this.icon,
    this.onViewRoadmap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.primary;
    final matchColor = matchPercent >= 90
        ? const Color(0xFF4CAF50)
        : matchPercent >= 80
            ? const Color(0xFF2196F3)
            : AppColors.secondary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Coloured header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardColor, cardColor.withOpacity(0.75)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon badge
                if (icon != null) ...[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                ],

                // Text — takes remaining space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Circular progress — radius=28 → diameter=56px, fits inside 64px box
                CircularPercentIndicator(
                  radius: 28.0,
                  lineWidth: 4.5,
                  percent: matchPercent / 100,
                  center: Text(
                    '$matchPercent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  progressColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ],
            ),
          ),

          // ── Match label + button ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Match pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: matchColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: matchColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$matchPercent% Match',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: matchColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Button — only render if callback provided
                if (onViewRoadmap != null)
                  SizedBox(
                    height: 36,
                    child: TextButton(
                      onPressed: onViewRoadmap,
                      style: TextButton.styleFrom(
                        backgroundColor: cardColor.withOpacity(0.1),
                        foregroundColor: cardColor,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Roadmap',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: cardColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              color: cardColor, size: 14),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
