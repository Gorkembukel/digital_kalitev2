import 'package:flutter/material.dart';

/// Kurumsal renk paleti — tüm renkler buradan kullanılır, hardcode yasak.
abstract final class AppColors {
  // --- Brand ---
  static const Color primary = Color(0xFF1B3A6B);
  static const Color accent = Color(0xFFE84E0F);

  // --- Backgrounds ---
  static const Color background = Color(0xFFF0F2F8);
  static const Color cardBg = Color(0xFFFFFFFF);

  // --- Text ---
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF6B7280);

  // --- Status ---
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color danger = Color(0xFFE74C3C);
  static const Color info = Color(0xFF2980B9);

  // --- Charts ---
  static const Color chartBlue = Color(0xFF2E86AB);
  static const Color chartOrange = Color(0xFFE84E0F);

  // --- UI ---
  static const Color border = Color(0xFFE2E8F0);

  // --- Alarm Level Backgrounds ---
  static const Color alarmCriticalBg = Color(0xFFFDECEA);
  static const Color alarmHighBg = Color(0xFFFEF0E7);
  static const Color alarmMediumBg = Color(0xFFFEF9E7);
  static const Color alarmLowBg = Color(0xFFEAF7EF);

  // --- Alarm Level Texts ---
  static const Color alarmCriticalText = Color(0xFFC0392B);
  static const Color alarmHighText = Color(0xFFD35400);
  static const Color alarmMediumText = Color(0xFFB7770D);
  static const Color alarmLowText = Color(0xFF1E8449);

  // --- Chart Control Limits ---
  static const Color controlLimitUpper = Color(0xFFE74C3C);
  static const Color controlLimitLower = Color(0xFFE74C3C);
  static const Color centerLine = Color(0xFF27AE60);
  static const Color dataPointNormal = Color(0xFF2E86AB);
  static const Color dataPointOOC = Color(0xFFE84E0F); // Out of Control

  // --- Shadow ---
  static const Color shadowColor = Color(0x1A1B3A6B); // rgba(27,58,107,0.10)

  // --- Transparent ---
  static const Color transparent = Colors.transparent;
}
