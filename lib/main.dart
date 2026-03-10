import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'client/providers/connection_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/models/app_mode.dart';
import 'screens/server_mode/server_mode_screen.dart';
import 'screens/connection/connection_screen.dart';

void main() {
  runApp(const DigitalKaliteApp());
}

class DigitalKaliteApp extends StatelessWidget {
  const DigitalKaliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitrA Karo SPC Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ModeSelectionScreen(),
    );
  }
}

/// Uygulama başlangıcında Server veya Client modunu seçen ekran.
class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  void _selectMode(BuildContext context, AppMode mode) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => switch (mode) {
          // Client: ConnectionProvider tüm client ekranlarını sarar
          AppMode.client => ChangeNotifierProvider(
              create: (_) => ConnectionProvider(),
              child: const ConnectionScreen(),
            ),
          AppMode.server => const ServerModeScreen(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.factory_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'VitrA Karo',
                  style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  'SPC Kalite Kontrol Dashboard',
                  style: AppTextStyles.bodyMuted.copyWith(color: const Color(0xFF8BADD4), fontSize: 15),
                ),
                const SizedBox(height: 48),

                _ModeCard(mode: AppMode.server, icon: Icons.dns_rounded, onSelect: () => _selectMode(context, AppMode.server)),
                const SizedBox(height: 16),
                _ModeCard(mode: AppMode.client, icon: Icons.monitor_rounded, onSelect: () => _selectMode(context, AppMode.client)),

                const SizedBox(height: 32),
                Text(
                  'Eczacıbaşı — VitrA Karo Üretim Kalite Sistemi',
                  style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF4A6F9F)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatefulWidget {
  const _ModeCard({required this.mode, required this.icon, required this.onSelect});

  final AppMode mode;
  final IconData icon;
  final VoidCallback onSelect;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isServer = widget.mode == AppMode.server;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovering
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovering ? AppColors.accent : Colors.white.withValues(alpha: 0.15),
              width: _hovering ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isServer
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.info.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  color: isServer ? AppColors.accent : AppColors.info,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mode.label,
                      style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.mode.description,
                      style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF8BADD4)),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: _hovering ? AppColors.accent : const Color(0xFF4A6F9F),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

