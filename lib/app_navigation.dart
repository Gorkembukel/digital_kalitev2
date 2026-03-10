import 'package:flutter/material.dart';
import 'core/models/nav_item.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';

// ── Ekranlar ──────────────────────────────────────────────────────────────────
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/data_health/data_health_screen.dart';
import 'screens/spc_analysis/spc_analysis_screen.dart';
import 'screens/capability/capability_screen.dart';
import 'screens/alarm_center/alarm_center_screen.dart';
import 'screens/pattern_analysis/pattern_analysis_screen.dart';
import 'screens/early_warning/early_warning_screen.dart';
import 'screens/deformation_spc/deformation_spc_screen.dart';
import 'screens/humidity_spc/humidity_spc_screen.dart';
import 'screens/stratification/stratification_screen.dart';

/// Ana navigasyon çerçevesi.
/// Masaüstü: NavigationRail (sol sabit, genişletilebilir)
/// Mobil   : Drawer
class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedIndex = 0;
  bool _railExtended = false;

  static const _breakpoint = 900.0; // masaüstü / mobil sınırı

  final List<Widget> _screens = [
    const DashboardScreen(),
    const DataHealthScreen(),
    const SpcAnalysisScreen(),
    const CapabilityScreen(),
    const AlarmCenterScreen(),
    const PatternAnalysisScreen(),
    const EarlyWarningScreen(),
    const DeformationSpcScreen(),
    const HumiditySpcScreen(),
    const StratificationScreen(),
  ];

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _breakpoint;

    if (isDesktop) {
      return _DesktopLayout(
        selectedIndex: _selectedIndex,
        extended: _railExtended,
        onDestinationSelected: _onDestinationSelected,
        onToggleExtend: () =>
            setState(() => _railExtended = !_railExtended),
        body: _screens[_selectedIndex],
      );
    }

    return _MobileLayout(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      body: _screens[_selectedIndex],
    );
  }
}

// ─── Desktop Layout ───────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.selectedIndex,
    required this.extended,
    required this.onDestinationSelected,
    required this.onToggleExtend,
    required this.body,
  });

  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onToggleExtend;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── NavigationRail ─────────────────────────────────────
          _AppNavigationRail(
            selectedIndex: selectedIndex,
            extended: extended,
            onDestinationSelected: onDestinationSelected,
            onToggleExtend: onToggleExtend,
          ),

          // ── İçerik ────────────────────────────────────────────
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _AppNavigationRail extends StatelessWidget {
  const _AppNavigationRail({
    required this.selectedIndex,
    required this.extended,
    required this.onDestinationSelected,
    required this.onToggleExtend,
  });

  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onToggleExtend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: NavigationRail(
        extended: extended,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: AppColors.primary,
        leading: _RailHeader(
          extended: extended,
          onToggle: onToggleExtend,
        ),
        trailing: const _RailTrailing(),
        destinations: AppNavItems.items.map((item) {
          return NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: Text(item.label),
            padding: const EdgeInsets.symmetric(vertical: 2),
          );
        }).toList(),
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.extended, required this.onToggle});

  final bool extended;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Logo / marka
          if (extended)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VitrA Karo',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'SPC Dashboard',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF8BADD4),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.factory_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),

          const SizedBox(height: 8),

          // Genişlet/daralt butonu
          IconButton(
            onPressed: onToggle,
            tooltip: extended ? 'Daralt' : 'Genişlet',
            icon: Icon(
              extended
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: const Color(0xFF8BADD4),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailTrailing extends StatelessWidget {
  const _RailTrailing();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: IconButton(
        onPressed: () {
          // Ayarlar ekranına git
        },
        tooltip: 'Ayarlar',
        icon: const Icon(
          Icons.settings_outlined,
          color: Color(0xFF8BADD4),
        ),
      ),
    );
  }
}

// ─── Mobile Layout ────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  // Mobilde sadece ilk 5 öğeyi göster; gerisine Drawer'dan ulaşılır
  static const _bottomItems = [0, 1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppNavItems.items[selectedIndex].tooltip),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: _MobileDrawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomItems.contains(selectedIndex)
            ? _bottomItems.indexOf(selectedIndex)
            : 0,
        onTap: (i) => onDestinationSelected(_bottomItems[i]),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primary,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: const Color(0xFF8BADD4),
        selectedLabelStyle: AppTextStyles.navLabel.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.navLabel,
        items: _bottomItems.map((i) {
          final item = AppNavItems.items[i];
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
            tooltip: item.tooltip,
          );
        }).toList(),
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primary,
      child: Column(
        children: [
          // Drawer header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF152E56),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.factory_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'VitrA Karo SPC',
                  style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
                ),
                Text(
                  'Kalite Kontrol Dashboard',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: const Color(0xFF8BADD4)),
                ),
              ],
            ),
          ),

          // Tüm 10 menü öğesi
          Expanded(
            child: ListView.builder(
              itemCount: AppNavItems.items.length,
              itemBuilder: (context, index) {
                final item = AppNavItems.items[index];
                final isSelected = selectedIndex == item.index;

                return ListTile(
                  leading: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected
                        ? AppColors.accent
                        : const Color(0xFF8BADD4),
                    size: 22,
                  ),
                  title: Text(
                    item.tooltip,
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: isSelected
                          ? AppColors.accent
                          : const Color(0xFF8BADD4),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  onTap: () {
                    Navigator.pop(context); // drawer'ı kapat
                    onDestinationSelected(item.index);
                  },
                );
              },
            ),
          ),

          const Divider(color: Color(0xFF2A4E7A), height: 1),
          ListTile(
            leading: const Icon(Icons.settings_outlined,
                color: Color(0xFF8BADD4)),
            title: Text(
              'Ayarlar',
              style: AppTextStyles.bodyRegular
                  .copyWith(color: const Color(0xFF8BADD4)),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
