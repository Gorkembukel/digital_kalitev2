/// HTTP/WebSocket sunucu yapılandırması.
class ServerConfig {
  const ServerConfig({
    this.host = '0.0.0.0',
    this.port = 8080,
    this.broadcastIntervalSeconds = 5,
  });

  final String host;
  final int port;

  /// WebSocket ile veri yayın aralığı (saniye).
  final int broadcastIntervalSeconds;

  String get wsUrl => 'ws://localhost:$port/ws';
  String get httpUrl => 'http://localhost:$port';

  ServerConfig copyWith({String? host, int? port, int? broadcastIntervalSeconds}) =>
      ServerConfig(
        host: host ?? this.host,
        port: port ?? this.port,
        broadcastIntervalSeconds:
            broadcastIntervalSeconds ?? this.broadcastIntervalSeconds,
      );

  Map<String, dynamic> toMap() => {
        'host': host,
        'port': port,
        'broadcastIntervalSeconds': broadcastIntervalSeconds,
      };

  factory ServerConfig.fromMap(Map<dynamic, dynamic> map) => ServerConfig(
        host: map['host'] as String? ?? '0.0.0.0',
        port: map['port'] as int? ?? 8080,
        broadcastIntervalSeconds: map['broadcastIntervalSeconds'] as int? ?? 5,
      );
}
