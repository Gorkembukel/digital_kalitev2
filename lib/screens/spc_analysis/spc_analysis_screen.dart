import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../client/models/connection_status.dart';
import '../../client/providers/connection_provider.dart';
import '../../core/models/alarm_level.dart';
import '../../core/spc/nelson_rules.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/alarm_badge.dart';
import '../../widgets/charts/imr_chart.dart';

class SpcAnalysisScreen extends StatelessWidget {
  const SpcAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, _) {
        if (conn.status != ConnectionStatus.connected) {
          return _buildDisconnected();
        }
        return _SpcAnalysisBody(conn: conn);
      },
    );
  }

  Widget _buildDisconnected() => const Center(
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

class _SpcAnalysisBody extends StatelessWidget {
  const _SpcAnalysisBody({required this.conn});
  final ConnectionProvider conn;

  @override
  Widget build(BuildContext context) {
    final imr = conn.humidityImr;
    final violations = conn.nelsonViolations;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'SPC Analizi',
                  subtitle: 'I-MR kontrol diyagramı ve Nelson 8 kural kontrolü',
                  showDivider: true,
                ),
              ),
              const SizedBox(width: 12),
              AlarmBadge(
                level: violations.isEmpty ? AlarmLevel.low : AlarmLevel.high,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Özet istatistikler
          if (imr != null) _StatsRow(imr: imr),
          const SizedBox(height: 20),

          // I-MR Grafiği
          if (imr != null)
            _Card(
              child: ImrChart(
                result: imr,
                title: 'Nem I-MR Kontrol Diyagramı',
                yAxisLabel: '%rH',
                maxPoints: 100,
                height: 460,
              ),
            )
          else
            const _NoDataCard(message: 'SPC grafiği için yeterli veri yok.'),

          const SizedBox(height: 24),

          // Nelson İhlalleri
          const SectionHeader(
            title: 'Nelson 8 Kural Analizi',
            subtitle: 'Tespit edilen istatistiksel pattern ihlalleri',
          ),
          const SizedBox(height: 12),
          _NelsonTable(violations: violations),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.imr});
  final dynamic imr;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 700 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StatTile('Ortalama (x̄)',
              '${(imr.mean as double).toStringAsFixed(4)} %rH',
              AppColors.centerLine),
          _StatTile('UCL',
              '${(imr.uclI as double).toStringAsFixed(4)} %rH',
              AppColors.controlLimitUpper),
          _StatTile('LCL',
              '${(imr.lclI as double).toStringAsFixed(4)} %rH',
              AppColors.controlLimitUpper),
          _StatTile('σ Tahmin',
              (imr.sigmaEstimate as double).toStringAsFixed(5),
              AppColors.primary),
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
                color: AppColors.shadowColor, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.kpiLabel),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.kpiValue.copyWith(
                    fontSize: 15, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _NelsonTable extends StatelessWidget {
  const _NelsonTable({required this.violations});
  final List<NelsonViolation> violations;

  static const _allRules = [
    (1, 'Bir nokta 3σ dışında', '|z| > 3'),
    (2, '9 ardışık aynı tarafta', 'Kayma / offset'),
    (3, '6 ardışık monoton', 'Trend / eğilim'),
    (4, '14 ardışık zigzag', 'Ossilasyon'),
    (5, '3\'te 2, ±2σ dışı (aynı taraf)', 'Yayılma'),
    (6, '5\'te 4, ±1σ dışı (aynı taraf)', 'Yayılma'),
    (7, '15 ardışık ±1σ içinde', 'Katmanlaşma'),
    (8, '8 ardışık ±1σ dışı (iki taraf)', 'Karma'),
  ];

  @override
  Widget build(BuildContext context) {
    final violatedRules = {for (final v in violations) v.rule: v};

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
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _HeaderCell('Kural', flex: 1),
                _HeaderCell('Açıklama', flex: 4),
                _HeaderCell('Tip', flex: 2),
                _HeaderCell('Durum', flex: 2),
                _HeaderCell('İhlal Sayısı', flex: 2),
              ],
            ),
          ),

          // Rule rows
          ..._allRules.asMap().entries.map((entry) {
            final (ruleNum, desc, type) = entry.value;
            final isEven = entry.key.isEven;
            final violation = violatedRules[ruleNum];
            final violated = violation != null;

            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: violated
                  ? AppColors.alarmHighBg
                  : (isEven
                      ? AppColors.background.withValues(alpha: 0.5)
                      : AppColors.cardBg),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text('K$ruleNum',
                        style: AppTextStyles.cardTitle.copyWith(
                            color: AppColors.primary, fontSize: 13)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(desc,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(type,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                  ),
                  Expanded(
                    flex: 2,
                    child: violated
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.alarmHighText.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.alarmHighText
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Text('İHLAL',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.alarmHighText,
                                    fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.alarmLowBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.alarmLowText
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Text('Normal',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.alarmLowText),
                                textAlign: TextAlign.center),
                          ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      violated ? '${violation.indices.length} nokta' : '—',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: violated
                              ? AppColors.alarmHighText
                              : AppColors.textMuted),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Footer summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  violations.isEmpty
                      ? 'Süreç kontrol altında — aktif Nelson ihlali yok.'
                      : '${violations.length} kural ihlali tespit edildi. '
                          'İhlalli noktalar: ${violations.expand((v) => v.indices).toSet().length} adet.',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: violations.isEmpty
                          ? AppColors.textMuted
                          : AppColors.alarmHighText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
        ),
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

class _NoDataCard extends StatelessWidget {
  const _NoDataCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(message,
            style: AppTextStyles.bodyMuted
                .copyWith(color: AppColors.textMuted)),
      );
}

// ignore: unused_element
String _fmtTime(DateTime dt) => DateFormat('HH:mm:ss').format(dt);
