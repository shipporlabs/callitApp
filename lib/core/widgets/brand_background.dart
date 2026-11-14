import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// The website's background: a faint grid fading out from the top, plus one
/// soft yellow glow rising from the bottom. Used on splash, onboarding and
/// welcome so the app and the site read as one product.
class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, this.child, this.glow = 0.5});

  final Widget? child;
  final double glow; // 0..1 strength of the bottom glow

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.paper),
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const RadialGradient(
            center: Alignment(0, -0.7),
            radius: 0.9,
            colors: [Colors.black, Colors.transparent],
          ).createShader(r),
          child: CustomPaint(painter: _GridPainter()),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionalTranslation(
            translation: const Offset(0, 0.45),
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.highlight.withOpacity(glow), AppColors.highlight.withOpacity(0)]),
              ),
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.mist
      ..strokeWidth = 1;
    const step = 44.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
