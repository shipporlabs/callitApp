import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// The Callit mark: a yellow ring with a teal wedge on the right, an ink
/// outline and a dot in the middle — the same mark as the website.
/// [color] is kept for older call sites: a light colour means "on a dark
/// surface", so the outline and dot switch to paper.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32, this.color = AppColors.ink, this.useAsset = false});

  final double size;
  final Color color;
  final bool useAsset;

  @override
  Widget build(BuildContext context) {
    final onDark = color.computeLuminance() > 0.6;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: LogoMarkPainter(outline: onDark ? AppColors.paper : AppColors.ink)),
    );
  }
}

class LogoMarkPainter extends CustomPainter {
  LogoMarkPainter({required this.outline});
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final outerR = s / 2 * 0.95;
    final innerR = outerR * 0.58;
    final mid = (outerR + innerR) / 2;
    final w = outerR - innerR;
    final rect = Rect.fromCircle(center: c, radius: mid);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.butt;
    const pi = 3.141592653589793;
    canvas.drawArc(rect, pi / 4, 3 * pi / 2, false, ring..color = AppColors.highlight);
    canvas.drawArc(rect, -pi / 4, pi / 2, false, ring..color = AppColors.yes);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..color = outline;
    canvas.drawCircle(c, outerR - line.strokeWidth / 2, line);
    canvas.drawCircle(c, innerR + line.strokeWidth / 2, line);
    canvas.drawCircle(c, s * 0.12, Paint()..color = outline);
  }

  @override
  bool shouldRepaint(covariant LogoMarkPainter old) => old.outline != outline;
}
