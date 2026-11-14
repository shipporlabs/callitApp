import 'package:flutter/material.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/brand_background.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../auth/welcome_screen.dart';
import 'onboarding_art.dart';

class _Step {
  const _Step(this.title, this.body);
  final String title;
  final String body;
}

// Two-line headings, short bodies.
const _steps = [
  _Step('Paste any take.', 'A headline, a tweet or your own question. Drop it in and Callit reads it.'),
  _Step('We write the market.', 'The question, the end date and the resolution rule are drafted and checked before you spend anything.'),
  _Step('Back it. Earn from it.', 'Fund from NEAR, Base or Ethereum in one click, back a side, and earn fees on markets you create.'),
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
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const WelcomeScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _steps.length - 1;
    return Scaffold(
      body: BrandBackground(
        glow: 0.35,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 12, 0),
                child: Row(
                  children: [
                    const AppLogo(size: 30),
                    const SizedBox(width: 10),
                    Text('Callit', style: AppTextStyles.display(28, letterSpacing: -0.8)),
                    const Spacer(),
                    TextButton(onPressed: _finish, child: Text('Skip', style: AppTextStyles.body(15, weight: FontWeight.w500, color: AppColors.slate))),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OnboardingArt(key: ValueKey('art$i'), step: i),
                        const SizedBox(height: 32),
                        Text(_steps[i].title, style: AppTextStyles.h1),
                        const SizedBox(height: 12),
                        Text(_steps[i].body, style: AppTextStyles.subtitle),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(_steps.length, (i) {
                        final on = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.only(right: 6),
                          width: on ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(color: on ? AppColors.ink : AppColors.mist, borderRadius: BorderRadius.circular(999)),
                        );
                      }),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: AppButton(
                        label: isLast ? 'Get started' : 'Next',
                        onPressed: () {
                          if (isLast) {
                            _finish();
                          } else {
                            _controller.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
