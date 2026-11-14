import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/api/callit_api.dart';
import '../../core/api/token_store.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/brand_background.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// Brand moment: the mark spins in, the wordmark and tagline rise, then we
/// fade into the app. Same background as the website hero.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final started = DateTime.now();
    // TokenStore is already loaded (see main.dart): a signed-in user skips onboarding.
    final loggedIn = TokenStore.instance.isAuthenticated;
    if (loggedIn && !TokenStore.instance.hasWallet) {
      try {
        final address = await callitApi.fetchWalletAddress();
        if (address != null) {
          await TokenStore.instance.saveWallet(address: address, provider: 'FossaPay');
        }
      } catch (_) {}
    }
    // Give the animation time to finish, but never longer than needed.
    final left = const Duration(milliseconds: 2300) - DateTime.now().difference(started);
    if (left > Duration.zero) await Future.delayed(left);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => loggedIn ? const HomeScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Interval _i(double a, double b) => Interval(a, b, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        glow: 0.55,
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final markT = Curves.easeOutBack.transform(_i(0.0, 0.55).transform(_c.value));
              final wordT = _i(0.35, 0.75).transform(_c.value);
              final tagT = _i(0.55, 0.95).transform(_c.value);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: (1 - markT) * -math.pi,
                    child: Transform.scale(scale: 0.4 + 0.6 * markT, child: Opacity(opacity: markT.clamp(0, 1), child: const AppLogo(size: 92))),
                  ),
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: wordT,
                    child: Transform.translate(
                      offset: Offset(0, (1 - wordT) * 18),
                      child: Text('Callit', style: AppTextStyles.display(64, letterSpacing: -2)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: tagT,
                    child: Transform.translate(
                      offset: Offset(0, (1 - tagT) * 12),
                      child: Text('Back what you believe.', style: AppTextStyles.body(16, color: AppColors.slate)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
