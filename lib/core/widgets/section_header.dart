import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onActionTap, this.number});

  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  /// Optional index shown as "01 —" before the title, e.g. for a
  /// numbered sequence of home-screen sections.
  final int? number;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (number != null) ...[
              Text(number!.toString().padLeft(2, '0'), style: AppTextStyles.label(13, color: AppColors.slate)),
              const SizedBox(width: 8),
              Container(width: 1, height: 14, color: AppColors.mist),
              const SizedBox(width: 8),
            ],
            Text(title, style: AppTextStyles.h3),
          ],
        ),
        if (action != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(action!.toUpperCase(), style: AppTextStyles.label(13, weight: FontWeight.w700, color: AppColors.ink)),
          ),
      ],
    );
  }
}
