import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

/// One button widget for the whole app, so every CTA looks and behaves
/// the same way. `variant` controls color; `loading` swaps the label for
/// a small spinner without changing the button's size.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final BoxBorder? border;

    switch (variant) {
      case AppButtonVariant.primary:
        background = AppColors.highlight;
        foreground = AppColors.ink;
        border = Border.all(color: AppColors.ink, width: 1.4);
        break;
      case AppButtonVariant.secondary:
        background = AppColors.ink;
        foreground = AppColors.paper;
        border = Border.all(color: AppColors.ink, width: 1.4);
        break;
      case AppButtonVariant.outline:
        background = Colors.transparent;
        foreground = AppColors.ink;
        border = Border.all(color: AppColors.ink, width: 1.4);
        break;
      case AppButtonVariant.danger:
        background = AppColors.no;
        foreground = AppColors.white;
        border = Border.all(color: AppColors.ink, width: 1.4);
        break;
    }

    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTextStyles.button.copyWith(color: foreground)),
            ],
          );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: onPressed == null ? background.withOpacity(0.5) : background,
          borderRadius: BorderRadius.circular(4),
          border: border,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: loading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
