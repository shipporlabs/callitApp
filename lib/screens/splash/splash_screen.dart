import 'package:flutter/material.dart';
import '../../core/api/callit_api.dart';
import '../../core/api/token_store.dart';
import '../../core/widgets/app_logo.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/home_screen.dart';
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
    Future.delayed(const Duration(milliseconds: 1100), () async {
      if (!mounted) return;
      // TokenStore is already loaded (see main.dart) — a returning,
      // signed-in user skips onboarding entirely.
      final loggedIn = TokenStore.instance.isAuthenticated;
      // FossaPay's wallet is provisioned server-side at sign-up; this
      // just covers a session that was signed in before the wallet
      // existed locally (e.g. restored on a fresh install).
      if (loggedIn && !TokenStore.instance.hasWallet) {
        try {
          final address = await callitApi.fetchWalletAddress();
          if (address != null) {
            await TokenStore.instance.saveWallet(address: address, provider: 'FossaPay');
          }
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => loggedIn ? const HomeScreen() : const OnboardingScreen()),
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
