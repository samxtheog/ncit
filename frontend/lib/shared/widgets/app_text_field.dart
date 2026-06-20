import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final int maxLines;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            enabled: widget.enabled,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            onChanged: widget.onChanged,
            validator: widget.validator,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: widget.prefixIcon,
                    )
                  : null,
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 20, minHeight: 20),
              suffixIcon: widget.isPassword
                  ? GestureDetector(
                      onTap: () =>
                          setState(() => _obscureText = !_obscureText),
                      child: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _isFocused
                            ? AppColors.secondary
                            : AppColors.textMuted,
                        size: 20,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
