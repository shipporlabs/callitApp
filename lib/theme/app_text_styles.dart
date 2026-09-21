import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Space Grotesk for display/headings, IBM Plex Sans for body copy —
/// matches the landing page's type pairing. Numbers use tabular figures
/// wherever prices or percentages appear, so they don't jitter live.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _display => GoogleFonts.spaceGrotesk();
  static TextStyle get _body => GoogleFonts.ibmPlexSans();

  static TextStyle display(double size, {FontWeight weight = FontWeight.w700, Color? color, double? height, double? letterSpacing}) {
    return _display.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.ink,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color, double? height}) {
    return _body.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.ink,
      height: height ?? 1.45,
    );
  }

  static TextStyle tabularNums(double size, {FontWeight weight = FontWeight.w700, Color? color}) {
    return _body.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Convenience presets used across screens
  static TextStyle get h1 => display(34, weight: FontWeight.w700, letterSpacing: -0.5);
  static TextStyle get h2 => display(26, weight: FontWeight.w700, letterSpacing: -0.3);
  static TextStyle get h3 => display(20, weight: FontWeight.w600);
  static TextStyle get subtitle => body(16, color: AppColors.slate, height: 1.5);
  static TextStyle get caption => body(13, color: AppColors.slate);
  static TextStyle get button => _body.copyWith(fontSize: 15, fontWeight: FontWeight.w700);
}
