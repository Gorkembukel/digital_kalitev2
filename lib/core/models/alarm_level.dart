import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Alarm seviyeleri (4 basamak).
enum AlarmLevel {
  critical,
  high,
  medium,
  low;

  String get label => switch (this) {
        AlarmLevel.critical => 'KRİTİK',
        AlarmLevel.high => 'YÜKSEK',
        AlarmLevel.medium => 'ORTA',
        AlarmLevel.low => 'DÜŞÜK',
      };

  Color get backgroundColor => switch (this) {
        AlarmLevel.critical => AppColors.alarmCriticalBg,
        AlarmLevel.high => AppColors.alarmHighBg,
        AlarmLevel.medium => AppColors.alarmMediumBg,
        AlarmLevel.low => AppColors.alarmLowBg,
      };

  Color get textColor => switch (this) {
        AlarmLevel.critical => AppColors.alarmCriticalText,
        AlarmLevel.high => AppColors.alarmHighText,
        AlarmLevel.medium => AppColors.alarmMediumText,
        AlarmLevel.low => AppColors.alarmLowText,
      };

  Color get stripColor => switch (this) {
        AlarmLevel.critical => AppColors.danger,
        AlarmLevel.high => AppColors.warning,
        AlarmLevel.medium => AppColors.warning,
        AlarmLevel.low => AppColors.success,
      };

  IconData get icon => switch (this) {
        AlarmLevel.critical => Icons.error_rounded,
        AlarmLevel.high => Icons.warning_rounded,
        AlarmLevel.medium => Icons.info_rounded,
        AlarmLevel.low => Icons.check_circle_rounded,
      };

  int get priority => switch (this) {
        AlarmLevel.critical => 4,
        AlarmLevel.high => 3,
        AlarmLevel.medium => 2,
        AlarmLevel.low => 1,
      };
}
