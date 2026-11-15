import 'package:flutter/material.dart';

/// Brand colours — identical to the website's CSS variables
/// (website/assets/css/style.css :root).
class AppColors {
  AppColors._();

  static const Color govGreen = Color(0xFF0D4A3A); // --gov-green
  static const Color govGreenDark = Color(0xFF072E24); // --gov-green-dark
  static const Color govGoldBronze = Color(0xFF9E793E); // --gov-gold
  static const Color govBgLight = Color(0xFFF8FAF9); // --gov-bg-light
  static const Color borderColor = Color(0xFFE5E7EB); // --border-color
  static const Color textColor = Color(0xFF1F2937); // body text
  static const Color muted = Color(0xFF6B7280);
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFB45309);

  static const String fontFamily = 'IBM Plex Sans Arabic';
}
