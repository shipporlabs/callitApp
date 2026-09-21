import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../app_images.dart';
import 'app_image.dart';

/// The Callit logomark — a ring with a check stroke, drawn with
/// CustomPaint so it never depends on an asset file. Pass
/// `useAsset: true` to swap in `assets/icons/logo.png` once you have one.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32, this.color = AppColors.ink, this.useAsset = false});

  final double size;
  final Color color;
  final bool useAsset;

  @override
  Widget build(BuildContext context) {
    if (useAsset) {
      return AppImage(AppImages.logo, width: size, height: size, fallbackIcon: Icons.check_circle_outline);
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(color: color)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - ringPaint.strokeWidth;
    canvas.drawCircle(center, radius, ringPaint);

    final checkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.31, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.65)
      ..lineTo(size.width * 0.70, size.height * 0.36);

    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => oldDelegate.color != color;
}
