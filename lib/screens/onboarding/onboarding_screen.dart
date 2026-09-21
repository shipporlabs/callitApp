import 'package:flutter/material.dart';
import '../../core/app_images.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../auth/welcome_screen.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.asset,
    required this.icon,
    required this.title,
    required this.body,
  });
  final String asset;
  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _OnboardingPage(
    asset: AppImages.onboarding1,
    icon: Icons.description_outlined,
    title: 'Paste any take',
    body: 'A headline, a tweet, or your own question — drop it in and Callit reads it.',
  ),
  _OnboardingPage(
    asset: AppImages.onboarding2,
    icon: Icons.auto_awesome_outlined,
    title: 'We compile the market',
    body: 'The question, the resolution rule and the sources are drafted and checked before you spend a cent.',
  ),
  _OnboardingPage(
    asset: AppImages.onboarding3,
    icon: Icons.swap_horiz_rounded,
    title: 'Trade and earn',
    body: 'Sign once, back a side in USDC, and earn a share of the fees on markets you create.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: TextButton(onPressed: _finish, child: const Text('Skip')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppImage(
                          page.asset,
                          width: 240,
                          height: 240,
                          fallbackIcon: page.icon,
                          backgroundColor: AppColors.mist.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        const SizedBox(height: 40),
                        Text(page.title, style: AppTextStyles.h1, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        Text(page.body, style: AppTextStyles.subtitle, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final selected = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: selected ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.ink : AppColors.mist,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: AppButton(
                label: isLast ? 'Get started' : 'Next',
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
