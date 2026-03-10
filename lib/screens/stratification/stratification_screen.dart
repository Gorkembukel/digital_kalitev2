import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../client/models/connection_status.dart';
import '../../client/providers/connection_provider.dart';
import '../../core/constants/spec_limits.dart';
import '../../core/models/alarm_level.dart';
import '../../core/models/measurement.dart';
import '../../core/spc/imr_calculator.dart';
import '../../core/spc/risk_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/alarm_badge.dart';
import '../../widgets/section_header.dart';

class StratificationScreen extends StatelessWidget {
  const StratificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, _) {
        if (conn.status != ConnectionStatus.connected) {
          return const _DisconnectedView();
        }
        return _StratificationBody(conn: conn);
      },
    );
  }
}

class _StratificationBody extends StatelessWidget {
  const _StratificationBody({required this.conn});
  final ConnectionProvider conn;

  @override
  Widget build(BuildContext context) {
    final data = conn.humidityData;

    // Vardiyaya göre grupla
    final byShift = <Shift, List<HumidityMeasurement>>{};
    for (final m in data) {
      final shift = Shift.fromDateTime(m.timestamp);
      byShift.putIfAbsent(shift, () => []).add(m);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Tabakalama Analizi',
            subtitle: 'Vardiyaya göre nem performansı karşılaştırması',
            showDivider: true,
          ),
          const SizedBox(height: 16),

          data.isEmpty
              ? const _EmptyCard('Tabakalama için yeterli veri yok.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vardiya karşılaştırma tablosu
                    _ShiftComparisonTable(byShift: byShift),
                    const SizedBox(height: 24),

                    // Vardiya bar grafiği (simple)
                    const SectionHeader(
                      title: 'Vardiya Performans Özeti',
                      subtitle: 'Ortalama nem ve OOB oranı karşılaştırması',
                    ),
                    const SizedBox(height: 12),
                    _ShiftBars(byShift: byShift),
                    const SizedBox(height: 24),

                    // Vardiya kartları
                    ...Shift.values.map((shift) {
                      final shiftData = byShift[shift] ?? [];
                      if (shiftData.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ShiftDetailCard(shift: shift, data: shiftData),
                      );
                    }),
                  ],
                ),
        ],
      ),
    );
  }
}

class _ShiftComparisonTable extends StatelessWidget {
  const _ShiftComparisonTable({required this.byShift});
  final Map<Shift, List<HumidityMeasurement>> byShift;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                _H('Vardiya', flex: 3),
                _H('n', flex: 1),
                _H('Ortalama', flex: 2),
                _H('Std.Sapma', flex: 2),
                _H('OOB %', flex: 2),
                _H('Cpk', flex: 2),
                _H('Durum', flex: 2),
              ],
            ),
          ),
          ...Shift.values.asMap().entries.map((e) {
            final shift = e.value;
            final shiftData = byShift[shift] ?? [];
            if (shiftData.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: e.key.isEven
                    ? AppColors.background.withValues(alpha: 0.5)
                    : AppColors.cardBg,
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: Text(shift.label, style: AppTextStyles.bodySmall),
                  ),
                  Expanded(
                    flex: 13,
                    child: Text('Veri yok',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                  ),
                ]),
              );
            }

            final values = shiftData.map((m) => m.value).toList();
            final stats = SummaryStats.fromValues(values);
            final oobRate = RiskCalculator.oobRate(values,
                lsl: SpecLimits.humidityLSL, usl: SpecLimits.humidityUSL);

            ImrResult? imr;
            double cpk = 0;
            if (values.length >= 2) {
              imr = ImrCalculator.calculate(values);
              if (imr.sigmaEstimate > 0) {
                final cpu = (SpecLimits.humidityUSL - stats.mean) / (3 * imr.sigmaEstimate);
                final cpl = (stats.mean - SpecLimits.humidityLSL) / (3 * imr.sigmaEstimate);
                cpk = cpu < cpl ? cpu : cpl;
              }
            }

            final level = oobRate > 0.05
                ? AlarmLevel.critical
                : oobRate > 0.01
                    ? AlarmLevel.high
                    : AlarmLevel.low;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: e.key.isEven
                  ? AppColors.background.withValues(alpha: 0.5)
                  : AppColors.cardBg,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(shift.label,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('${shiftData.length}',
                        style: AppTextStyles.bodySmall),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(stats.mean.toStringAsFixed(4),
                        style: AppTextStyles.bodySmall),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(stats.stddev.toStringAsFixed(4),
                        style: AppTextStyles.bodySmall),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '%${(oobRate * 100).toStringAsFixed(1)}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: oobRate > 0 ? AppColors.danger : AppColors.success,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      values.length >= 2 ? cpk.toStringAsFixed(3) : '—',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: cpk >= 1.33 ? AppColors.success : AppColors.warning),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: AlarmBadge(level: level, compact: true),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.text, {required this.flex});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
      );
}

class _ShiftBars extends StatelessWidget {
  const _ShiftBars({required this.byShift});
  final Map<Shift, List<HumidityMeasurement>> byShift;

  @override
  Widget build(BuildContext context) {
    final shiftColors = [AppColors.chartBlue, AppColors.success, AppColors.accent];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: Shift.values.asMap().entries.map((e) {
          final shift = e.value;
          final shiftData = byShift[shift] ?? [];
          if (shiftData.isEmpty) return const SizedBox.shrink();

          final values = shiftData.map((m) => m.value).toList();
          final stats = SummaryStats.fromValues(values);
          final oobRate = RiskCalculator.oobRate(values,
              lsl: SpecLimits.humidityLSL, usl: SpecLimits.humidityUSL);

          // Ortalama bar — normalize et spec aralığına göre
          final specRange = SpecLimits.humidityUSL - SpecLimits.humidityLSL;
          final barFill = ((stats.mean - SpecLimits.humidityLSL) / specRange).clamp(0.0, 1.0);
          final color = shiftColors[e.key % shiftColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(shift.label,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      'x̄=${stats.mean.toStringAsFixed(4)}  n=${shiftData.length}'
                      '  OOB=%${(oobRate * 100).toStringAsFixed(1)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: barFill,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Target line
                    FractionallySizedBox(
                      widthFactor:
                          (SpecLimits.humidityTarget - SpecLimits.humidityLSL) / specRange,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 2,
                          height: 20,
                          color: AppColors.centerLine,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ShiftDetailCard extends StatelessWidget {
  const _ShiftDetailCard({required this.shift, required this.data});
  final Shift shift;
  final List<HumidityMeasurement> data;

  @override
  Widget build(BuildContext context) {
    final values = data.map((m) => m.value).toList();
    final stats = SummaryStats.fromValues(values);
    final oobRate = RiskCalculator.oobRate(values,
        lsl: SpecLimits.humidityLSL, usl: SpecLimits.humidityUSL);
    final oobCount = data.where((m) => !SpecLimits.isHumidityInSpec(m.value)).length;

    AlarmLevel level;
    if (oobRate > SpecLimits.riskOobCritical) {
      level = AlarmLevel.critical;
    } else if (oobRate > SpecLimits.riskOobHigh) {
      level = AlarmLevel.high;
    } else if (oobRate > SpecLimits.riskOobMedium) {
      level = AlarmLevel.medium;
    } else {
      level = AlarmLevel.low;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: level.textColor.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(shift.label,
                    style: AppTextStyles.sectionHeader
                        .copyWith(color: level.textColor, fontSize: 14)),
              ),
              AlarmBadge(level: level, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 24, runSpacing: 8, children: [
            _DS('n', '${data.length}', level.textColor),
            _DS('Ortalama', '${stats.mean.toStringAsFixed(4)} %rH', level.textColor),
            _DS('Std.Sapma', stats.stddev.toStringAsFixed(5), level.textColor),
            _DS('Min', '${stats.min.toStringAsFixed(4)} %rH', level.textColor),
            _DS('Max', '${stats.max.toStringAsFixed(4)} %rH', level.textColor),
            _DS('OOB Sayısı', '$oobCount', level.textColor),
            _DS('OOB Oran', '%${(oobRate * 100).toStringAsFixed(2)}', level.textColor),
          ]),
        ],
      ),
    );
  }
}

class _DS extends StatelessWidget {
  const _DS(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AppTextStyles.kpiLabel.copyWith(color: color.withValues(alpha: 0.7))),
          Text(value,
              style: AppTextStyles.kpiValue.copyWith(fontSize: 14, color: color)),
        ],
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(message, style: AppTextStyles.bodyMuted),
      );
}

class _DisconnectedView extends StatelessWidget {
  const _DisconnectedView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('Sunucuya Bağlı Değil',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
          ],
        ),
      );
}
