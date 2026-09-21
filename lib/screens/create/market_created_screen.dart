import 'package:flutter/material.dart';
import '../../core/app_images.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class MarketCreatedScreen extends StatelessWidget {
  const MarketCreatedScreen({super.key, required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              AppImage(
                AppImages.successCheck,
                width: 180,
                height: 180,
                fallbackIcon: Icons.celebration_outlined,
                backgroundColor: AppColors.highlight.withOpacity(0.35),
                borderRadius: BorderRadius.circular(90),
              ),
              const SizedBox(height: 32),
              Text('Your market is live', style: AppTextStyles.h1, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                question,
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Share it now to get the first trades in — you earn a share of the fees for as long as people trade it.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(label: 'Share market', icon: Icons.ios_share_rounded, onPressed: () {}),
              const SizedBox(height: 12),
              AppButton(
                label: 'View market',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
