import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../client/models/connection_status.dart';
import '../../client/providers/connection_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../app_navigation.dart';

/// Client modunda sunucuya bağlanma ekranı.
/// Bağlantı başarılı olunca AppNavigation'a geçer.
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _urlCtrl = TextEditingController(text: 'http://localhost:8080');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;
    final provider = ctx.read<ConnectionProvider>();
    await provider.connect(_urlCtrl.text.trim());

    if (!ctx.mounted) return;
    if (provider.status == ConnectionStatus.connected) {
      Navigator.of(ctx).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Consumer<ConnectionProvider>(
              builder: (ctx, provider, _) {
                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.monitor_rounded,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'İstemci Modu',
                        style: AppTextStyles.displayLarge
                            .copyWith(color: Colors.white, fontSize: 26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sunucu adresini girerek bağlanın',
                        style: AppTextStyles.bodyMuted
                            .copyWith(color: const Color(0xFF8BADD4)),
                      ),
                      const SizedBox(height: 40),

                      // URL girişi
                      TextFormField(
                        controller: _urlCtrl,
                        enabled: provider.status != ConnectionStatus.connecting,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Sunucu URL',
                          hintText: 'http://192.168.1.100:8080',
                          labelStyle: const TextStyle(
                              color: Color(0xFF8BADD4)),
                          hintStyle:
                              const TextStyle(color: Color(0xFF4A6F9F)),
                          prefixIcon: const Icon(Icons.dns_rounded,
                              color: Color(0xFF8BADD4)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFF2A4E7A)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.accent, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.danger),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.danger, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.07),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'URL boş olamaz';
                          }
                          if (!v.startsWith('http')) {
                            return 'http:// veya https:// ile başlamalı';
                          }
                          return null;
                        },
                      ),

                      // Hata mesajı
                      if (provider.status == ConnectionStatus.error &&
                          provider.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.alarmCriticalBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.alarmCriticalText,
                                  size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.errorMessage!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.alarmCriticalText),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Bağlan butonu
                      FilledButton.icon(
                        onPressed:
                            provider.status == ConnectionStatus.connecting
                                ? null
                                : () => _connect(ctx),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: provider.status ==
                                ConnectionStatus.connecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.link_rounded),
                        label: Text(
                          provider.status == ConnectionStatus.connecting
                              ? 'Bağlanıyor...'
                              : 'Bağlan',
                          style: AppTextStyles.button
                              .copyWith(color: Colors.white, fontSize: 15),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Geri butonu
                      TextButton(
                        onPressed:
                            provider.status == ConnectionStatus.connecting
                                ? null
                                : () => Navigator.of(context).pop(),
                        child: Text(
                          'Geri Dön',
                          style: AppTextStyles.bodyMuted
                              .copyWith(color: const Color(0xFF8BADD4)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
