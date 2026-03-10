/// Client bağlantı durumu.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error;

  String get label => switch (this) {
        ConnectionStatus.disconnected => 'Bağlı Değil',
        ConnectionStatus.connecting => 'Bağlanıyor...',
        ConnectionStatus.connected => 'Bağlı',
        ConnectionStatus.error => 'Hata',
      };

  bool get isActive => this == ConnectionStatus.connected;
}
