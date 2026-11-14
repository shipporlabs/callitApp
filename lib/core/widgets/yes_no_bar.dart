import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// The split YES/NO probability bar used on every market card and the
/// market detail screen. `yesPct` is 0–100. The fill animates in once.
class YesNoBar extends StatelessWidget {
  const YesNoBar({super.key, required this.yesPct, this.height = 10, this.showLabels = true});

  final double yesPct;
  final double height;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final yes = yesPct.clamp(0, 100).toDouble();
    final no = 100 - yes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: yes),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Row(
                children: [
                  Expanded(flex: (v * 10).round().clamp(1, 1000), child: const ColoredBox(color: AppColors.yes)),
                  const SizedBox(width: 3),
                  Expanded(flex: ((100 - v) * 10).round().clamp(1, 1000), child: ColoredBox(color: AppColors.no.withOpacity(0.85))),
                ],
              ),
            ),
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('YES ${yes.toStringAsFixed(0)}%', style: AppTextStyles.tabularNums(13, color: AppColors.yes)),
              Text('NO ${no.toStringAsFixed(0)}%', style: AppTextStyles.tabularNums(13, color: AppColors.no)),
            ],
          ),
        ],
      ],
    );
  }
}
