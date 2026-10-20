import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFE8F0FF);
  static const darkPrimary = Color(0xFF96BBFF);
  static const darkPrimarySoft = Color(0xFF173560);
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF172033);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF008F62);
  static const green = Color(0xFF00C56A);
  static const low = Color(0xFF568318);
  static const warning = Color(0xFFB85A08);
  static const danger = Color(0xFFDC2447);
  static const critical = Color(0xFF991B32);
  static const purple = Color(0xFF9146DB);
  static const darkBackground = Color(0xFF0D1421);
  static const darkSurface = Color(0xFF182233);
  static const darkBorder = Color(0xFF334155);
  static const darkText = Color(0xFFF1F5F9);
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
