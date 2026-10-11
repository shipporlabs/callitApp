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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.ink, width: 1.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PillChip(label: market.category, dense: true),
                  if (market.isGraduated)
                    const PillChip(
                      label: 'GRADUATED',
                      dense: true,
                      background: AppColors.highlight,
                      foreground: AppColors.ink,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                market.question,
                style: AppTextStyles.display(16.5, weight: FontWeight.w600, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              YesNoBar(yesPct: market.yesPricePct),
              if (market.creatorHandle.isNotEmpty || market.volumeLabel != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (market.creatorHandle.isNotEmpty) ...[
                      AppAvatar(initials: market.creatorInitials, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          market.creatorHandle,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (market.volumeLabel != null)
                      Text(market.volumeLabel!, style: AppTextStyles.caption),
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
