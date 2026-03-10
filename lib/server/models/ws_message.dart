import 'dart:convert';

/// WebSocket mesaj tipleri.
enum WsMessageType {
  humidityData,
  deformationData,
  alarm,
  status,
  ping,
  pong,
}

/// WebSocket üzerinden gönderilen/alınan mesaj zarfı.
class WsMessage {
  const WsMessage({
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  final WsMessageType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  factory WsMessage.humidityData(List<Map<String, dynamic>> data) => WsMessage(
        type: WsMessageType.humidityData,
        payload: {'data': data},
        timestamp: DateTime.now(),
      );

  factory WsMessage.deformationData(List<Map<String, dynamic>> data) =>
      WsMessage(
        type: WsMessageType.deformationData,
        payload: {'data': data},
        timestamp: DateTime.now(),
      );

  factory WsMessage.alarm(String level, String message) => WsMessage(
        type: WsMessageType.alarm,
        payload: {'level': level, 'message': message},
        timestamp: DateTime.now(),
      );

  factory WsMessage.status(Map<String, dynamic> status) => WsMessage(
        type: WsMessageType.status,
        payload: status,
        timestamp: DateTime.now(),
      );

  factory WsMessage.pong() => WsMessage(
        type: WsMessageType.pong,
        payload: {},
        timestamp: DateTime.now(),
      );

  String toJson() => jsonEncode({
        'type': type.name,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
      });

  factory WsMessage.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return WsMessage(
      type: WsMessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WsMessageType.status,
      ),
      payload: map['payload'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
