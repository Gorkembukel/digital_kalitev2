import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../client/models/connection_status.dart';
import '../../client/providers/connection_provider.dart';
import '../../core/constants/spec_limits.dart';
import '../../core/models/alarm_level.dart';
import '../../core/spc/capability_calculator.dart';
import '../../core/spc/risk_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/alarm_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/charts/imr_chart.dart';
import '../../widgets/charts/histogram_chart.dart';

class HumiditySpcScreen extends StatefulWidget {
  const HumiditySpcScreen({super.key});

  @override
  State<HumiditySpcScreen> createState() => _HumiditySpcScreenState();
}

class _HumiditySpcScreenState extends State<HumiditySpcScreen> {
  int _maxPoints = 100;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, _) {
        if (conn.status != ConnectionStatus.connected) {
          return const _DisconnectedView();
        }
        return _HumidityBody(
          conn: conn,
          maxPoints: _maxPoints,
          onMaxPointsChanged: (v) => setState(() => _maxPoints = v),
        );
      },
    );
  }
}

class _HumidityBody extends StatelessWidget {
  const _HumidityBody({
    required this.conn,
    required this.maxPoints,
    required this.onMaxPointsChanged,
  });
  final ConnectionProvider conn;
  final int maxPoints;
  final ValueChanged<int> onMaxPointsChanged;

  @override
  Widget build(BuildContext context) {
    final imr = conn.humidityImr;
    final cap = conn.humidityCapability;
    final data = conn.humidityData;
    final values = data.map((m) => m.value).toList();

    final stats = values.isNotEmpty ? SummaryStats.fromValues(values) : null;
    final oobRate = values.isNotEmpty
        ? RiskCalculator.oobRate(values,
            lsl: SpecLimits.humidityLSL, usl: SpecLimits.humidityUSL)
        : 0.0;
    final trend = values.length > 5
        ? RiskCalculator.trendSlope(values, windowSize: 30)
        : 0.0;

    AlarmLevel level = conn.humidityRisk?.level ?? AlarmLevel.low;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Nem SPC — Kapsamlı Analiz',
                  subtitle: 'I-MR, histogram ve istatistik özeti',
                  showDivider: true,
                ),
              ),
              const SizedBox(width: 12),
              AlarmBadge(level: level),
              const SizedBox(width: 8),
              IconButton(
                onPressed: conn.refresh,
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.primary,
                tooltip: 'Yenile',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // İstatistik özeti
          if (stats != null) _StatsGrid(stats: stats, oobRate: oobRate, trend: trend),
          const SizedBox(height: 20),

          // Grafik başlığı + nokta sayısı seçici
          Row(
            children: [
              const Expanded(
                child: SectionHeader(title: 'I-MR Kontrol Diyagramı'),
              ),
              _PointSelector(
                value: maxPoints,
                onChanged: onMaxPointsChanged,
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (imr != null)
            _Card(
              child: ImrChart(
                result: imr,
                title: 'Nem I-MR Kontrol Diyagramı',
                yAxisLabel: '%rH',
                maxPoints: maxPoints,
                height: 460,
              ),
            )
          else
            const _EmptyCard('I-MR grafiği için yeterli veri yok.'),
          const SizedBox(height: 24),

          // Spesifikasyon bilgisi
          _SpecInfoCard(imr: imr, cap: cap),
          const SizedBox(height: 24),

          // Histogram
          const SectionHeader(title: 'Dağılım Histogramı'),
          const SizedBox(height: 10),
          if (values.length >= 5)
            _Card(
              child: HistogramChart(
                bins: CapabilityCalculator.histogram(
                  values,
                  lsl: SpecLimits.humidityLSL,
                  usl: SpecLimits.humidityUSL,
                ),
                mean: stats?.mean ?? 0,
                sigma: imr?.sigmaEstimate ?? 0,
                lsl: SpecLimits.humidityLSL,
                usl: SpecLimits.humidityUSL,
                title: 'Nem Değer Dağılımı',
                height: 260,
              ),
            )
          else
            const _EmptyCard('Histogram için yeterli veri yok (en az 5 gerekli).'),

          const SizedBox(height: 24),

          // Son ölçümler tablosu
          const SectionHeader(
            title: 'Son Ölçümler',
            subtitle: 'En son 20 nem ölçümü',
          ),
          const SizedBox(height: 10),
          _RecentTable(data: data.length > 20 ? data.sublist(data.length - 20) : data),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.oobRate, required this.trend});
  final SummaryStats stats;
  final double oobRate;
  final double trend;

  @override
  Widget build(BuildContext context) {
    final trendDir = trend > 0.001
        ? '↑ Artıyor'
        : trend < -0.001
            ? '↓ Azalıyor'
            : '→ Stabil';

    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 700 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StatTile('Ortalama', '${stats.mean.toStringAsFixed(4)} %rH',
              AppColors.primary),
          _StatTile('Std. Sapma', stats.stddev.toStringAsFixed(5),
              AppColors.info),
          _StatTile('Min / Max',
              '${stats.min.toStringAsFixed(3)} / ${stats.max.toStringAsFixed(3)}',
              AppColors.textMuted),
          _StatTile('n (ölçüm)', '${stats.count}', AppColors.primary),
          _StatTile(
              'Spec Dışı Oran',
              '%${(oobRate * 100).toStringAsFixed(2)}',
              oobRate > 0.05 ? AppColors.danger : AppColors.success),
          _StatTile('Trend (son 30)', trendDir,
              trend.abs() > 0.005 ? AppColors.warning : AppColors.success),
          _StatTile('LSL', '${SpecLimits.humidityLSL} %rH', AppColors.accent),
          _StatTile('USL', '${SpecLimits.humidityUSL} %rH', AppColors.accent),
        ],
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.kpiLabel),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.kpiValue
                    .copyWith(fontSize: 14, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _PointSelector extends StatelessWidget {
  const _PointSelector({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [50, 100, 200, 300];
    return Row(
      children: [
        Text('Göster: ', style: AppTextStyles.bodySmall),
        ...options.map((n) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: InkWell(
                onTap: () => onChanged(n),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: value == n ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('$n',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: value == n ? Colors.white : AppColors.textMuted,
                          fontWeight: value == n
                              ? FontWeight.w700
                              : FontWeight.w400)),
                ),
              ),
            )),
      ],
    );
  }
}

class _SpecInfoCard extends StatelessWidget {
  const _SpecInfoCard({this.imr, this.cap});
  final dynamic imr;
  final dynamic cap;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('Spesifikasyon & Kontrol Limitleri',
                  style: AppTextStyles.cardTitle),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _SL('LSL', '${SpecLimits.humidityLSL} %rH', AppColors.accent),
                _SL('Hedef', '${SpecLimits.humidityTarget} %rH', AppColors.success),
                _SL('USL', '${SpecLimits.humidityUSL} %rH', AppColors.accent),
                if (imr != null)
                  _SL('UCL (I)', (imr.uclI as double).toStringAsFixed(4),
                      AppColors.controlLimitUpper),
                if (imr != null)
                  _SL('LCL (I)', (imr.lclI as double).toStringAsFixed(4),
                      AppColors.controlLimitUpper),
                if (imr != null)
                  _SL('σ IMR', (imr.sigmaEstimate as double).toStringAsFixed(5),
                      AppColors.primary),
                if (cap != null)
                  _SL('Cpk', (cap.cpk as double).toStringAsFixed(3),
                      AppColors.info),
              ],
            ),
          ],
        ),
      );
}

class _SL extends StatelessWidget {
  const _SL(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.kpiLabel),
          Text(value,
              style: AppTextStyles.kpiValue.copyWith(fontSize: 14, color: color)),
        ],
      );
}

class _RecentTable extends StatelessWidget {
  const _RecentTable({required this.data});
  final List<dynamic> data;

  @override
  Widget build(BuildContext context) {
    final reversed = data.reversed.toList();
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                _H('Zaman', flex: 3),
                _H('Değer (%rH)', flex: 3),
                _H('Durum', flex: 2),
              ],
            ),
          ),
          ...reversed.asMap().entries.map((e) {
            final m = e.value;
            final val = m.value as double;
            final ts = m.timestamp as DateTime;
            final inSpec = SpecLimits.isHumidityInSpec(val);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: e.key.isEven
                  ? AppColors.background.withValues(alpha: 0.5)
                  : AppColors.cardBg,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      DateFormat('HH:mm:ss  dd/MM/yy').format(ts),
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      val.toStringAsFixed(4),
                      style: AppTextStyles.bodySmall.copyWith(
                          color: inSpec
                              ? AppColors.textPrimary
                              : AppColors.alarmCriticalText,
                          fontWeight: inSpec
                              ? FontWeight.w400
                              : FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      inSpec ? 'Spec içi' : 'SPEC DIŞI',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: inSpec
                              ? AppColors.alarmLowText
                              : AppColors.alarmCriticalText,
                          fontWeight: FontWeight.w600),
                    ),
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
