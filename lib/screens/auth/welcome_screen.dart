import 'package:flutter/material.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/brand_background.dart';
import '../../core/widgets/yes_no_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'log_in_screen.dart';
import 'sign_up_screen.dart';

/// The in-app version of the website hero: two-line headline, a short line,
/// two buttons, and a market card peeking up from the bottom.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const AppLogo(size: 32),
                  const SizedBox(width: 10),
                  Text('Callit', style: AppTextStyles.display(30, letterSpacing: -0.8)),
                ]),
                const SizedBox(height: 40),
                Text('Back what you believe.', style: AppTextStyles.display(41, letterSpacing: -1, height: 1.05)),
                Text('Watch the truth form.', style: AppTextStyles.display(41, color: AppColors.slate, letterSpacing: -1, height: 1.05).copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                Text(
                  'Turn any take into a live market. Fund from NEAR, Base or Ethereum in one click.',
                  style: AppTextStyles.subtitle,
                ),
                const Spacer(),
                const _PeekCard(),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Create an account',
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpScreen())),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'I already have an account',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogInScreen())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeekCard extends StatelessWidget {
  const _PeekCard();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * 40), child: child)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.mist, width: 1.2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CRYPTO', style: AppTextStyles.label(11)),
            const SizedBox(height: 8),
            Text('Will SOL flip ETH by Dec 31?', style: AppTextStyles.body(18, weight: FontWeight.w500, height: 1.25)),
            const SizedBox(height: 14),
            const YesNoBar(yesPct: 62),
          ],
        ),
      ),
    );
  }
}
