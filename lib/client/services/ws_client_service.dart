import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../server/models/ws_message.dart';

/// WebSocket üzerinden sunucuya bağlanan istemci servisi.
class WsClientService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _pingTimer;

  final _controller = StreamController<WsMessage>.broadcast();

  /// Sunucu WS mesajlarının stream'i.
  Stream<WsMessage> get messages => _controller.stream;

  bool get isConnected => _channel != null;

  /// Sunucuya WebSocket bağlantısı kurar.
  void connect(String wsUrl) {
    disconnect();
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _sub = _channel!.stream.listen(
      (raw) {
        try {
          final msg = WsMessage.fromJson(raw as String);
          _controller.add(msg);
        } catch (_) {
          // Bilinmeyen mesaj — yoksay
        }
      },
      onDone: _onDisconnected,
      onError: (_) => _onDisconnected(),
    );

    // Her 30 saniyede ping gönder (bağlantıyı canlı tut)
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendPing();
    });
  }

  void disconnect() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  void _sendPing() {
    try {
      _channel?.sink.add(
        '{"type":"ping","payload":{},"timestamp":"${DateTime.now().toIso8601String()}"}',
      );
    } catch (_) {}
  }

  void _onDisconnected() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    // Downstream'e disconnect sinyali ver
    _controller.add(WsMessage.status({'event': 'disconnected'}));
  }
}
