import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../client/models/connection_status.dart';
import '../../client/providers/connection_provider.dart';
import '../../core/constants/spec_limits.dart';
import '../../core/models/alarm_level.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/alarm_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/charts/imr_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, _) {
        if (conn.status == ConnectionStatus.disconnected) {
          return const _DisconnectedPlaceholder();
        }
        if (conn.status == ConnectionStatus.connecting) {
          return const Center(child: CircularProgressIndicator());
        }
        return _DashboardBody(conn: conn);
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.conn});
  final ConnectionProvider conn;

  @override
  Widget build(BuildContext context) {
    final imr = conn.humidityImr;
    final risk = conn.humidityRisk;
    final cap = conn.humidityCapability;
    final latest =
        conn.humidityData.isNotEmpty ? conn.humidityData.last : null;
    final alarmLevel = risk?.level ?? AlarmLevel.low;

    return RefreshIndicator(
      onRefresh: conn.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SectionHeader(
                    title: 'Ana Dashboard',
                    subtitle: 'Son güncelleme: ${_fmt(latest?.timestamp)}',
                    showDivider: true,
                  ),
                ),
                const SizedBox(width: 12),
                AlarmBadge(level: alarmLevel),
                IconButton(
                  onPressed: conn.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.primary,
                  tooltip: 'Yenile',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // KPI Kartları
            LayoutBuilder(builder: (_, c) {
              final cols = c.maxWidth > 800 ? 4 : c.maxWidth > 500 ? 2 : 1;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  KpiCard(
                    label: 'ORT. NEM',
                    value: imr != null
                        ? '${imr.mean.toStringAsFixed(3)} %rH'
                        : '—',
                    sub: 'n = ${conn.humidityData.length}',
                    level: alarmLevel,
                    icon: Icons.water_drop_outlined,
                  ),
                  KpiCard(
                    label: 'SON ÖLÇÜM',
                    value: latest != null
                        ? '${latest.value.toStringAsFixed(3)} %rH'
                        : '—',
                    sub: _fmt(latest?.timestamp),
                    level: latest != null
                        ? (SpecLimits.isHumidityInSpec(latest.value)
                            ? AlarmLevel.low
                            : AlarmLevel.critical)
                        : AlarmLevel.low,
                    icon: Icons.sensors_rounded,
                  ),
                  KpiCard(
                    label: 'CPK',
                    value: cap != null ? cap.cpk.toStringAsFixed(3) : '—',
                    sub: cap?.cpkGrade ?? '',
                    level: cap != null ? _cpkLevel(cap.cpk) : AlarmLevel.low,
                    icon: Icons.speed_outlined,
                  ),
                  KpiCard(
                    label: 'NELSON İHLAL',
                    value: '${conn.nelsonViolations.length}',
                    sub: conn.nelsonViolations.isEmpty
                        ? 'Kural ihlali yok'
                        : conn.nelsonViolations
                            .map((v) => 'K${v.rule}')
                            .join(', '),
                    level: conn.nelsonViolations.isEmpty
                        ? AlarmLevel.low
                        : AlarmLevel.high,
                    icon: Icons.rule_rounded,
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Risk Özeti
            if (risk != null) ...[
              _RiskCard(risk: risk),
              const SizedBox(height: 24),
            ],

            // I-MR Grafiği
            if (imr != null) ...[
              _ChartCard(
                child: ImrChart(
                  result: imr,
                  title: 'Nem I-MR Kontrol Diyagramı',
                  yAxisLabel: '%rH',
                  maxPoints: 60,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Spec Özeti
            _SpecCard(imr: imr),
          ],
        ),
      ),
    );
  }

  AlarmLevel _cpkLevel(double cpk) {
    if (cpk >= SpecLimits.cpkExcellent) return AlarmLevel.low;
    if (cpk >= SpecLimits.cpkAdequate) return AlarmLevel.medium;
    if (cpk >= SpecLimits.cpkMarginal) return AlarmLevel.high;
    return AlarmLevel.critical;
  }

  String _fmt(DateTime? dt) =>
      dt == null ? '—' : DateFormat('HH:mm:ss').format(dt);
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child});
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

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.risk});
  final dynamic risk;

  @override
  Widget build(BuildContext context) {
    final level = risk.level as AlarmLevel;
    return Container(
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: level.textColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(level.icon, color: level.textColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Risk: ${level.label}',
                    style: AppTextStyles.cardTitle
                        .copyWith(color: level.textColor)),
                const SizedBox(height: 4),
                ...(risk.reasons as List<String>).map((r) => Text('• $r',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: level.textColor))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  const _SpecCard({this.imr});
  final dynamic imr;

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
              Text('Spesifikasyon — Nem', style: AppTextStyles.cardTitle),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _ST('LSL', '${SpecLimits.humidityLSL} %rH',
                  AppColors.chartBlue),
              _ST('Hedef', '${SpecLimits.humidityTarget} %rH',
                  AppColors.success),
              _ST('USL', '${SpecLimits.humidityUSL} %rH',
                  AppColors.chartBlue),
              if (imr != null)
                _ST('σ (IMR)',
                    (imr.sigmaEstimate as double).toStringAsFixed(4),
                    AppColors.primary),
            ]),
          ],
        ),
      );
}

class _ST extends StatelessWidget {
  const _ST(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style:
                  AppTextStyles.kpiValue.copyWith(fontSize: 16, color: color)),
          Text(label, style: AppTextStyles.kpiLabel),
        ]),
      );
}

class _DisconnectedPlaceholder extends StatelessWidget {
  const _DisconnectedPlaceholder();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Sunucuya Bağlı Değil', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 8),
            Text('Lütfen önce bir sunucuya bağlanın.',
                style: AppTextStyles.bodyMuted),
          ],
        ),
      );
}
