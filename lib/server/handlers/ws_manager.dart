import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/ws_message.dart';

/// WebSocket bağlantı yöneticisi.
class WsManager {
  final _clients = <WebSocketChannel>{};
  final void Function(String log) onLog;
  final void Function(int count) onClientCountChanged;

  WsManager({required this.onLog, required this.onClientCountChanged});

  int get clientCount => _clients.length;

  /// Yeni WebSocket bağlantısını kaydeder.
  void addClient(WebSocketChannel channel) {
    _clients.add(channel);
    onClientCountChanged(_clients.length);
    onLog('Yeni istemci bağlandı. Toplam: ${_clients.length}');

    channel.stream.listen(
      (message) => _handleMessage(channel, message as String),
      onDone: () => _removeClient(channel),
      onError: (_) => _removeClient(channel),
      cancelOnError: true,
    );
  }

  /// Tüm bağlı istemcilere mesaj yayınlar.
  void broadcast(WsMessage message) {
    if (_clients.isEmpty) return;
    final json = message.toJson();
    final disconnected = <WebSocketChannel>[];
    for (final client in _clients) {
      try {
        client.sink.add(json);
      } catch (_) {
        disconnected.add(client);
      }
    }
    for (final c in disconnected) {
      _removeClient(c);
    }
  }

  Future<void> closeAll() async {
    for (final client in _clients) {
      await client.sink.close();
    }
    _clients.clear();
    onClientCountChanged(0);
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  void _handleMessage(WebSocketChannel channel, String raw) {
    try {
      final msg = WsMessage.fromJson(raw);
      if (msg.type == WsMessageType.ping) {
        channel.sink.add(WsMessage.pong().toJson());
      }
    } catch (_) {
      // Bilinmeyen mesaj — yoksay
    }
  }

  void _removeClient(WebSocketChannel channel) {
    _clients.remove(channel);
    onClientCountChanged(_clients.length);
    onLog('İstemci bağlantısı kesildi. Kalan: ${_clients.length}');
  }
}
