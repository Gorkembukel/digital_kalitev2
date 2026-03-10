import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/models/alarm_level.dart';

/// KPI kartı — sol 4px renkli dikey şerit, hover animasyon.
///
/// Kullanım:
/// ```dart
/// KpiCard(
///   label: 'Ort. Nem',
///   value: '6.12 %rH',
///   sub: 'Son 60 ölçüm',
///   level: AlarmLevel.low,
/// )
/// ```
class KpiCard extends StatefulWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.level = AlarmLevel.low,
    this.icon,
    this.onTap,
    this.width,
    this.height,
  });

  /// Üst etiket (küçük, muted).
  final String label;

  /// Ana değer (büyük, bold).
  final String value;

  /// Alt açıklama (küçük, muted). Opsiyonel.
  final String? sub;

  /// Alarm seviyesi — sol şerit rengini ve durumunu belirler.
  final AlarmLevel level;

  /// Sağ üst köşe ikonu. Opsiyonel.
  final IconData? icon;

  /// Karta dokunulduğunda tetiklenir. Opsiyonel.
  final VoidCallback? onTap;

  final double? width;
  final double? height;

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _elevation;
  late final Animation<Offset> _offset;

  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _elevation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _offset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -3),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onEnter() {
    setState(() => _hovering = true);
    _ctrl.forward();
  }

  void _onExit() {
    setState(() => _hovering = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final stripColor = widget.level.stripColor;

    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.translate(
            offset: _offset.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 2 + _elevation.value,
                      offset: Offset(0, 2 + _elevation.value * 0.5),
                      spreadRadius: _hovering ? 1 : 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Sol renkli şerit (4px) ──────────────
                        Container(
                          width: 4,
                          color: stripColor,
                        ),

                        // ── İçerik ─────────────────────────────
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Label + ikon satırı
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.label,
                                        style: AppTextStyles.kpiLabel,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget.icon != null) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        widget.icon,
                                        size: 18,
                                        color: stripColor,
                                      ),
                                    ],
                                  ],
                                ),

                                const SizedBox(height: 6),

                                // Ana değer
                                Text(
                                  widget.value,
                                  style: AppTextStyles.kpiValue.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),

                                // Alt açıklama
                                if (widget.sub != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.sub!,
                                    style: AppTextStyles.kpiSub,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
