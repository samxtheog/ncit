import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.lightAccent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: 28),
              AppButton(
                label: buttonLabel!,
                onTap: onButtonTap,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
