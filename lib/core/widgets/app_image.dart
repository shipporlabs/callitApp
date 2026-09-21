import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Renders a local asset if it exists, otherwise falls back to a clean
/// drawn placeholder (an icon on a soft Mist tile) instead of crashing or
/// showing Flutter's red error box.
///
/// Usage: `AppImage(AppImages.onboarding1, fallbackIcon: Icons.auto_awesome)`
class AppImage extends StatelessWidget {
  const AppImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallbackIcon = Icons.image_outlined,
    this.borderRadius,
    this.backgroundColor,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.mist.withOpacity(0.6),
              borderRadius: radius,
            ),
            alignment: Alignment.center,
            child: Icon(
              fallbackIcon,
              size: (width ?? height ?? 80) * 0.32,
              color: AppColors.slate,
            ),
          );
        },
      ),
    );
  }
}
