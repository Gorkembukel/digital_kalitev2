import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../client/models/connection_status.dart';
import '../../client/providers/connection_provider.dart';
import '../../core/constants/spec_limits.dart';
import '../../core/models/alarm_level.dart';
import '../../core/spc/capability_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/alarm_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/charts/histogram_chart.dart';

class CapabilityScreen extends StatelessWidget {
  const CapabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, _) {
        if (conn.status != ConnectionStatus.connected) {
          return const _DisconnectedView();
        }
        return _CapabilityBody(conn: conn);
      },
    );
  }
}

class _CapabilityBody extends StatelessWidget {
  const _CapabilityBody({required this.conn});
  final ConnectionProvider conn;

  @override
  Widget build(BuildContext context) {
    final cap = conn.humidityCapability;
    final imr = conn.humidityImr;
    final values = conn.humidityData.map((m) => m.value).toList();

    AlarmLevel cpkLevel = AlarmLevel.low;
    if (cap != null) {
      if (cap.cpk >= SpecLimits.cpkExcellent) {
        cpkLevel = AlarmLevel.low;
      } else if (cap.cpk >= SpecLimits.cpkAdequate) {
        cpkLevel = AlarmLevel.medium;
      } else if (cap.cpk >= SpecLimits.cpkMarginal) {
        cpkLevel = AlarmLevel.high;
      } else {
        cpkLevel = AlarmLevel.critical;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Kapasite Analizi',
                  subtitle: 'Cp, Cpk, Pp, Ppk indeksleri ve histogram',
                  showDivider: true,
                ),
              ),
              const SizedBox(width: 12),
              AlarmBadge(level: cpkLevel),
            ],
          ),
          const SizedBox(height: 20),

          if (cap == null)
            const _EmptyCard('Kapasite analizi için yeterli veri yok.')
          else ...[
            // KPI - capability indices
            LayoutBuilder(builder: (_, c) {
              final cols = c.maxWidth > 700 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _IndexCard('Cp', cap.cp, 'Kısa dönem (potansiyel)',
                      _indexLevel(cap.cp)),
                  _IndexCard('Cpk', cap.cpk, cap.cpkGrade, cpkLevel),
                  _IndexCard('Pp', cap.pp, 'Uzun dönem (performans)',
                      _indexLevel(cap.pp)),
                  _IndexCard('Ppk', cap.ppk, 'Uzun dönem Cpk',
                      _indexLevel(cap.ppk)),
                ],
              );
            }),
            const SizedBox(height: 20),

            // Detay tablosu
            _DetailTable(cap: cap),
            const SizedBox(height: 24),

            // Histogram
            _Card(
              child: HistogramChart(
                bins: CapabilityCalculator.histogram(
                  values,
                  lsl: SpecLimits.humidityLSL,
                  usl: SpecLimits.humidityUSL,
                ),
                mean: cap.mean,
                sigma: imr?.sigmaEstimate ?? cap.sigmaShort,
                lsl: SpecLimits.humidityLSL,
                usl: SpecLimits.humidityUSL,
                title: 'Nem Dağılım Histogramı',
                height: 280,
              ),
            ),
            const SizedBox(height: 20),

            // PPM kartı
            _PpmCard(ppm: cap.ppm),
          ],
        ],
      ),
    );
  }

  AlarmLevel _indexLevel(double idx) {
    if (idx >= SpecLimits.cpkExcellent) return AlarmLevel.low;
    if (idx >= SpecLimits.cpkAdequate) return AlarmLevel.medium;
    if (idx >= SpecLimits.cpkMarginal) return AlarmLevel.high;
    return AlarmLevel.critical;
  }
}

class _IndexCard extends StatelessWidget {
  const _IndexCard(this.label, this.value, this.subtitle, this.level);
  final String label, subtitle;
  final double value;
  final AlarmLevel level;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: level.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: level.textColor.withValues(alpha: 0.25)),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowColor, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: AppTextStyles.sectionHeader.copyWith(
                        color: level.textColor, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: level.textColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    level.label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: level.textColor, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value.toStringAsFixed(3),
              style: AppTextStyles.kpiValue
                  .copyWith(color: level.textColor, fontSize: 26),
            ),
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppTextStyles.kpiLabel
                    .copyWith(color: level.textColor.withValues(alpha: 0.7))),
          ],
        ),
      );
}

class _DetailTable extends StatelessWidget {
  const _DetailTable({required this.cap});
  final CapabilityResult cap;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Ortalama (x̄)', cap.mean.toStringAsFixed(5), '%rH'),
      ('σ Kısa Dönem', cap.sigmaShort.toStringAsFixed(5), '(IMR bazlı)'),
      ('σ Uzun Dönem', cap.sigmaLong.toStringAsFixed(5), '(popülasyon)'),
      ('CPU', cap.cpu.toStringAsFixed(3), 'Üst limit kapasitesi'),
      ('CPL', cap.cpl.toStringAsFixed(3), 'Alt limit kapasitesi'),
      ('PPU', cap.ppu.toStringAsFixed(3), 'Uzun dönem üst'),
      ('PPL', cap.ppl.toStringAsFixed(3), 'Uzun dönem alt'),
      ('LSL', cap.lsl.toStringAsFixed(3), '%rH'),
      ('USL', cap.usl.toStringAsFixed(3), '%rH'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _H('Parametre', flex: 3),
                _H('Değer', flex: 2),
                _H('Açıklama', flex: 4),
              ],
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final (param, val, note) = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              color: e.key.isEven
                  ? AppColors.background.withValues(alpha: 0.5)
                  : AppColors.cardBg,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(param,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(val,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(note,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted)),
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
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      );
}

class _PpmCard extends StatelessWidget {
  const _PpmCard({required this.ppm});
  final double ppm;

  @override
  Widget build(BuildContext context) {
    final isGood = ppm < 3400; // 6σ = ~3.4 PPM
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGood ? AppColors.alarmLowBg : AppColors.alarmHighBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isGood
                ? AppColors.alarmLowText.withValues(alpha: 0.3)
                : AppColors.alarmHighText.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.verified_rounded : Icons.warning_amber_rounded,
            color: isGood ? AppColors.alarmLowText : AppColors.alarmHighText,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tahmini PPM (Parts Per Million)',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted)),
              Text(
                '${ppm.toStringAsFixed(1)} PPM',
                style: AppTextStyles.kpiValue.copyWith(
                    fontSize: 22,
                    color: isGood
                        ? AppColors.alarmLowText
                        : AppColors.alarmHighText),
              ),
              Text(
                isGood
                    ? 'Normal dağılım varsayımıyla hesaplanmıştır.'
                    : 'Her milyonda ${ppm.toStringAsFixed(0)} ürün spec dışı olabilir.',
                style: AppTextStyles.bodySmall.copyWith(
                    color: isGood
                        ? AppColors.alarmLowText.withValues(alpha: 0.7)
                        : AppColors.alarmHighText.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: child,
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
