import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/models/alarm_level.dart';
import '../../server/server_app.dart';
import '../../server/models/email_config.dart';
import '../../widgets/section_header.dart';

class ServerModeScreen extends StatelessWidget {
  const ServerModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SpcServerApp()..init(),
      child: const _ServerModeBody(),
    );
  }
}

class _ServerModeBody extends StatelessWidget {
  const _ServerModeBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sunucu Modu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer<SpcServerApp>(
            builder: (_, server, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: _StatusChip(status: server.status),
            ),
          ),
        ],
      ),
      body: Consumer<SpcServerApp>(
        builder: (context, server, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return _DesktopLayout(server: server);
              }
              return _MobileLayout(server: server);
            },
          );
        },
      ),
    );
  }
}

// ─── Desktop: 2 sütun ─────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.server});
  final SpcServerApp server;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sol sütun
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ServerControlCard(server: server),
                const SizedBox(height: 20),
                _EmailConfigCard(server: server),
              ],
            ),
          ),
        ),
        // Sağ sütun
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatsCard(server: server),
                const SizedBox(height: 20),
                _LogCard(server: server),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Mobile: tek sütun ────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.server});
  final SpcServerApp server;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ServerControlCard(server: server),
          const SizedBox(height: 16),
          _StatsCard(server: server),
          const SizedBox(height: 16),
          _EmailConfigCard(server: server),
          const SizedBox(height: 16),
          _LogCard(server: server),
        ],
      ),
    );
  }
}

// ─── Sunucu Kontrol Kartı ─────────────────────────────────────────────────────

class _ServerControlCard extends StatefulWidget {
  const _ServerControlCard({required this.server});
  final SpcServerApp server;

  @override
  State<_ServerControlCard> createState() => _ServerControlCardState();
}

class _ServerControlCardState extends State<_ServerControlCard> {
  late final TextEditingController _portCtrl;

  @override
  void initState() {
    super.initState();
    _portCtrl = TextEditingController(
      text: widget.server.serverConfig.port.toString(),
    );
  }

  @override
  void dispose() {
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final server = widget.server;
    final isRunning = server.isRunning;
    final isBusy = server.status == ServerStatus.starting ||
        server.status == ServerStatus.stopping;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Sunucu Kontrolü', showDivider: true),

          // Port ayarı
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _portCtrl,
                  enabled: !isRunning,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'HTTP / WS Port',
                    prefixIcon: Icon(Icons.settings_ethernet_rounded),
                  ),
                  onChanged: (v) {
                    final port = int.tryParse(v);
                    if (port != null && port > 1024 && port < 65535) {
                      server.updateServerConfig(
                        server.serverConfig.copyWith(port: port),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Broadcast interval
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<int>(
                  initialValue: server.serverConfig.broadcastIntervalSeconds,
                  decoration: const InputDecoration(labelText: 'Yayın (sn)'),
                  items: [2, 5, 10, 30]
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v sn'),
                          ))
                      .toList(),
                  onChanged: isRunning
                      ? null
                      : (v) {
                          if (v != null) {
                            server.updateServerConfig(
                              server.serverConfig.copyWith(
                                broadcastIntervalSeconds: v,
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // URL göster
          if (isRunning) ...[
            _InfoRow(
              icon: Icons.link_rounded,
              label: 'HTTP API',
              value: 'http://localhost:${server.serverConfig.port}/api/status',
              copyable: true,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.swap_horiz_rounded,
              label: 'WebSocket',
              value: 'ws://localhost:${server.serverConfig.port}/ws',
              copyable: true,
            ),
            const SizedBox(height: 16),
          ],

          // Hata mesajı
          if (server.status == ServerStatus.error &&
              server.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.alarmCriticalBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      server.errorMessage!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.alarmCriticalText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Başlat / Durdur butonu
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isBusy
                  ? null
                  : () => isRunning
                      ? server.stopServer()
                      : server.startServer(),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isRunning ? AppColors.danger : AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isRunning
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded),
              label: Text(
                isBusy
                    ? (server.status == ServerStatus.starting
                        ? 'Başlatılıyor...'
                        : 'Durduruluyor...')
                    : (isRunning ? 'Sunucuyu Durdur' : 'Sunucuyu Başlat'),
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── İstatistik Kartı ─────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.server});
  final SpcServerApp server;

  @override
  Widget build(BuildContext context) {
    final uptime = server.isRunning
        ? _formatUptime(server.humidityData.isNotEmpty
            ? DateTime.now()
                .difference(server.humidityData.first.timestamp)
                .inSeconds
            : 0)
        : '-';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Durum', showDivider: true),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.people_rounded,
                  label: 'Bağlı İstemci',
                  value: '${server.clientCount}',
                  color: AppColors.info,
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.water_drop_rounded,
                  label: 'Nem Kaydı',
                  value: '${server.humidityData.length}',
                  color: AppColors.chartBlue,
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.straighten_rounded,
                  label: 'Deform. Kaydı',
                  value: '${server.deformationData.length}',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.timer_rounded,
                  label: 'Çalışma Süresi',
                  value: uptime,
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.notifications_rounded,
                  label: 'Son Alarm',
                  value: server.lastAlarmLevel?.label ?? 'Yok',
                  color: server.lastAlarmLevel?.stripColor ?? AppColors.success,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    if (seconds < 60) return '${seconds}sn';
    if (seconds < 3600) return '${seconds ~/ 60}dk';
    return '${seconds ~/ 3600}sa ${(seconds % 3600) ~/ 60}dk';
  }
}

// ─── Email Yapılandırma Kartı ─────────────────────────────────────────────────

class _EmailConfigCard extends StatefulWidget {
  const _EmailConfigCard({required this.server});
  final SpcServerApp server;

  @override
  State<_EmailConfigCard> createState() => _EmailConfigCardState();
}

class _EmailConfigCardState extends State<_EmailConfigCard> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _user;
  late final TextEditingController _pass;
  late final TextEditingController _fromName;
  late final TextEditingController _to;
  bool _obscurePass = true;
  bool _saving = false;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final c = widget.server.emailConfig;
    _host = TextEditingController(text: c.smtpHost);
    _port = TextEditingController(text: c.smtpPort.toString());
    _user = TextEditingController(text: c.username);
    _pass = TextEditingController(text: c.password);
    _fromName = TextEditingController(text: c.fromName);
    _to = TextEditingController(text: c.toEmails.join(', '));
  }

  @override
  void dispose() {
    for (final c in [_host, _port, _user, _pass, _fromName, _to]) {
      c.dispose();
    }
    super.dispose();
  }

  EmailConfig _buildConfig() {
    final toList = _to.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return EmailConfig(
      smtpHost: _host.text.trim(),
      smtpPort: int.tryParse(_port.text) ?? 587,
      username: _user.text.trim(),
      password: _pass.text,
      fromName: _fromName.text.trim(),
      toEmails: toList,
      useSsl: widget.server.emailConfig.useSsl,
      sendOnCritical: widget.server.emailConfig.sendOnCritical,
      sendOnHigh: widget.server.emailConfig.sendOnHigh,
      sendOnMedium: widget.server.emailConfig.sendOnMedium,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.server.updateEmailConfig(_buildConfig());
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email yapılandırması kaydedildi.')),
      );
    }
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    await widget.server.updateEmailConfig(_buildConfig());
    final ok = await widget.server.sendTestEmail();
    setState(() {
      _testing = false;
      _testResult = ok ? 'Bağlantı başarılı!' : 'Bağlantı hatası — log\'u kontrol edin.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Email Yapılandırması', showDivider: true),

          // SMTP
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _Field(ctrl: _host, label: 'SMTP Host', hint: 'smtp.gmail.com'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  ctrl: _port,
                  label: 'Port',
                  hint: '587',
                  inputType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Kimlik bilgileri
          _Field(ctrl: _user, label: 'Kullanıcı Adı / Email', hint: 'noreply@vitra.com.tr'),
          const SizedBox(height: 12),
          _PasswordField(ctrl: _pass, obscure: _obscurePass, onToggle: () => setState(() => _obscurePass = !_obscurePass)),
          const SizedBox(height: 12),

          // Gönderici adı
          _Field(ctrl: _fromName, label: 'Gönderici Adı', hint: 'VitrA SPC'),
          const SizedBox(height: 12),

          // Alıcılar
          _Field(
            ctrl: _to,
            label: 'Alıcılar (virgülle ayır)',
            hint: 'kalite@vitra.com.tr, mudur@vitra.com.tr',
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              'Email, yukarıdaki kullanıcı adresinden bu adreslere gönderilir.',
              style: AppTextStyles.bodySmall,
            ),
          ),

          const SizedBox(height: 16),

          // Bildirim seçenekleri
          _NotificationToggles(server: widget.server),

          const SizedBox(height: 16),

          // Test sonucu
          if (_testResult != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _testResult!.contains('başarılı')
                    ? AppColors.alarmLowBg
                    : AppColors.alarmCriticalBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _testResult!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: _testResult!.contains('başarılı')
                      ? AppColors.alarmLowText
                      : AppColors.alarmCriticalText,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Butonlar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Bağlantıyı Test Et'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationToggles extends StatelessWidget {
  const _NotificationToggles({required this.server});
  final SpcServerApp server;

  @override
  Widget build(BuildContext context) {
    final cfg = server.emailConfig;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email Bildirimleri', style: AppTextStyles.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _AlarmToggle(
              level: AlarmLevel.critical,
              value: cfg.sendOnCritical,
              onChanged: (v) => server.updateEmailConfig(cfg.copyWith(sendOnCritical: v)),
            ),
            _AlarmToggle(
              level: AlarmLevel.high,
              value: cfg.sendOnHigh,
              onChanged: (v) => server.updateEmailConfig(cfg.copyWith(sendOnHigh: v)),
            ),
            _AlarmToggle(
              level: AlarmLevel.medium,
              value: cfg.sendOnMedium,
              onChanged: (v) => server.updateEmailConfig(cfg.copyWith(sendOnMedium: v)),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlarmToggle extends StatelessWidget {
  const _AlarmToggle({required this.level, required this.value, required this.onChanged});
  final AlarmLevel level;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? level.backgroundColor : AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? level.textColor.withValues(alpha: 0.5) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
              size: 14,
              color: value ? level.textColor : AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              level.label,
              style: AppTextStyles.label.copyWith(
                color: value ? level.textColor : AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Log Kartı ────────────────────────────────────────────────────────────────

class _LogCard extends StatefulWidget {
  const _LogCard({required this.server});
  final SpcServerApp server;

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _LogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.server.logs;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: const SectionHeader(title: 'Sunucu Logu', showDivider: false),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: 'Logu Kopyala',
                iconSize: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
            ),
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      'Sunucu henüz başlatılmadı.',
                      style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF6B7280)),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (_, i) {
                      final log = logs[i];
                      final isError = log.contains('HATA') || log.contains('ERR');
                      return Text(
                        log,
                        style: AppTextStyles.mono.copyWith(
                          fontSize: 11,
                          color: isError
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF98C379),
                          height: 1.6,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Yardımcı Widget'lar ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ServerStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      ServerStatus.running => ('Çalışıyor', AppColors.alarmLowText, AppColors.alarmLowBg),
      ServerStatus.starting => ('Başlatılıyor', AppColors.alarmMediumText, AppColors.alarmMediumBg),
      ServerStatus.stopping => ('Durduruluyor', AppColors.alarmMediumText, AppColors.alarmMediumBg),
      ServerStatus.error => ('Hata', AppColors.alarmCriticalText, AppColors.alarmCriticalBg),
      ServerStatus.stopped => ('Durdu', AppColors.textMuted, AppColors.background),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.label.copyWith(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.kpiValue.copyWith(fontSize: 20, color: color)),
        Text(label, style: AppTextStyles.kpiLabel, textAlign: TextAlign.center),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.copyable = false});
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTextStyles.bodySmall),
          Expanded(
            child: Text(value,
                style: AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.primary),
                overflow: TextOverflow.ellipsis),
          ),
          if (copyable)
            IconButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: value)),
              icon: const Icon(Icons.copy_rounded, size: 14),
              color: AppColors.textMuted,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Kopyala',
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.ctrl, required this.label, this.hint, this.inputType});
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final TextInputType? inputType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.ctrl, required this.obscure, required this.onToggle});
  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: 'Şifre / Uygulama Parolası',
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
        ),
      ),
    );
  }
}
