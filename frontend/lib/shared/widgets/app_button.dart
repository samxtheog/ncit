import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, gradient }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.isDisabled && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    switch (widget.variant) {
      case AppButtonVariant.gradient:
        return _buildGradientButton();
      case AppButtonVariant.outline:
        return _buildOutlineButton();
      case AppButtonVariant.ghost:
        return _buildGhostButton();
      case AppButtonVariant.secondary:
        return _buildSecondaryButton();
      case AppButtonVariant.primary:
        return _buildPrimaryButton();
    }
  }

  Widget _buildPrimaryButton() {
    final isEnabled = !widget.isDisabled && !widget.isLoading;
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.primary : AppColors.textMuted,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: isEnabled ? AppColors.buttonShadow : [],
      ),
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
      child: _buildContent(AppColors.textOnPrimary),
    );
  }

  Widget _buildGradientButton() {
    final isEnabled = !widget.isDisabled && !widget.isLoading;
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        gradient:
            isEnabled ? AppColors.primaryGradient : null,
        color: isEnabled ? null : AppColors.textMuted,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: isEnabled ? AppColors.buttonShadow : [],
      ),
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
      child: _buildContent(AppColors.textOnPrimary),
    );
  }

  Widget _buildSecondaryButton() {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.lightAccent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
      child: _buildContent(AppColors.primary),
    );
  }

  Widget _buildOutlineButton() {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
      child: _buildContent(AppColors.primary),
    );
  }

  Widget _buildGhostButton() {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
      child: _buildContent(AppColors.secondary),
    );
  }

  Widget _buildContent(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: 10),
          ],
          Text(
            widget.label,
            style: AppTextStyles.buttonText.copyWith(color: textColor),
          ),
        ],
      ],
    );
  }
}
