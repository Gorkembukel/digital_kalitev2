import 'package:flutter/material.dart';

/// NavigationRail / BottomNav için tek bir menü öğesi.
class NavItem {
  const NavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.tooltip,
  });

  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String tooltip;
}

/// 10 ekranın navigasyon listesi.
abstract final class AppNavItems {
  static const List<NavItem> items = [
    NavItem(
      index: 0,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      tooltip: 'Ana Dashboard',
    ),
    NavItem(
      index: 1,
      label: 'Veri Sağlık',
      icon: Icons.health_and_safety_outlined,
      activeIcon: Icons.health_and_safety_rounded,
      tooltip: 'Veri Sağlık Analizi',
    ),
    NavItem(
      index: 2,
      label: 'SPC Analiz',
      icon: Icons.show_chart_outlined,
      activeIcon: Icons.show_chart_rounded,
      tooltip: 'SPC Analizi',
    ),
    NavItem(
      index: 3,
      label: 'Kapasite',
      icon: Icons.speed_outlined,
      activeIcon: Icons.speed_rounded,
      tooltip: 'Kapasite Analizi',
    ),
    NavItem(
      index: 4,
      label: 'Alarmlar',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      tooltip: 'Alarm Merkezi',
    ),
    NavItem(
      index: 5,
      label: 'Pattern',
      icon: Icons.pattern_outlined,
      activeIcon: Icons.pattern_rounded,
      tooltip: 'Pattern Analizi',
    ),
    NavItem(
      index: 6,
      label: 'Erken Uyarı',
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up_rounded,
      tooltip: 'Erken Uyarı Sistemi',
    ),
    NavItem(
      index: 7,
      label: 'Deform SPC',
      icon: Icons.straighten_outlined,
      activeIcon: Icons.straighten_rounded,
      tooltip: 'Deformasyon SPC',
    ),
    NavItem(
      index: 8,
      label: 'Nem SPC',
      icon: Icons.water_drop_outlined,
      activeIcon: Icons.water_drop_rounded,
      tooltip: 'Nem SPC (Kapsamlı)',
    ),
    NavItem(
      index: 9,
      label: 'Tabaka',
      icon: Icons.layers_outlined,
      activeIcon: Icons.layers_rounded,
      tooltip: 'Tabakalama Analizi',
    ),
  ];
}
