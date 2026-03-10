import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/spc/imr_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'chart_helpers.dart';

/// I-MR (Individuals & Moving Range) kontrol diyagramı.
///
/// Üstte I chart, altta MR chart olmak üzere iki grafik gösterir.
class ImrChart extends StatelessWidget {
  const ImrChart({
    super.key,
    required this.result,
    this.title = 'I-MR Kontrol Diyagramı',
    this.yAxisLabel = '',
    this.maxPoints = 100,
    this.height = 420,
  });

  final ImrResult result;
  final String title;
  final String yAxisLabel;

  /// Grafik'te gösterilecek maksimum nokta sayısı (sağdan).
  final int maxPoints;

  final double height;

  @override
  Widget build(BuildContext context) {
    final values = _lastN(result.values, maxPoints);
    final mrs = _lastN(result.movingRanges, maxPoints);
    final offset = result.values.length > maxPoints
        ? result.values.length - maxPoints
        : 0;

    // OOC setleri (offset'e göre normalize)
    final oocI = result.oocIndividuals
        .where((i) => i >= offset)
        .map((i) => i - offset)
        .toSet();
    final oocMR = result.oocMovingRanges
        .where((i) => i >= offset)
        .map((i) => i - offset)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartTitle(title: title),
        const SizedBox(height: 4),
        SizedBox(
          height: height,
          child: Column(
            children: [
              // ── I Chart ─────────────────────────────────────────────────
              Expanded(
                flex: 3,
                child: _SubChart(
                  label: 'I  (Bireysel Değerler)',
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [_iBar(values, oocI)],
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          ChartHelpers.controlLimit(result.uclI,
                              label: 'UCL=${result.uclI.toStringAsFixed(3)}'),
                          ChartHelpers.centerLine(result.mean,
                              label: 'x̄=${result.mean.toStringAsFixed(3)}'),
                          ChartHelpers.controlLimit(result.lclI,
                              label: 'LCL=${result.lclI.toStringAsFixed(3)}'),
                        ],
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: ChartHelpers.hiddenAxis,
                        topTitles: ChartHelpers.hiddenAxis,
                        rightTitles: ChartHelpers.hiddenAxis,
                        leftTitles: ChartHelpers.yTitles(decimals: 3),
                      ),
                      gridData: ChartHelpers.chartGrid,
                      borderData: ChartHelpers.chartBorder,
                      clipData: const FlClipData.all(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── MR Chart ────────────────────────────────────────────────
              Expanded(
                flex: 2,
                child: _SubChart(
                  label: 'MR  (Hareketli Aralık)',
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [_mrBar(mrs, oocMR)],
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          ChartHelpers.controlLimit(result.uclMR,
                              label: 'UCL=${result.uclMR.toStringAsFixed(3)}'),
                          ChartHelpers.centerLine(result.meanMR,
                              label: 'MR̄=${result.meanMR.toStringAsFixed(3)}'),
                        ],
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: ChartHelpers.indexXTitles(
                            step: values.length ~/ 5 + 1),
                        topTitles: ChartHelpers.hiddenAxis,
                        rightTitles: ChartHelpers.hiddenAxis,
                        leftTitles: ChartHelpers.yTitles(decimals: 3),
                      ),
                      gridData: ChartHelpers.chartGrid,
                      borderData: ChartHelpers.chartBorder,
                      clipData: const FlClipData.all(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        _Legend(),
      ],
    );
  }

  LineChartBarData _iBar(List<double> values, Set<int> oocIdx) =>
      LineChartBarData(
        spots: values.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList(),
        isCurved: false,
        color: AppColors.chartBlue,
        barWidth: 1.5,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, _, __, i) => oocIdx.contains(i)
              ? ChartHelpers.oocDot()
              : ChartHelpers.hiddenDot(),
        ),
        belowBarData: BarAreaData(show: false),
      );

  LineChartBarData _mrBar(List<double> mrs, Set<int> oocIdx) =>
      LineChartBarData(
        spots: mrs.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList(),
        isCurved: false,
        color: AppColors.chartBlue.withValues(alpha: 0.8),
        barWidth: 1.5,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, _, __, i) => oocIdx.contains(i)
              ? ChartHelpers.oocDot()
              : ChartHelpers.hiddenDot(),
        ),
        belowBarData: BarAreaData(show: false),
      );

  static List<double> _lastN(List<double> list, int n) =>
      list.length > n ? list.sublist(list.length - n) : list;
}

class _SubChart extends StatelessWidget {
  const _SubChart({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.chartAxis.copyWith(
                color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Expanded(child: child),
      ],
    );
  }
}

class _ChartTitle extends StatelessWidget {
  const _ChartTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.cardTitle),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _LegendItem(color: AppColors.chartBlue, label: 'Veri'),
        _LegendItem(color: AppColors.centerLine, label: 'Merkez (x̄)'),
        _LegendItem(
            color: AppColors.controlLimitUpper,
            label: 'UCL / LCL',
            dashed: true),
        _LegendItem(color: AppColors.dataPointOOC, label: 'Kontrol Dışı'),
      ],
    );
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
        Container(
          width: 20,
          height: 2,
          color: dashed ? Colors.transparent : color,
          child: dashed
              ? CustomPaint(painter: _DashPainter(color: color))
              : null,
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.chartAxis),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width * 0.6, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
