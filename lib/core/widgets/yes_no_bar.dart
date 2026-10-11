import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// The split YES/NO probability bar used on every market card and the
/// market detail screen. `yesPct` is 0–100.
class YesNoBar extends StatelessWidget {
  const YesNoBar({super.key, required this.yesPct, this.height = 10, this.showLabels = true});

  final double yesPct;
  final double height;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final yes = yesPct.clamp(0, 100);
    final no = 100 - yes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.ink, width: 1.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: height,
              child: Row(
                children: [
                  Expanded(flex: (yes * 10).round().clamp(1, 1000).toInt(), child: Container(color: AppColors.yes)),
                  Expanded(flex: (no * 10).round().clamp(1, 1000).toInt(), child: Container(color: AppColors.no)),
                ],
              ),
            ),
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('YES ${yes.toStringAsFixed(0)}%', style: AppTextStyles.tabularNums(12, color: AppColors.yes)),
              Text('NO ${no.toStringAsFixed(0)}%', style: AppTextStyles.tabularNums(12, color: AppColors.no)),
            ],
          ),
        ],
      ],
    );
  }
}
