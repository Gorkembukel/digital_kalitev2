/// SMTP email yapılandırması.
/// Gönderici adres olarak [username] kullanılır — ayrı fromEmail alanı yok.
class EmailConfig {
  const EmailConfig({
    required this.smtpHost,
    required this.smtpPort,
    required this.username,
    required this.password,
    required this.fromName,
    required this.toEmails,
    this.useSsl = true,
    this.sendOnCritical = true,
    this.sendOnHigh = true,
    this.sendOnMedium = false,
  });

  final String smtpHost;
  final int smtpPort;
  final String username;
  final String password;
  final String fromName;

  /// Alıcı email adresleri listesi.
  final List<String> toEmails;

  final bool useSsl;
  final bool sendOnCritical;
  final bool sendOnHigh;
  final bool sendOnMedium;

  bool get isValid =>
      smtpHost.isNotEmpty &&
      username.isNotEmpty &&
      password.isNotEmpty &&
      toEmails.isNotEmpty;

  EmailConfig copyWith({
    String? smtpHost,
    int? smtpPort,
    String? username,
    String? password,
    String? fromName,
    List<String>? toEmails,
    bool? useSsl,
    bool? sendOnCritical,
    bool? sendOnHigh,
    bool? sendOnMedium,
  }) {
    return EmailConfig(
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      username: username ?? this.username,
      password: password ?? this.password,
      fromName: fromName ?? this.fromName,
      toEmails: toEmails ?? this.toEmails,
      useSsl: useSsl ?? this.useSsl,
      sendOnCritical: sendOnCritical ?? this.sendOnCritical,
      sendOnHigh: sendOnHigh ?? this.sendOnHigh,
      sendOnMedium: sendOnMedium ?? this.sendOnMedium,
    );
  }

  Map<String, dynamic> toMap() => {
        'smtpHost': smtpHost,
        'smtpPort': smtpPort,
        'username': username,
        'password': password,
        'fromName': fromName,
        'toEmails': toEmails,
        'useSsl': useSsl,
        'sendOnCritical': sendOnCritical,
        'sendOnHigh': sendOnHigh,
        'sendOnMedium': sendOnMedium,
      };

  factory EmailConfig.fromMap(Map<dynamic, dynamic> map) => EmailConfig(
        smtpHost: map['smtpHost'] as String? ?? '',
        smtpPort: map['smtpPort'] as int? ?? 587,
        username: map['username'] as String? ?? '',
        password: map['password'] as String? ?? '',
        fromName: map['fromName'] as String? ?? 'VitrA SPC',
        toEmails: (map['toEmails'] as List?)?.cast<String>() ?? [],
        useSsl: map['useSsl'] as bool? ?? true,
        sendOnCritical: map['sendOnCritical'] as bool? ?? true,
        sendOnHigh: map['sendOnHigh'] as bool? ?? true,
        sendOnMedium: map['sendOnMedium'] as bool? ?? false,
      );

  static EmailConfig get empty => const EmailConfig(
        smtpHost: '',
        smtpPort: 587,
        username: '',
        password: '',
        fromName: 'VitrA SPC',
        toEmails: [],
      );
}
