import 'package:flutter/material.dart';
import '../../core/widgets/app_logo.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 64, color: AppColors.paper),
            const SizedBox(height: 16),
            Text('Callit', style: AppTextStyles.display(28, color: AppColors.paper)),
            const SizedBox(height: 8),
            Text(
              'Turn any take into a market.',
              style: AppTextStyles.body(14, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
