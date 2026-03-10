import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tüm tipografi tanımları — tüm text style'lar buradan kullanılır.
abstract final class AppTextStyles {
  // --- Display / Hero ---
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  // --- KPI Value (büyük rakam) ---
  static TextStyle get kpiValue => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  // --- KPI Label ---
  static TextStyle get kpiLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        letterSpacing: 0.3,
      );

  // --- KPI Sub ---
  static TextStyle get kpiSub => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // --- Section Header ---
  static TextStyle get sectionHeader => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  // --- Card Title ---
  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // --- Body Regular ---
  static TextStyle get bodyRegular => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  // --- Body Muted ---
  static TextStyle get bodyMuted => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // --- Body Small ---
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // --- Label / Badge ---
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  // --- Navigation Label ---
  static TextStyle get navLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  // --- Button ---
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  // --- Chart Axis ---
  static TextStyle get chartAxis => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // --- Chart Tooltip ---
  static TextStyle get chartTooltip => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.cardBg,
      );

  // --- Table Header ---
  static TextStyle get tableHeader => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.3,
      );

  // --- Table Cell ---
  static TextStyle get tableCell => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  // --- Mono (değerler için) ---
  static TextStyle get mono => const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );
}
