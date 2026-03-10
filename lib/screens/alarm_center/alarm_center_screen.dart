import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../client/models/connection_status.dart';
import '../../client/providers/connection_provider.dart';
import '../../core/constants/spec_limits.dart';
import '../../core/models/alarm_level.dart';
import '../../core/spc/nelson_rules.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/alarm_badge.dart';
import '../../widgets/section_header.dart';

class AlarmCenterScreen extends StatelessWidget {
  const AlarmCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, _) {
        if (conn.status != ConnectionStatus.connected) {
          return const _DisconnectedView();
        }
        return _AlarmCenterBody(conn: conn);
      },
    );
  }
}

class _AlarmCenterBody extends StatelessWidget {
  const _AlarmCenterBody({required this.conn});
  final ConnectionProvider conn;

  @override
  Widget build(BuildContext context) {
    final violations = conn.nelsonViolations;
    final risk = conn.humidityRisk;
    final data = conn.humidityData;

    final recentData = data.length > 50 ? data.sublist(data.length - 50) : data;
    final oobPoints = recentData
        .where((m) => !SpecLimits.isHumidityInSpec(m.value))
        .toList();

    final overallLevel = risk?.level ?? AlarmLevel.low;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Alarm Merkezi',
                  subtitle: 'Tolerans dışı noktalar ve Nelson kural ihlalleri',
                  showDivider: true,
                ),
              ),
              const SizedBox(width: 12),
              AlarmBadge(level: overallLevel),
            ],
          ),
          const SizedBox(height: 16),

          LayoutBuilder(builder: (_, c) {
            final cols = c.maxWidth > 700 ? 3 : 1;
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: c.maxWidth > 700 ? 2.8 : 4.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SummaryTile(
                  icon: Icons.rule_rounded,
                  label: 'Nelson İhlali',
                  value: '${violations.length}',
                  level: violations.isEmpty ? AlarmLevel.low : AlarmLevel.high,
                ),
                _SummaryTile(
                  icon: Icons.warning_amber_rounded,
                  label: 'Spec Dışı (son 50)',
                  value: '${oobPoints.length}',
                  level: oobPoints.isEmpty ? AlarmLevel.low : AlarmLevel.critical,
                ),
                _SummaryTile(
                  icon: Icons.thermostat_rounded,
                  label: 'Risk Seviyesi',
                  value: overallLevel.label,
                  level: overallLevel,
                ),
              ],
            );
          }),
          const SizedBox(height: 24),

          if (risk != null && risk.reasons.isNotEmpty) ...[
            const SectionHeader(title: 'Risk Analizi'),
            const SizedBox(height: 10),
            _RiskReasonsCard(risk: risk),
            const SizedBox(height: 24),
          ],

          const SectionHeader(
            title: 'Tolerans Dışı Noktalar',
            subtitle: 'Son 50 ölçüm içindeki spec dışı değerler',
          ),
          const SizedBox(height: 10),
          oobPoints.isEmpty
              ? const _GreenCard('Son 50 ölçümde tolerans dışı nokta yok.')
              : _OobTable(points: oobPoints),
          const SizedBox(height: 24),

          const SectionHeader(
            title: 'Nelson Kural İhlalleri',
            subtitle: 'Tespit edilen istatistiksel anomaliler',
          ),
          const SizedBox(height: 10),
          violations.isEmpty
              ? const _GreenCard('Aktif Nelson kural ihlali yok.')
              : _NelsonDetailList(violations: violations),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.level,
  });
  final IconData icon;
  final String label, value;
  final AlarmLevel level;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: level.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: level.textColor.withValues(alpha: 0.25)),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: level.textColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: AppTextStyles.kpiLabel.copyWith(
                          color: level.textColor.withValues(alpha: 0.7))),
                  Text(value,
                      style: AppTextStyles.kpiValue
                          .copyWith(color: level.textColor, fontSize: 22)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _RiskReasonsCard extends StatelessWidget {
  const _RiskReasonsCard({required this.risk});
  final dynamic risk;

  @override
  Widget build(BuildContext context) {
    final level = risk.level as AlarmLevel;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: level.textColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(level.icon, color: level.textColor, size: 20),
              const SizedBox(width: 8),
              Text('Risk: ${level.label}',
                  style: AppTextStyles.cardTitle.copyWith(color: level.textColor)),
            ],
          ),
          const SizedBox(height: 8),
          ...(risk.reasons as List<String>).map((r) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, color: level.textColor, size: 6),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(r,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: level.textColor)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _OobTable extends StatelessWidget {
  const _OobTable({required this.points});
  final List<dynamic> points;

  @override
  Widget build(BuildContext context) {
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
                _H('Değer (%rH)', flex: 2),
                _H('Sapma', flex: 2),
                _H('Durum', flex: 2),
              ],
            ),
          ),
          ...points.asMap().entries.map((e) {
            final m = e.value;
            final val = m.value as double;
            final ts = m.timestamp as DateTime;
            final overUSL = val > SpecLimits.humidityUSL;
            final deviation = overUSL
                ? val - SpecLimits.humidityUSL
                : SpecLimits.humidityLSL - val;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              color: e.key.isEven
                  ? AppColors.alarmCriticalBg.withValues(alpha: 0.4)
                  : AppColors.cardBg,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      DateFormat('HH:mm:ss dd/MM').format(ts),
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      val.toStringAsFixed(4),
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.alarmCriticalText,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${overUSL ? "+" : "-"}${deviation.toStringAsFixed(4)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.danger),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      overUSL ? '> USL' : '< LSL',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.alarmCriticalText,
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

class _NelsonDetailList extends StatelessWidget {
  const _NelsonDetailList({required this.violations});
  final List<NelsonViolation> violations;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: violations.map((v) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.alarmHighBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.alarmHighText.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.alarmHighText.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('K${v.rule}',
                      style: AppTextStyles.cardTitle.copyWith(
                          color: AppColors.alarmHighText, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.description,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${v.indices.length} nokta etkilendi — indeksler: '
                      '${v.indices.take(10).join(", ")}${v.indices.length > 10 ? "..." : ""}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              AlarmBadge(level: AlarmLevel.high, compact: true),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _GreenCard extends StatelessWidget {
  const _GreenCard(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.alarmLowBg,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.alarmLowText.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.alarmLowText, size: 20),
            const SizedBox(width: 10),
            Text(message,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.alarmLowText)),
          ],
        ),
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
