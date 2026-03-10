import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../client/models/connection_status.dart';
import '../../client/providers/connection_provider.dart';
import '../../core/constants/spec_limits.dart';
import '../../core/models/alarm_level.dart';
import '../../core/spc/risk_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/alarm_badge.dart';
import '../../widgets/section_header.dart';

class DataHealthScreen extends StatelessWidget {
  const DataHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, _) {
        if (conn.status != ConnectionStatus.connected) {
          return const _DisconnectedView();
        }
        return _DataHealthBody(conn: conn);
      },
    );
  }
}

class _DataHealthBody extends StatelessWidget {
  const _DataHealthBody({required this.conn});
  final ConnectionProvider conn;

  @override
  Widget build(BuildContext context) {
    final humData = conn.humidityData;
    final defData = conn.deformationData;
    final values = humData.map((m) => m.value).toList();

    final humStats = values.isNotEmpty ? SummaryStats.fromValues(values) : null;
    final humOob = values.isNotEmpty
        ? RiskCalculator.oobRate(values,
            lsl: SpecLimits.humidityLSL, usl: SpecLimits.humidityUSL)
        : 0.0;

    // Veri sağlık skoru (0-100)
    final score = _calcScore(humData.length, defData.length, humOob);
    final scoreLevel = score >= 80
        ? AlarmLevel.low
        : score >= 60
            ? AlarmLevel.medium
            : score >= 40
                ? AlarmLevel.high
                : AlarmLevel.critical;

    // Zaman aralığı
    final firstHum = humData.isNotEmpty ? humData.first.timestamp : null;
    final lastHum = humData.isNotEmpty ? humData.last.timestamp : null;
    final duration = (firstHum != null && lastHum != null)
        ? lastHum.difference(firstHum)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Veri Sağlık Analizi',
                  subtitle: 'Veri kalite skoru ve bütünlük kontrolü',
                  showDivider: true,
                ),
              ),
              const SizedBox(width: 12),
              AlarmBadge(level: scoreLevel),
            ],
          ),
          const SizedBox(height: 16),

          // Skor kartı
          _ScoreCard(score: score, level: scoreLevel),
          const SizedBox(height: 20),

          // Sayım özeti
          LayoutBuilder(builder: (_, c) {
            final cols = c.maxWidth > 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Tile('Nem Ölçümü', '${humData.length}', AppColors.primary,
                    icon: Icons.water_drop_outlined),
                _Tile('Deformasyon', '${defData.length}', AppColors.info,
                    icon: Icons.straighten_rounded),
                _Tile('Veri bozukluk Oranı', '%${(humOob * 100).toStringAsFixed(2)}',
                    humOob > 0.05 ? AppColors.danger : AppColors.success,
                    icon: Icons.warning_amber_rounded),
                _Tile(
                    'Veri Süresi',
                    duration != null ? _fmtDuration(duration) : '—',
                    AppColors.primary,
                    icon: Icons.timer_outlined),
              ],
            );
          }),
          const SizedBox(height: 24),

          // İstatistik detayları
          if (humStats != null) ...[
            const SectionHeader(
                title: 'Nem İstatistikleri', subtitle: 'Tüm yüklü veri üzerinde'),
            const SizedBox(height: 12),
            _StatsTable(stats: humStats, firstTs: firstHum, lastTs: lastHum),
            const SizedBox(height: 24),
          ],

          // Deformasyon özeti
          if (defData.isNotEmpty) ...[
            const SectionHeader(title: 'Deformasyon Özeti'),
            const SizedBox(height: 12),
            _DefSummary(data: defData),
            const SizedBox(height: 24),
          ],

          // Bağlantı bilgisi
          _ConnectionCard(conn: conn),
        ],
      ),
    );
  }

  int _calcScore(int humCount, int defCount, double oobRate) {
    int score = 100;
    if (humCount < 10) {
      score -= 30;
    } else if (humCount < 30) {
      score -= 15;
    }
    if (defCount < 5) score -= 15;
    score -= (oobRate * 200).round().clamp(0, 40);
    return score.clamp(0, 100);
  }

  String _fmtDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}g ${d.inHours.remainder(24)}s';
    if (d.inHours > 0) return '${d.inHours}s ${d.inMinutes.remainder(60)}dk';
    return '${d.inMinutes}dk';
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.level});
  final int score;
  final AlarmLevel level;

  @override
  Widget build(BuildContext context) => Container(
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
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 7,
                    backgroundColor: level.textColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(level.textColor),
                  ),
                  Text('$score',
                      style: AppTextStyles.kpiValue
                          .copyWith(color: level.textColor, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Veri Sağlık Skoru',
                      style: AppTextStyles.kpiLabel
                          .copyWith(color: level.textColor.withValues(alpha: 0.7))),
                  Text('$score / 100',
                      style: AppTextStyles.sectionHeader
                          .copyWith(color: level.textColor, fontSize: 20)),
                  Text(
                    score >= 80
                        ? 'Mükemmel — veri güvenilir.'
                        : score >= 60
                            ? 'İyi — küçük iyileştirme gerekebilir.'
                            : score >= 40
                                ? 'Zayıf — veri kalitesi düşük.'
                                : 'Kritik — veriyi inceleyin!',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: level.textColor.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.color, {required this.icon});
  final String label, value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: AppTextStyles.kpiLabel),
                  Text(value,
                      style: AppTextStyles.kpiValue
                          .copyWith(fontSize: 15, color: color, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StatsTable extends StatelessWidget {
  const _StatsTable({required this.stats, this.firstTs, this.lastTs});
  final SummaryStats stats;
  final DateTime? firstTs;
  final DateTime? lastTs;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm:ss');
    final rows = [
      ('n (Ölçüm Sayısı)', '${stats.count}'),
      ('Ortalama (x̄)', '${stats.mean.toStringAsFixed(5)} %rH'),
      ('Std. Sapma (σ)', stats.stddev.toStringAsFixed(5)),
      ('Min Değer', '${stats.min.toStringAsFixed(4)} %rH'),
      ('Max Değer', '${stats.max.toStringAsFixed(4)} %rH'),
      ('Aralık (Max-Min)', '${(stats.max - stats.min).toStringAsFixed(4)} %rH'),
      if (firstTs != null) ('İlk Ölçüm', fmt.format(firstTs!)),
      if (lastTs != null) ('Son Ölçüm', fmt.format(lastTs!)),
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
        children: rows.asMap().entries.map((e) {
          final (label, value) = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: e.key.isEven
                  ? AppColors.background.withValues(alpha: 0.5)
                  : AppColors.cardBg,
              borderRadius: e.key == rows.length - 1
                  ? const BorderRadius.vertical(bottom: Radius.circular(12))
                  : BorderRadius.zero,
              border: Border(
                  bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(label,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 4,
                  child: Text(value,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DefSummary extends StatelessWidget {
  const _DefSummary({required this.data});
  final List<dynamic> data;

  @override
  Widget build(BuildContext context) {
    final avgs = data.map((m) => m.average as double).toList();
    final stats = SummaryStats.fromValues(avgs);
    final oobVitra =
        data.where((m) => !SpecLimits.isDeformVitraInSpec(m.average as double)).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(spacing: 28, runSpacing: 12, children: [
        _DS('Ölçüm Sayısı', '${data.length}', AppColors.primary),
        _DS('Ort. Deformasyon', '${stats.mean.toStringAsFixed(3)} mm', AppColors.info),
        _DS('Min / Max', '${stats.min.toStringAsFixed(3)} / ${stats.max.toStringAsFixed(3)} mm', AppColors.textMuted),
        _DS('VitrA Dışı', '$oobVitra', oobVitra > 0 ? AppColors.danger : AppColors.success),
      ]),
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
          Text(label, style: AppTextStyles.kpiLabel),
          Text(value,
              style: AppTextStyles.kpiValue.copyWith(fontSize: 15, color: color)),
        ],
      );
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.conn});
  final ConnectionProvider conn;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.alarmLowBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.alarmLowText.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_done_rounded,
                color: AppColors.alarmLowText, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bağlantı Durumu',
                      style: AppTextStyles.kpiLabel
                          .copyWith(color: AppColors.alarmLowText.withValues(alpha: 0.7))),
                  Text(conn.serverUrl,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.alarmLowText, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: conn.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Yenile'),
              style: TextButton.styleFrom(foregroundColor: AppColors.alarmLowText),
            ),
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
