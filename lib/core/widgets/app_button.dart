import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_icon.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

/// One pill button for the whole app, matching the website:
///  - primary: ink, with a yellow arrow disc that nudges right on press,
///  - secondary: yellow,
///  - outline: white with a soft border,
///  - danger: red.
/// No shadows. Pressing scales it to 98%.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.expand = true,
    this.arrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool expand;

  /// Show the trailing arrow disc (primary and secondary only).
  final bool arrow;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final Color bg, fg;
    BorderSide side = BorderSide.none;
    Color disc = AppColors.yellowOrInk(widget.variant);
    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = AppColors.ink;
        fg = AppColors.paper;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.highlight;
        fg = AppColors.ink;
        break;
      case AppButtonVariant.outline:
        bg = AppColors.white;
        fg = AppColors.ink;
        side = const BorderSide(color: AppColors.mist, width: 1.2);
        break;
      case AppButtonVariant.danger:
        bg = AppColors.no;
        fg = AppColors.white;
        break;
    }
    final showArrow = widget.arrow && (widget.variant == AppButtonVariant.primary || widget.variant == AppButtonVariant.secondary) && widget.icon == null;
    final enabled = widget.onPressed != null && !widget.loading;

    final label = widget.loading
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: fg), const SizedBox(width: 8)],
              Flexible(child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.button.copyWith(color: fg))),
            ],
          );

    return AnimatedScale(
      scale: _down && enabled ? 0.98 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Opacity(
        opacity: widget.onPressed == null ? 0.5 : 1,
        child: SizedBox(
          width: widget.expand ? double.infinity : null,
          height: 56,
          child: Material(
            color: bg,
            shape: StadiumBorder(side: side),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: enabled ? widget.onPressed : null,
              onHighlightChanged: (v) => setState(() => _down = v),
              child: Padding(
                padding: EdgeInsets.fromLTRB(showArrow ? 26 : 24, 0, showArrow ? 8 : 24, 0),
                child: Row(
                  mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (widget.expand) const Spacer(),
                    label,
                    if (widget.expand) const Spacer(),
                    if (showArrow && !widget.loading) ...[
                      if (!widget.expand) const SizedBox(width: 14),
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        offset: Offset(_down ? 0.12 : 0, 0),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: disc, shape: BoxShape.circle),
                          child: Center(child: AppIcon(Ic.arrowRight, size: 20, color: widget.variant == AppButtonVariant.primary ? AppColors.ink : AppColors.highlight)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
