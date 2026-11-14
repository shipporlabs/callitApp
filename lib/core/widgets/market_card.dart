import 'package:flutter/material.dart';
import '../../models/market.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_avatar.dart';
import 'pill_chip.dart';
import 'yes_no_bar.dart';

class MarketCard extends StatelessWidget {
  const MarketCard({super.key, required this.market, this.onTap});

  final Market market;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.mist, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PillChip(label: market.category, dense: true),
                  if (market.isGraduated)
                    const PillChip(label: 'Graduated', dense: true, background: AppColors.tint2, foreground: AppColors.ink),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                market.question,
                style: AppTextStyles.body(18, weight: FontWeight.w500, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),
              YesNoBar(yesPct: market.yesPricePct),
              if (market.creatorHandle.isNotEmpty || market.volumeLabel != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (market.creatorHandle.isNotEmpty) ...[
                      AppAvatar(initials: market.creatorInitials, size: 24),
                      const SizedBox(width: 8),
                      Expanded(child: Text(market.creatorHandle, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
                    ] else
                      const Spacer(),
                    if (market.volumeLabel != null) Text(market.volumeLabel!, style: AppTextStyles.caption),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
