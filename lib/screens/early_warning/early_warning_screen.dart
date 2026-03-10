import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../client/models/connection_status.dart';
import '../../client/providers/connection_provider.dart';
import '../../core/constants/spec_limits.dart';
import '../../core/models/alarm_level.dart';
import '../../core/spc/risk_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/alarm_badge.dart';
import '../../widgets/section_header.dart';

class EarlyWarningScreen extends StatelessWidget {
  const EarlyWarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, _) {
        if (conn.status != ConnectionStatus.connected) {
          return const _DisconnectedView();
        }
        return _EarlyWarningBody(conn: conn);
      },
    );
  }
}

class _EarlyWarningBody extends StatelessWidget {
  const _EarlyWarningBody({required this.conn});
  final ConnectionProvider conn;

  @override
  Widget build(BuildContext context) {
    final risk = conn.humidityRisk;
    final values = conn.humidityData.map((m) => m.value).toList();
    final level = risk?.level ?? AlarmLevel.low;

    // Window-based OOB rates
    final oob10 = values.length >= 10
        ? RiskCalculator.oobRate(values.sublist(values.length - 10),
            lsl: SpecLimits.humidityLSL, usl: SpecLimits.humidityUSL)
        : 0.0;
    final oob30 = values.length >= 30
        ? RiskCalculator.oobRate(values.sublist(values.length - 30),
            lsl: SpecLimits.humidityLSL, usl: SpecLimits.humidityUSL)
        : 0.0;
    final oob60 = values.isNotEmpty
        ? RiskCalculator.oobRate(
            values.length > 60 ? values.sublist(values.length - 60) : values,
            lsl: SpecLimits.humidityLSL, usl: SpecLimits.humidityUSL)
        : 0.0;

    // Trend slopes
    final trend10 = values.length >= 5
        ? RiskCalculator.trendSlope(values, windowSize: 10)
        : 0.0;
    final trend30 = values.length >= 5
        ? RiskCalculator.trendSlope(values, windowSize: 30)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Erken Uyarı Sistemi',
                  subtitle: 'Trend analizi ve risk tahmini',
                  showDivider: true,
                ),
              ),
              const SizedBox(width: 12),
              AlarmBadge(level: level),
            ],
          ),
          const SizedBox(height: 16),

          // Genel risk durumu
          if (risk != null) _RiskOverviewCard(risk: risk),
          const SizedBox(height: 20),

          // Pencere bazlı OOB oran kartları
          const SectionHeader(
            title: 'Tolerans Dışı Oran Analizi',
            subtitle: 'Farklı zaman pencerelerinde OOB oranı',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (_, c) {
            final cols = c.maxWidth > 700 ? 3 : 1;
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: c.maxWidth > 700 ? 2.2 : 3.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _OobCard('Son 10 Ölçüm', oob10, 'Anlık durum'),
                _OobCard('Son 30 Ölçüm', oob30, 'Kısa dönem'),
                _OobCard('Son 60 Ölçüm', oob60, 'Uzun dönem'),
              ],
            );
          }),
          const SizedBox(height: 24),

          // Trend analizi
          const SectionHeader(
            title: 'Trend Analizi',
            subtitle: 'Doğrusal regresyon eğimi',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (_, c) {
            final cols = c.maxWidth > 700 ? 2 : 1;
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: c.maxWidth > 700 ? 2.8 : 4.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _TrendCard('Son 10 Ölçüm Eğimi', trend10),
                _TrendCard('Son 30 Ölçüm Eğimi', trend30),
              ],
            );
          }),
          const SizedBox(height: 24),

          // Uyarı kuralları
          _WarningRulesCard(),
          const SizedBox(height: 24),

          // Öneriler
          if (risk != null) _RecommendationsCard(risk: risk),
        ],
      ),
    );
  }
}

class _RiskOverviewCard extends StatelessWidget {
  const _RiskOverviewCard({required this.risk});
  final dynamic risk;

  @override
  Widget build(BuildContext context) {
    final level = risk.level as AlarmLevel;
    final oobRate = (risk.oobRate as double) * 100;
    final trend = risk.trend as double;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: level.textColor.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(level.icon, color: level.textColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Risk Seviyesi: ${level.label}',
                    style: AppTextStyles.sectionHeader
                        .copyWith(color: level.textColor, fontSize: 16)),
                const SizedBox(height: 6),
                Wrap(spacing: 24, children: [
                  _InfoChip('OOB Oran: %${oobRate.toStringAsFixed(1)}', level.textColor),
                  _InfoChip(
                      'Trend: ${trend >= 0 ? "+" : ""}${trend.toStringAsFixed(5)}',
                      level.textColor),
                  _InfoChip('Nelson: ${(risk.nelsonViolationCount as int)} ihlal',
                      level.textColor),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: AppTextStyles.bodySmall
                .copyWith(color: color, fontWeight: FontWeight.w600)),
      );
}

class _OobCard extends StatelessWidget {
  const _OobCard(this.title, this.rate, this.subtitle);
  final String title, subtitle;
  final double rate;

  @override
  Widget build(BuildContext context) {
    AlarmLevel level;
    if (rate > SpecLimits.riskOobCritical) {
      level = AlarmLevel.critical;
    } else if (rate > SpecLimits.riskOobHigh) {
      level = AlarmLevel.high;
    } else if (rate > SpecLimits.riskOobMedium) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: AppTextStyles.bodySmall
                  .copyWith(color: level.textColor.withValues(alpha: 0.7))),
          Text('%${(rate * 100).toStringAsFixed(2)}',
              style: AppTextStyles.kpiValue
                  .copyWith(color: level.textColor, fontSize: 24)),
          Text(subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: level.textColor.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard(this.title, this.slope);
  final String title;
  final double slope;

  @override
  Widget build(BuildContext context) {
    final isRising = slope > SpecLimits.riskTrendHigh;
    final isFalling = slope < -SpecLimits.riskTrendHigh;
    final isWarning = slope.abs() > SpecLimits.riskTrendCritical;

    final color = isWarning ? AppColors.danger : (isRising || isFalling) ? AppColors.warning : AppColors.success;
    final icon = slope > 0.0001
        ? Icons.trending_up_rounded
        : slope < -0.0001
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;
    final label = slope > 0.001
        ? 'Artış trendi'
        : slope < -0.001
            ? 'Azalış trendi'
            : 'Stabil';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: AppTextStyles.kpiLabel),
                Text('${slope >= 0 ? "+" : ""}${slope.toStringAsFixed(6)}',
                    style: AppTextStyles.kpiValue.copyWith(color: color, fontSize: 18)),
                Text(label,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningRulesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rules = [
      ('OOB > %15', 'Son 60 ölçümde tolerans dışı oran kritik eşiği aşıyor', AlarmLevel.critical),
      ('OOB > %5', 'Son 60 ölçümde tolerans dışı oran yüksek eşiği aşıyor', AlarmLevel.high),
      ('OOB > %1', 'Düşük düzey tolerans dışı kontaminasyon', AlarmLevel.medium),
      ('Trend |eğim| > 0.01', 'Hızlı artış veya düşüş trendi', AlarmLevel.critical),
      ('Trend |eğim| > 0.005', 'Orta düzey trend', AlarmLevel.high),
      ('Nelson ihlali', 'İstatistiksel pattern ihlali tespit edildi', AlarmLevel.medium),
    ];

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Uyarı Eşikleri',
                  style: AppTextStyles.cardTitle.copyWith(color: Colors.white)),
            ]),
          ),
          ...rules.asMap().entries.map((e) {
            final (rule, desc, level) = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: e.key.isEven
                  ? AppColors.background.withValues(alpha: 0.5)
                  : AppColors.cardBg,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: level.backgroundColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: level.textColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(level.label,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: level.textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rule,
                            style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600)),
                        Text(desc,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textMuted)),
                      ],
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

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.risk});
  final dynamic risk;

  @override
  Widget build(BuildContext context) {
    final level = risk.level as AlarmLevel;

    final List<String> recs = switch (level) {
      AlarmLevel.critical => [
          'Derhal üretimi durdurun ve proses parametrelerini kontrol edin.',
          'Nem kontrol sistemini ve sensörleri kalibre edin.',
          'Kalite müdürünü ve vardiya amirini bilgilendirin.',
          'Etkilenen parti için karantina uygulayın.',
        ],
      AlarmLevel.high => [
          'Nem kontrol sistemini yakından izleyin.',
          'Son 1 saatin ölçümlerini gözden geçirin.',
          'Sensör kalibrasyonunu kontrol edin.',
        ],
      AlarmLevel.medium => [
          'Nem trendini yakından takip edin.',
          'Bir sonraki vardiyada ekstra ölçüm alın.',
        ],
      AlarmLevel.low => [
          'Süreç kontrol altında. Rutin izlemeye devam edin.',
        ],
    };

    return Container(
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
            Text('Önerilen Aksiyonlar', style: AppTextStyles.cardTitle),
          ]),
          const SizedBox(height: 12),
          ...recs.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 10, top: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Expanded(
                      child: Text(e.value,
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
