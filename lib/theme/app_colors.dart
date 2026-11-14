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

  // Soft tints of the accent, for illustration panels and glows (22% / 42% yellow on white).
  static const Color tint = Color(0xFFFFF5D5);
  static const Color tint2 = Color(0xFFFFECAE);

  static const Color success = yes;

  /// Arrow-disc colour for the two filled button variants.
  static Color yellowOrInk(Object variant) => variant.toString().endsWith('secondary') ? ink : highlight;
  static const Color danger = no;
}
