import 'package:flutter/material.dart';
import '../core/models/alarm_level.dart';
import '../core/theme/app_text_styles.dart';

/// Alarm seviyesini gösteren renkli badge.
///
/// Kullanım:
/// ```dart
/// AlarmBadge(level: AlarmLevel.critical)
/// AlarmBadge(level: AlarmLevel.high, label: 'YÜKSEK')
/// ```
class AlarmBadge extends StatelessWidget {
  const AlarmBadge({
    super.key,
    required this.level,
    this.label,
    this.showIcon = true,
    this.compact = false,
  });

  final AlarmLevel level;

  /// Özel etiket. Null ise [AlarmLevel.label] kullanılır.
  final String? label;

  /// İkon gösterilsin mi?
  final bool showIcon;

  /// Kompakt mod — sadece nokta + etiket.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = label ?? level.label;
    final bg = level.backgroundColor;
    final fg = level.textColor;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: AppTextStyles.label.copyWith(color: fg, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(level.icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: AppTextStyles.label.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// Alarm sayacı — örn. "3 Kritik" gibi.
class AlarmCountBadge extends StatelessWidget {
  const AlarmCountBadge({
    super.key,
    required this.level,
    required this.count,
  });

  final AlarmLevel level;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return AlarmBadge(
      level: level,
      label: '$count ${level.label}',
      showIcon: true,
    );
  }
}
