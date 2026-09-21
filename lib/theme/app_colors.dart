import 'package:flutter/material.dart';

/// Callit brand palette — kept identical to the landing page and PRD
/// so the app and the marketing site read as one product.
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF111426); // primary text, headings, dark surfaces
  static const Color paper = Color(0xFFFBF8F1); // app background
  static const Color highlight = Color(0xFFFFD23F); // brand accent, CTAs
  static const Color yes = Color(0xFF0B7F76); // YES side
  static const Color no = Color(0xFFD63645); // NO side
  static const Color slate = Color(0xFF5B6478); // secondary text
  static const Color mist = Color(0xFFE7E4DA); // borders, dividers, chips
  static const Color white = Color(0xFFFFFFFF);

  // Dark-surface variants (used on Ink backgrounds, e.g. wallet & creator screens)
  static const Color inkSurface = Color(0xFF1B1F38);
  static const Color inkBorder = Color(0xFF2C304D);
  static const Color inkMuted = Color(0xFF9FA3B8);
  static const Color inkMuted2 = Color(0xFFC9CBD8);

  static const Color success = yes;
  static const Color danger = no;
}
