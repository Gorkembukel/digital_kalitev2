import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../client/models/connection_status.dart';
import '../../client/providers/connection_provider.dart';
import '../../core/constants/spec_limits.dart';
import '../../core/models/alarm_level.dart';
import '../../core/models/measurement.dart';
import '../../core/spc/imr_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/alarm_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/charts/imr_chart.dart';

class DeformationSpcScreen extends StatefulWidget {
  const DeformationSpcScreen({super.key});

  @override
  State<DeformationSpcScreen> createState() => _DeformationSpcScreenState();
}

class _DeformationSpcScreenState extends State<DeformationSpcScreen> {
  int _selectedPoint = 0; // 0=avg, 1-4=P1-P4

  static const _pointLabels = ['Ortalama', 'Nokta 1', 'Nokta 2', 'Nokta 3', 'Nokta 4'];

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, _) {
        if (conn.status != ConnectionStatus.connected) {
          return const _DisconnectedView();
        }
        return _Body(
          conn: conn,
          selectedPoint: _selectedPoint,
          pointLabels: _pointLabels,
          onPointChanged: (i) => setState(() => _selectedPoint = i),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.conn,
    required this.selectedPoint,
    required this.pointLabels,
    required this.onPointChanged,
  });
  final ConnectionProvider conn;
  final int selectedPoint;
  final List<String> pointLabels;
  final ValueChanged<int> onPointChanged;

  List<double> _vals(List<DeformationMeasurement> data) => data.map((m) {
        switch (selectedPoint) {
          case 1: return m.point1;
          case 2: return m.point2;
          case 3: return m.point3;
          case 4: return m.point4;
          default: return m.average;
        }
      }).toList();

  @override
  Widget build(BuildContext context) {
    final data = conn.deformationData;
    final values = _vals(data);

    ImrResult? imr;
    if (values.length >= 2) {
      imr = ImrCalculator.calculate(values);
    }

    final oobVitra = data.where((m) => !SpecLimits.isDeformVitraInSpec(m.average)).length;
    final oobEN = data.where((m) => !SpecLimits.isDeformEN14411InSpec(m.average)).length;
    final level = oobEN > 0
        ? AlarmLevel.critical
        : oobVitra > 0
            ? AlarmLevel.high
            : AlarmLevel.low;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Deformasyon SPC',
                  subtitle: '4 ölçüm noktası ve I-MR kontrol diyagramı',
                  showDivider: true,
                ),
              ),
              const SizedBox(width: 12),
              AlarmBadge(level: level),
            ],
          ),
          const SizedBox(height: 16),

          LayoutBuilder(builder: (_, c) {
            final cols = c.maxWidth > 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Tile('Ölçüm Sayısı', '${data.length}', AppColors.primary),
                _Tile('VitrA Spec Dışı', '$oobVitra',
                    oobVitra > 0 ? AppColors.danger : AppColors.success),
                _Tile('EN14411 Dışı', '$oobEN',
                    oobEN > 0 ? AppColors.danger : AppColors.success),
                data.isNotEmpty
                    ? _Tile('Son Ortalama', '${data.last.average.toStringAsFixed(3)} mm',
                        SpecLimits.isDeformVitraInSpec(data.last.average)
                            ? AppColors.success
                            : AppColors.danger)
                    : _Tile('Son Ortalama', '—', AppColors.textMuted),
              ],
            );
          }),
          const SizedBox(height: 20),

          _PointSelector(
              selected: selectedPoint, labels: pointLabels, onChanged: onPointChanged),
          const SizedBox(height: 12),

          imr != null
              ? _Card(
                  child: ImrChart(
                    result: imr,
                    title: 'Deformasyon I-MR — ${pointLabels[selectedPoint]}',
                    yAxisLabel: 'mm',
                    maxPoints: 80,
                    height: 440,
                  ),
                )
              : const _EmptyCard('I-MR grafiği için yeterli veri yok.'),
          const SizedBox(height: 24),

          _SpecCard(),
          const SizedBox(height: 24),

          const SectionHeader(title: 'Son Ölçümler'),
          const SizedBox(height: 10),
          data.isEmpty
              ? const _EmptyCard('Henüz deformasyon verisi yok.')
              : _DeformTable(
                  data: data.length > 20 ? data.sublist(data.length - 20) : data),
        ],
      ),
    );
  }
}

class _PointSelector extends StatelessWidget {
  const _PointSelector(
      {required this.selected, required this.labels, required this.onChanged});
  final int selected;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        children: labels.asMap().entries.map((e) {
          final on = e.key == selected;
          return InkWell(
            onTap: () => onChanged(e.key),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: on ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: on ? AppColors.primary : AppColors.border),
              ),
              child: Text(e.value,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: on ? Colors.white : AppColors.textMuted,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w400)),
            ),
          );
        }).toList(),
      );
}

class _SpecCard extends StatelessWidget {
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
              Text('Spesifikasyon Limitleri', style: AppTextStyles.cardTitle),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 32, runSpacing: 12, children: [
              _SI('VitrA LSL', '${SpecLimits.deformVitraLSL} mm', AppColors.accent),
              _SI('VitrA USL', '${SpecLimits.deformVitraUSL} mm', AppColors.accent),
              _SI('EN14411 LSL', '${SpecLimits.deformEN14411LSL} mm', AppColors.info),
              _SI('EN14411 USL', '${SpecLimits.deformEN14411USL} mm', AppColors.info),
            ]),
          ],
        ),
      );
}

class _SI extends StatelessWidget {
  const _SI(this.label, this.value, this.color);
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

class _DeformTable extends StatelessWidget {
  const _DeformTable({required this.data});
  final List<DeformationMeasurement> data;

  @override
  Widget build(BuildContext context) {
    final reversed = data.reversed.toList();
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
                _H('Zaman', flex: 3),
                _H('P1', flex: 1),
                _H('P2', flex: 1),
                _H('P3', flex: 1),
                _H('P4', flex: 1),
                _H('Ort.', flex: 2),
                _H('Aralık', flex: 2),
                _H('Durum', flex: 2),
              ],
            ),
          ),
          ...reversed.asMap().entries.map((e) {
            final m = e.value;
            final inSpec = SpecLimits.isDeformVitraInSpec(m.average);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              color: e.key.isEven
                  ? AppColors.background.withValues(alpha: 0.5)
                  : AppColors.cardBg,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      DateFormat('HH:mm\ndd/MM').format(m.timestamp),
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    ),
                  ),
                  ...[m.point1, m.point2, m.point3, m.point4].map((v) => Expanded(
                        flex: 1,
                        child: Text(v.toStringAsFixed(2),
                            style: AppTextStyles.bodySmall.copyWith(
                                color: SpecLimits.isDeformVitraInSpec(v)
                                    ? AppColors.textPrimary
                                    : AppColors.danger,
                                fontSize: 11)),
                      )),
                  Expanded(
                    flex: 2,
                    child: Text(m.average.toStringAsFixed(3),
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: inSpec
                                ? AppColors.textPrimary
                                : AppColors.alarmCriticalText)),
                  ),
                  Expanded(
                    flex: 2,
                    child:
                        Text(m.range.toStringAsFixed(3), style: AppTextStyles.bodySmall),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      inSpec ? 'OK' : 'DIŞI',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: inSpec
                              ? AppColors.alarmLowText
                              : AppColors.alarmCriticalText,
                          fontWeight: FontWeight.w700),
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
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.color);
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
                    .copyWith(fontSize: 15, color: color, fontWeight: FontWeight.w700)),
          ],
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
            BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))
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
