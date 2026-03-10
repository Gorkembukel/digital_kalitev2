import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// fl_chart için ortak yardımcı fonksiyon ve stiller.
abstract final class ChartHelpers {
  /// Değer eksenini formatlar (3 ondalık basamak).
  static String formatY(double v, {int decimals = 3}) =>
      v.toStringAsFixed(decimals);

  /// Kontrol limiti çizgisi — kırmızı kesikli.
  static HorizontalLine controlLimit(double y, {String? label}) =>
      HorizontalLine(
        y: y,
        color: AppColors.controlLimitUpper,
        strokeWidth: 1.5,
        dashArray: [6, 4],
        label: label == null
            ? null
            : HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                style: AppTextStyles.chartAxis
                    .copyWith(color: AppColors.controlLimitUpper),
                labelResolver: (_) => label,
              ),
      );

  /// Merkez çizgisi — yeşil.
  static HorizontalLine centerLine(double y, {String? label}) =>
      HorizontalLine(
        y: y,
        color: AppColors.centerLine,
        strokeWidth: 1.5,
        label: label == null
            ? null
            : HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                style: AppTextStyles.chartAxis
                    .copyWith(color: AppColors.centerLine),
                labelResolver: (_) => label,
              ),
      );

  /// Spesifikasyon limiti çizgisi — turuncu.
  static HorizontalLine specLimit(double y, {String? label}) =>
      HorizontalLine(
        y: y,
        color: AppColors.accent.withValues(alpha: 0.7),
        strokeWidth: 1.5,
        dashArray: [10, 4],
        label: label == null
            ? null
            : HorizontalLineLabel(
                show: true,
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                style: AppTextStyles.chartAxis
                    .copyWith(color: AppColors.accent),
                labelResolver: (_) => label,
              ),
      );

  /// Genel LineChart border ayarı.
  static FlBorderData get chartBorder => FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5), width: 1),
          left: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5), width: 1),
        ),
      );

  /// Genel grid ayarı.
  static FlGridData get chartGrid => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.border.withValues(alpha: 0.4),
          strokeWidth: 0.8,
        ),
      );

  /// X ekseni (index) başlık ayarı.
  static AxisTitles indexXTitles({int step = 1}) => AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: step.toDouble(),
          getTitlesWidget: (v, _) => Text(
            '${v.toInt()}',
            style: AppTextStyles.chartAxis,
          ),
        ),
      );

  /// Y ekseni başlık ayarı.
  static AxisTitles yTitles({int decimals = 2}) => AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (v, _) => Text(
            v.toStringAsFixed(decimals),
            style: AppTextStyles.chartAxis,
          ),
        ),
      );

  /// Gizlenmiş eksen.
  static const AxisTitles hiddenAxis = AxisTitles(
    sideTitles: SideTitles(showTitles: false),
  );

  /// OOC nokta için painter.
  static FlDotCirclePainter oocDot() =>
      FlDotCirclePainter(radius: 4, color: AppColors.dataPointOOC);

  /// Normal nokta (gizli).
  static FlDotCirclePainter hiddenDot() =>
      FlDotCirclePainter(radius: 0, color: Colors.transparent);
}
