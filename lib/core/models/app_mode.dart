/// Uygulama çalışma modu.
enum AppMode {
  /// Veri işleme, email, WebSocket/HTTP sunucu.
  server,

  /// Sunucuya bağlanıp veriyi görüntüleyen istemci.
  client;

  String get label => switch (this) {
        AppMode.server => 'Sunucu Modu',
        AppMode.client => 'İstemci Modu',
      };

  String get description => switch (this) {
        AppMode.server =>
          'Veri işleme, alarm yönetimi ve email gönderme sunucusu olarak çalışır.',
        AppMode.client =>
          'Sunucuya bağlanarak canlı verileri görüntüler.',
      };
}
