import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SelectionCard extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? description;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accentColor;
  final bool compact;
  /// Optional short label shown inside the icon badge (e.g. grade number "10")
  final String? badgeLabel;

  const SelectionCard({
    super.key,
    required this.label,
    this.icon,
    this.description,
    required this.isSelected,
    required this.onTap,
    this.accentColor,
    this.compact = false,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(compact ? 14 : 18),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFDDE8F5),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppColors.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null || badgeLabel != null) ...[
                  _buildIconBadge(color),
                  SizedBox(width: compact ? 10 : 12),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.titleMedium.copyWith(
                      color:
                          isSelected ? color : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? color.withOpacity(0.8)
                      : AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconBadge(Color color) {
    final size = compact ? 32.0 : 40.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Center(
        child: badgeLabel != null
            ? Text(
                badgeLabel!,
                style: TextStyle(
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              )
            : Icon(
                icon,
                size: compact ? 16 : 20,
                color: isSelected ? color : AppColors.textSecondary,
              ),
      ),
    );
  }
}
