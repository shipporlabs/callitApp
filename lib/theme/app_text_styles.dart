import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Type system, matching the Callit website:
///  - Instrument Serif for big headings (regular only),
///  - Onest for everything else, never heavier than Medium (500).
/// Size does the work, not weight. Numbers use tabular figures.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _serif => GoogleFonts.instrumentSerif();
  static TextStyle get _sans => GoogleFonts.onest();

  /// Anything bolder than Medium is clamped to Medium.
  static FontWeight cap(FontWeight w) => w.value >= 500 ? FontWeight.w500 : FontWeight.w400;

  /// Headings. From 22px up this is Instrument Serif; smaller "display"
  /// text (card titles) falls back to Onest Medium so it stays readable.
  static TextStyle display(double size, {FontWeight weight = FontWeight.w400, Color? color, double? height, double? letterSpacing}) {
    if (size >= 22) {
      return _serif.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.ink,
        height: height ?? 1.04,
        letterSpacing: letterSpacing ?? -size * 0.012,
      );
    }
    return _sans.copyWith(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.ink,
      height: height ?? 1.3,
      letterSpacing: letterSpacing ?? -0.1,
    );
  }

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color, double? height}) {
    return _sans.copyWith(
      fontSize: size,
      fontWeight: cap(weight),
      color: color ?? AppColors.ink,
      height: height ?? 1.45,
    );
  }

  static TextStyle tabularNums(double size, {FontWeight weight = FontWeight.w500, Color? color}) {
    return _sans.copyWith(
      fontSize: size,
      fontWeight: cap(weight),
      color: color ?? AppColors.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// A small, letter-spaced eyebrow label: "TRENDING", "TRANSFER EXACTLY".
  static TextStyle label(double size, {FontWeight weight = FontWeight.w500, Color? color}) {
    return _sans.copyWith(
      fontSize: size,
      fontWeight: cap(weight),
      color: color ?? AppColors.slate,
      letterSpacing: 0.9,
    );
  }

  static TextStyle get h1 => display(44, letterSpacing: -0.6);
  static TextStyle get h2 => display(32, letterSpacing: -0.4);
  static TextStyle get h3 => display(20);
  static TextStyle get subtitle => body(16, color: AppColors.slate, height: 1.5);
  static TextStyle get caption => body(13, color: AppColors.slate);
  static TextStyle get button => _sans.copyWith(fontSize: 16, fontWeight: FontWeight.w500);
}
