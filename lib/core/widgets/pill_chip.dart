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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 11 : 14, vertical: dense ? 5 : 8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.label(dense ? 10.5 : 12, color: foreground),
      ),
    );
  }
}
