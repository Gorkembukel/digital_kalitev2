import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/email_config.dart';
import '../../core/models/alarm_level.dart';

/// Email gönderme sonucu.
class EmailResult {
  const EmailResult({required this.success, this.error});

  final bool success;
  final String? error;

  static const EmailResult ok = EmailResult(success: true);
  static EmailResult fail(String error) => EmailResult(success: false, error: error);
}

/// SMTP email servisi — mailer paketi üzerinden çalışır.
abstract final class EmailService {
  /// Alarm emaili gönderir.
  static Future<EmailResult> sendAlarmEmail({
    required EmailConfig config,
    required AlarmLevel level,
    required String subject,
    required String details,
    required DateTime timestamp,
  }) async {
    if (!config.isValid) {
      return EmailResult.fail('Email yapılandırması eksik.');
    }

    try {
      final smtpServer = _buildSmtpServer(config);
      final message = Message()
        ..from = Address(config.username, config.fromName)
        ..recipients.addAll(config.toEmails.map((e) => Address(e)))
        ..subject = '[VitrA SPC] $subject'
        ..html = _buildAlarmHtml(
          level: level,
          subject: subject,
          details: details,
          timestamp: timestamp,
        );

      await send(message, smtpServer);
      return EmailResult.ok;
    } on MailerException catch (e) {
      return EmailResult.fail('SMTP hatası: ${e.message}');
    } catch (e) {
      return EmailResult.fail('Beklenmeyen hata: $e');
    }
  }

  /// SMTP bağlantısını test eder — boş bir email göndermeden bağlantıyı doğrular.
  static Future<EmailResult> testConnection(EmailConfig config) async {
    if (!config.isValid) {
      return EmailResult.fail('Email yapılandırması eksik.');
    }
    try {
      final smtpServer = _buildSmtpServer(config);
      final message = Message()
        ..from = Address(config.username, config.fromName)
        ..recipients.addAll(config.toEmails.map((e) => Address(e)))
        ..subject = '[VitrA SPC] Bağlantı Testi'
        ..text = 'Bu mesaj VitrA SPC Dashboard tarafından gönderilmiştir.';

      await send(message, smtpServer);
      return EmailResult.ok;
    } on MailerException catch (e) {
      return EmailResult.fail('SMTP hatası: ${e.message}');
    } catch (e) {
      return EmailResult.fail('Bağlantı hatası: $e');
    }
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  static SmtpServer _buildSmtpServer(EmailConfig config) {
    return SmtpServer(
      config.smtpHost,
      port: config.smtpPort,
      username: config.username,
      password: config.password,
      ssl: config.useSsl && config.smtpPort == 465,
      allowInsecure: !config.useSsl,
    );
  }

  static String _buildAlarmHtml({
    required AlarmLevel level,
    required String subject,
    required String details,
    required DateTime timestamp,
  }) {
    final levelColors = {
      AlarmLevel.critical: ('#FDECEA', '#C0392B'),
      AlarmLevel.high: ('#FEF0E7', '#D35400'),
      AlarmLevel.medium: ('#FEF9E7', '#B7770D'),
      AlarmLevel.low: ('#EAF7EF', '#1E8449'),
    };
    final (bg, fg) = levelColors[level] ?? ('#F0F2F8', '#1A1A2E');
    final ts = '${timestamp.day}.${timestamp.month}.${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';

    return '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: Arial, sans-serif; background: #F0F2F8; padding: 24px;">
  <div style="max-width: 600px; margin: 0 auto; background: #fff;
              border-radius: 12px; overflow: hidden;
              box-shadow: 0 2px 12px rgba(27,58,107,0.10);">
    <!-- Header -->
    <div style="background: #1B3A6B; padding: 20px 24px;">
      <div style="color: #fff; font-size: 20px; font-weight: 700;">
        VitrA Karo SPC Dashboard
      </div>
      <div style="color: #8BADD4; font-size: 13px; margin-top: 4px;">
        Kalite Kontrol Alarm Bildirimi
      </div>
    </div>
    <!-- Alarm Badge -->
    <div style="padding: 24px;">
      <div style="background: $bg; border-left: 4px solid $fg;
                  border-radius: 6px; padding: 16px; margin-bottom: 16px;">
        <div style="color: $fg; font-weight: 700; font-size: 16px;">
          ${level.label} ALARM
        </div>
        <div style="color: #1A1A2E; font-size: 15px; margin-top: 8px;">
          $subject
        </div>
      </div>
      <!-- Details -->
      <div style="background: #F0F2F8; border-radius: 6px; padding: 16px;
                  font-size: 14px; color: #1A1A2E; white-space: pre-line;">
$details
      </div>
      <!-- Footer -->
      <div style="margin-top: 16px; color: #6B7280; font-size: 12px;">
        Zaman: $ts
      </div>
    </div>
    <div style="background: #F0F2F8; padding: 12px 24px;
                color: #6B7280; font-size: 11px; text-align: center;">
      Bu email VitrA SPC Dashboard tarafından otomatik olarak gönderilmiştir.
    </div>
  </div>
</body>
</html>
''';
  }
}
