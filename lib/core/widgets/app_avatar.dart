import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// A small circular avatar showing initials on an Ink background —
/// used for creator attribution wherever a real profile photo isn't
/// available yet.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.initials, this.size = 24});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
      child: Text(
        initials,
        style: AppTextStyles.body(size * 0.42, weight: FontWeight.w700, color: AppColors.paper),
      ),
    );
  }
}
