import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? value;
  final Widget? trailing;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;
  final LinearGradient? gradient;

  const ProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.value,
    this.trailing,
    this.color,
    this.icon,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.secondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? cardColor : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (value != null) ...[
              const SizedBox(width: 8),
              Text(
                value!,
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
