import 'package:flutter/material.dart';
import '../../core/app_images.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_logo.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'sign_up_screen.dart';
import 'log_in_screen.dart';

/// The first screen after onboarding — the in-app equivalent of the
/// landing page's hero. Same headline, same tagline, same brand.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            children: [
              const Align(alignment: Alignment.centerLeft, child: AppLogo(size: 30)),
              const Spacer(),
              AppImage(
                AppImages.authArt,
                width: 260,
                height: 260,
                fallbackIcon: Icons.trending_up_rounded,
                backgroundColor: AppColors.mist.withOpacity(0.5),
                borderRadius: BorderRadius.circular(28),
              ),
              const SizedBox(height: 36),
              Text('Turn any take\ninto a market.', style: AppTextStyles.h1, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Text(
                'Non-custodial prediction markets on Solana, powered by Panta.',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                label: 'Create an account',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'I already have an account',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LogInScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
