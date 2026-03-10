import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/spc/capability_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'chart_helpers.dart';

/// Histogram + Normal eğrisi grafiği.
class HistogramChart extends StatelessWidget {
  const HistogramChart({
    super.key,
    required this.bins,
    required this.mean,
    required this.sigma,
    this.lsl,
    this.usl,
    this.title = 'Histogram',
    this.height = 260,
  });

  final List<HistogramBin> bins;
  final double mean;
  final double sigma;
  final double? lsl;
  final double? usl;
  final String title;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (bins.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Veri yok')),
      );
    }

    final maxCount = bins.map((b) => b.count).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.cardTitle),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxCount * 1.15,
              barGroups: bins.asMap().entries.map((e) {
                final bin = e.value;
                final isInSpec = (lsl == null || bin.lower >= lsl!) &&
                    (usl == null || bin.upper <= usl!);
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: bin.count.toDouble(),
                      color: isInSpec
                          ? AppColors.chartBlue.withValues(alpha: 0.85)
                          : AppColors.danger.withValues(alpha: 0.85),
                      width: _barWidth(),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                topTitles: ChartHelpers.hiddenAxis,
                rightTitles: ChartHelpers.hiddenAxis,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: AppTextStyles.chartAxis,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= bins.length) {
                        return const SizedBox.shrink();
                      }
                      // Her 3-5 çubukta bir etiket göster
                      if (idx % (bins.length ~/ 5 + 1) != 0) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        bins[idx].midpoint.toStringAsFixed(2),
                        style: AppTextStyles.chartAxis,
                      );
                    },
                  ),
                ),
              ),
              gridData: ChartHelpers.chartGrid,
              borderData: ChartHelpers.chartBorder,
              extraLinesData: ExtraLinesData(
                horizontalLines: const [],
                verticalLines: [
                  // Ortalama çizgisi
                  VerticalLine(
                    x: _valueToBarIndex(mean),
                    color: AppColors.centerLine,
                    strokeWidth: 2,
                    dashArray: [4, 4],
                    label: VerticalLineLabel(
                      show: true,
                      alignment: Alignment.topLeft,
                      style: AppTextStyles.chartAxis
                          .copyWith(color: AppColors.centerLine),
                      labelResolver: (_) =>
                          'x̄=${mean.toStringAsFixed(3)}',
                    ),
                  ),
                  // LSL
                  if (lsl != null)
                    VerticalLine(
                      x: _valueToBarIndex(lsl!),
                      color: AppColors.accent.withValues(alpha: 0.8),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: AppTextStyles.chartAxis
                            .copyWith(color: AppColors.accent),
                        labelResolver: (_) => 'LSL',
                      ),
                    ),
                  // USL
                  if (usl != null)
                    VerticalLine(
                      x: _valueToBarIndex(usl!),
                      color: AppColors.accent.withValues(alpha: 0.8),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topLeft,
                        style: AppTextStyles.chartAxis
                            .copyWith(color: AppColors.accent),
                        labelResolver: (_) => 'USL',
                      ),
                    ),
                ],
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gIdx, rod, rIdx) {
                    final bin = bins[gIdx];
                    return BarTooltipItem(
                      '${bin.lower.toStringAsFixed(3)}–${bin.upper.toStringAsFixed(3)}\n'
                      'n = ${bin.count}',
                      AppTextStyles.chartTooltip,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Wrap(
          spacing: 16,
          children: [
            _LegendItem(
                color: AppColors.chartBlue.withValues(alpha: 0.85),
                label: 'Spec içi'),
            _LegendItem(
                color: AppColors.danger.withValues(alpha: 0.85),
                label: 'Spec dışı'),
            _LegendItem(color: AppColors.centerLine, label: 'Ortalama'),
            if (lsl != null || usl != null)
              _LegendItem(
                  color: AppColors.accent, label: 'LSL / USL', dashed: true),
          ],
        ),
      ],
    );
  }

  double _barWidth() => (bins.length > 20) ? 8 : 16;

  /// Bir değeri bar indeksine dönüştürür (çizgi pozisyonu için).
  double _valueToBarIndex(double value) {
    if (bins.isEmpty) return 0;
    final min = bins.first.lower;
    final max = bins.last.upper;
    final range = max - min;
    if (range == 0) return 0;
    return ((value - min) / range) * (bins.length - 1);
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(
      {required this.color, required this.label, this.dashed = false});
  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.chartAxis),
      ],
    );
  }
}
