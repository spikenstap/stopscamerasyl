import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF17675B);
  static const primarySoft = Color(0xFFE1EEE7);
  static const darkPrimary = Color(0xFF9BE0CC);
  static const darkPrimarySoft = Color(0xFF24483D);
  static const background = Color(0xFFF4F6F2);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1C302B);
  static const textSecondary = Color(0xFF5A6B64);
  static const border = Color(0xFFDCE4DD);
  static const hero = Color(0xFF173D33);
  static const onHero = Color(0xFFF5FAEE);
  static const heroMuted = Color(0xFFC1D6CA);
  static const accent = Color(0xFFD6EFAD);
  static const success = Color(0xFF008F62);
  static const green = Color(0xFF00C56A);
  static const low = Color(0xFF568318);
  static const warning = Color(0xFFB85A08);
  static const danger = Color(0xFFDC2447);
  static const critical = Color(0xFF991B32);
  static const purple = Color(0xFF9146DB);
  static const darkBackground = Color(0xFF111C18);
  static const darkSurface = Color(0xFF1C2B24);
  static const darkBorder = Color(0xFF3B4C42);
  static const darkText = Color(0xFFECF3E9);
  static const darkTextSecondary = Color(0xFFB4C6B9);
  static Color risk(int? score) => score == null
      ? textSecondary
      : score <= 20
      ? success
      : score <= 40
      ? low
      : score <= 60
      ? warning
      : score <= 80
      ? danger
      : critical;
}
