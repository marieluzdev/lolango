import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';

enum AppButtonType { primary, secondary, outline, text }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final Widget? prefixWidget;
  final bool isLoading;
  final bool isFullWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.prefixWidget,
    this.isLoading = false,
    this.isFullWidth = false,
    this.borderRadius = 26.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isProcessing = false;

  void _handlePress() async {
    if (widget.isLoading || _isProcessing || widget.onPressed == null) return;

    // Protection double clic minimal
    setState(() => _isProcessing = true);
    widget.onPressed!();

    // Le Future.delayed permet d'éviter un autre tap immédiatement (debounce visuel)
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final secondaryColor = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.type) {
      case AppButtonType.primary:
        backgroundColor = primaryColor;
        textColor = Colors.white;
        break;
      case AppButtonType.secondary:
        backgroundColor = secondaryColor;
        textColor = Colors.white;
        break;
      case AppButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = textPrimary;
        borderSide = BorderSide(color: borderColor);
        break;
      case AppButtonType.text:
        backgroundColor = Colors.transparent;
        textColor = primaryColor;
        break;
    }

    // Disable state overrides
    if (widget.onPressed == null) {
      backgroundColor = surfaceColor;
      textColor = textPrimary.withValues(alpha: 0.5);
      borderSide = widget.type == AppButtonType.outline
          ? BorderSide(color: borderColor.withValues(alpha: 0.5))
          : BorderSide.none;
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      side: borderSide,
    );

    Widget content = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.prefixWidget != null) ...[
                widget.prefixWidget!,
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );

    if (widget.isFullWidth) {
      content = Center(child: content);
    }

    switch (widget.type) {
      case AppButtonType.primary:
      case AppButtonType.secondary:
        return ElevatedButton(
          onPressed: widget.onPressed == null ? null : _handlePress,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            padding: widget.padding,
            shape: shape,
            elevation: 0,
          ),
          child: content,
        );
      case AppButtonType.outline:
        return OutlinedButton(
          onPressed: widget.onPressed == null ? null : _handlePress,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor,
            padding: widget.padding,
            shape: shape,
          ),
          child: content,
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: widget.onPressed == null ? null : _handlePress,
          style: TextButton.styleFrom(
            foregroundColor: textColor,
            padding: widget.padding,
            shape: shape,
          ),
          child: content,
        );
    }
  }
}
