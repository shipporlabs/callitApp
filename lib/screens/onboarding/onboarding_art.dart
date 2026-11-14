import 'package:flutter/material.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/widgets/yes_no_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Small drawn scenes for the three onboarding steps. They animate once when
/// they appear. No image files, so nothing can 404.
class OnboardingArt extends StatelessWidget {
  const OnboardingArt({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 330,
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.mist, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(right: -60, bottom: -80, child: Container(width: 240, height: 240, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.highlight.withOpacity(0.55), AppColors.highlight.withOpacity(0)])))),
          Center(child: [const _PasteScene(), const _CompileScene(), const _TradeScene()][step]),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.mist, width: 1.2)),
        child: child,
      );
}

/// 1: a take being typed into the box.
class _PasteScene extends StatelessWidget {
  const _PasteScene();
  static const text = 'SOL will flip ETH before the year ends';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(top: 2), child: AppIcon(Ic.sparkles, size: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: text.length),
                    duration: const Duration(milliseconds: 1900),
                    curve: Curves.easeOut,
                    builder: (_, n, __) => Text('${text.substring(0, n)}${n < text.length ? '▍' : ''}', style: AppTextStyles.body(17, weight: FontWeight.w500, height: 1.35)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip('Tweet'),
              const SizedBox(width: 8),
              _chip('Headline'),
              const SizedBox(width: 8),
              _chip('Your own question'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.mist)),
        child: Text(t, style: AppTextStyles.body(12.5, weight: FontWeight.w500)),
      );
}

/// 2: the compiled market appears with its rule.
class _CompileScene extends StatelessWidget {
  const _CompileScene();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * 30), child: child)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _Card(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('NEW · COMPILED', style: AppTextStyles.label(11)),
                const Spacer(),
                const AppIcon(Ic.check, size: 20, color: AppColors.yes),
              ]),
              const SizedBox(height: 10),
              Text('Will SOL flip ETH by Dec 31?', style: AppTextStyles.body(20, weight: FontWeight.w500, height: 1.25)),
              const SizedBox(height: 16),
              const YesNoBar(yesPct: 62),
              const SizedBox(height: 14),
              Row(children: [
                const AppIcon(Ic.news, size: 18, color: AppColors.slate),
                const SizedBox(width: 8),
                Expanded(child: Text('Resolves on Dec 31 from on-chain data', style: AppTextStyles.caption)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3: coins in, a YES position out.
class _TradeScene extends StatelessWidget {
  const _TradeScene();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _coin('NEAR', AppColors.ink, AppColors.paper, t, 0),
                _coin('ETH', AppColors.white, AppColors.ink, t, 1),
                _coin('BTC', AppColors.highlight, AppColors.ink, t, 2),
                _coin('SOL', AppColors.yes, AppColors.white, t, 3),
              ],
            ),
            const SizedBox(height: 18),
            Opacity(
              opacity: t,
              child: _Card(
                child: Row(
                  children: [
                    Container(width: 44, height: 44, decoration: const BoxDecoration(color: AppColors.yes, shape: BoxShape.circle), child: const Center(child: AppIcon(Ic.check, size: 22, color: AppColors.white))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('You backed YES', style: AppTextStyles.body(16, weight: FontWeight.w500)),
                        Text('\$25 at 62¢', style: AppTextStyles.caption),
                      ]),
                    ),
                    Text('+\$15.30', style: AppTextStyles.tabularNums(16, color: AppColors.yes)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coin(String s, Color bg, Color fg, double t, int i) {
    final k = ((t * 4) - i).clamp(0.0, 1.0);
    return Opacity(
      opacity: k,
      child: Transform.translate(
        offset: Offset(0, (1 - k) * -26),
        child: Container(
          width: 58,
          height: 58,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: AppColors.mist, width: 1.2)),
          child: Center(child: Text(s, style: AppTextStyles.body(12.5, weight: FontWeight.w500, color: fg))),
        ),
      ),
    );
  }
}
