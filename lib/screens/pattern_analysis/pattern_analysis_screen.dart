import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../client/models/connection_status.dart';
import '../../client/providers/connection_provider.dart';
import '../../core/models/alarm_level.dart';
import '../../core/spc/nelson_rules.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/alarm_badge.dart';
import '../../widgets/section_header.dart';

class PatternAnalysisScreen extends StatelessWidget {
  const PatternAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, _) {
        if (conn.status != ConnectionStatus.connected) {
          return const _DisconnectedView();
        }
        return _PatternBody(conn: conn);
      },
    );
  }
}

class _PatternBody extends StatelessWidget {
  const _PatternBody({required this.conn});
  final ConnectionProvider conn;

  @override
  Widget build(BuildContext context) {
    final violations = conn.nelsonViolations;
    final imr = conn.humidityImr;
    final values = conn.humidityData.map((m) => m.value).toList();

    final level = violations.isEmpty ? AlarmLevel.low : AlarmLevel.high;

    // Pattern tiplerine göre grupla
    final patternGroups = _groupByPatternType(violations);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Pattern Analizi',
                  subtitle: 'Nelson 8 kural ihlal detayları ve pattern tipleri',
                  showDivider: true,
                ),
              ),
              const SizedBox(width: 12),
              AlarmBadge(level: level),
            ],
          ),
          const SizedBox(height: 16),

          // Özet
          _SummaryRow(violations: violations, n: values.length),
          const SizedBox(height: 20),

          // Pattern tipi kartları
          if (patternGroups.isNotEmpty) ...[
            const SectionHeader(
              title: 'Tespit Edilen Pattern Tipleri',
              subtitle: 'İstatistiksel anomali kategorileri',
            ),
            const SizedBox(height: 12),
            ...patternGroups.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PatternGroupCard(type: e.key, violations: e.value),
                )),
            const SizedBox(height: 12),
          ],

          // Tüm 8 kural detayları
          const SectionHeader(
            title: 'Nelson Kural Referansı',
            subtitle: '8 istatistiksel kontrol kuralının açıklamaları',
          ),
          const SizedBox(height: 12),
          _NelsonReferenceCard(
            violations: violations,
            values: values,
            mean: imr?.mean ?? 0,
            sigma: imr?.sigmaEstimate ?? 1,
          ),
        ],
      ),
    );
  }

  Map<String, List<NelsonViolation>> _groupByPatternType(
      List<NelsonViolation> violations) {
    final groups = <String, List<NelsonViolation>>{};
    for (final v in violations) {
      final type = _patternType(v.rule);
      groups.putIfAbsent(type, () => []).add(v);
    }
    return groups;
  }

  String _patternType(int rule) {
    switch (rule) {
      case 1: return 'Aşırı Değer';
      case 2: return 'Kayma / Offset';
      case 3: return 'Trend';
      case 4: return 'Ossilasyon';
      case 5:
      case 6: return 'Yayılma';
      case 7: return 'Katmanlaşma';
      case 8: return 'Karma Pattern';
      default: return 'Diğer';
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.violations, required this.n});
  final List<NelsonViolation> violations;
  final int n;

  @override
  Widget build(BuildContext context) {
    final totalAffected = violations.expand((v) => v.indices).toSet().length;
    final affectedRate = n > 0 ? totalAffected / n * 100 : 0.0;

    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 700 ? 3 : 1;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: c.maxWidth > 700 ? 2.8 : 4.0,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _Tile('Toplam İhlal', '${violations.length} kural',
              violations.isEmpty ? AppColors.success : AppColors.danger),
          _Tile('Etkilenen Nokta', '$totalAffected adet',
              totalAffected == 0 ? AppColors.success : AppColors.warning),
          _Tile('Etkilenme Oranı', '%${affectedRate.toStringAsFixed(1)}',
              affectedRate > 20 ? AppColors.danger : AppColors.textMuted),
        ],
      );
    });
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: Offset(0, 2))
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
                    .copyWith(fontSize: 18, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _PatternGroupCard extends StatelessWidget {
  const _PatternGroupCard({required this.type, required this.violations});
  final String type;
  final List<NelsonViolation> violations;

  @override
  Widget build(BuildContext context) {
    final totalPts = violations.expand((v) => v.indices).toSet().length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.alarmHighBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.alarmHighText.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.alarmHighText,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(type,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text('${violations.length} kural, $totalPts nokta',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          ...violations.map((v) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('K${v.rule}: ',
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.alarmHighText)),
                    Expanded(
                      child: Text(v.description,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _NelsonReferenceCard extends StatelessWidget {
  const _NelsonReferenceCard({
    required this.violations,
    required this.values,
    required this.mean,
    required this.sigma,
  });
  final List<NelsonViolation> violations;
  final List<double> values;
  final double mean;
  final double sigma;

  static const _rules = [
    (1, 'Aşırı Değer', '1 nokta |z| > 3σ dışında',
        'Olası ölçüm hatası veya proses kayması.'),
    (2, 'Kayma', '9 ardışık nokta ortalamanın aynı tarafında',
        'Proses ortalamasında kalıcı kayma.'),
    (3, 'Trend', '6 ardışık nokta sürekli artıyor veya azalıyor',
        'Yavaş proses sürüklenmesi / aşınma.'),
    (4, 'Ossilasyon', '14 ardışık nokta zigzag',
        'İki süreç arasında alternatif geçiş.'),
    (5, 'Yayılma 2σ', '3\'te 2, aynı tarafta ±2σ dışı',
        'Varyasyon artışı veya çift tepe dağılımı.'),
    (6, 'Yayılma 1σ', '5\'te 4, aynı tarafta ±1σ dışı',
        'Süreç kayması ya da yayılma artışı.'),
    (7, 'Katmanlaşma', '15 ardışık nokta ±1σ içinde',
        'Yapay olarak düşük varyasyon — sensör problemi?'),
    (8, 'Karma', '8 ardışık nokta ±1σ dışı (iki taraf)',
        'İki ayrı dağılım veya karışık popülasyon.'),
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
          BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: _rules.asMap().entries.map((entry) {
          final (ruleNum, type, rule, meaning) = entry.value;
          final violation = violatedRules[ruleNum];
          final violated = violation != null;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: violated
                  ? AppColors.alarmHighBg
                  : entry.key.isEven
                      ? AppColors.background.withValues(alpha: 0.5)
                      : AppColors.cardBg,
              border: Border(
                bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              borderRadius: entry.key == _rules.length - 1
                  ? const BorderRadius.vertical(bottom: Radius.circular(12))
                  : BorderRadius.zero,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: violated
                        ? AppColors.alarmHighText
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('K$ruleNum',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: violated ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('$type — ',
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: violated
                                      ? AppColors.alarmHighText
                                      : AppColors.textPrimary)),
                          Expanded(
                            child: Text(rule,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textPrimary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(meaning,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                      if (violated) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${violation.indices.length} nokta ihlalde — '
                          '${violation.indices.take(8).join(", ")}'
                          '${violation.indices.length > 8 ? "..." : ""}',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.alarmHighText,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                if (violated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.alarmHighText,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('İHLAL',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10)),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
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
