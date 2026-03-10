import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Bölüm başlığı — 18px bold primary + accent alt çizgi 2px.
///
/// Kullanım:
/// ```dart
/// SectionHeader(title: 'SPC Analizi')
/// SectionHeader(title: 'Alarmlar', subtitle: 'Son 24 saat', trailing: IconButton(...))
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showDivider = true,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Accent rengi alt çizgi gösterilsin mi?
  final bool showDivider;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.sectionHeader),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTextStyles.bodyMuted),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (showDivider) ...[
            const SizedBox(height: 8),
            _AccentUnderline(),
          ],
        ],
      ),
    );
  }
}

class _AccentUnderline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ],
    );
  }
}

/// Kart içi küçük başlık (section header'dan daha küçük).
class CardHeader extends StatelessWidget {
  const CardHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Accent dikey çizgi
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: AppTextStyles.cardTitle),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
