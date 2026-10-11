import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.background = AppColors.mist,
    this.foreground = AppColors.ink,
    this.dense = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isInkOrMist = background == AppColors.mist || background == AppColors.ink;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 9 : 13, vertical: dense ? 4 : 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: isInkOrMist ? null : Border.all(color: AppColors.ink, width: 1.2),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.label(dense ? 10.5 : 12, weight: FontWeight.w700, color: foreground),
      ),
    );
  }
}
