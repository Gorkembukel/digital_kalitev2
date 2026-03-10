import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/models/alarm_level.dart';
import '../core/models/measurement.dart';
import '../core/spc/imr_calculator.dart';
import '../core/spc/risk_calculator.dart';
import 'database/config_database.dart';
import 'handlers/api_handler.dart';
import 'handlers/ws_manager.dart';
import 'models/email_config.dart';
import 'models/server_config.dart';
import 'models/ws_message.dart';
import 'services/email_service.dart';
import 'services/mock_data_service.dart';

/// Sunucu durumu.
enum ServerStatus { stopped, starting, running, stopping, error }

/// SPC sunucu uygulaması — HTTP + WebSocket + email + veri yönetimi.
///
/// ChangeNotifier olduğundan Provider ile UI'a reaktif bağlanabilir.
class SpcServerApp extends ChangeNotifier {
  SpcServerApp();

  // ─── State ──────────────────────────────────────────────────────────────────
  ServerStatus _status = ServerStatus.stopped;
  ServerConfig _serverConfig = const ServerConfig();
  EmailConfig _emailConfig = EmailConfig.empty;
  String? _errorMessage;
  final List<String> _logs = [];
  int _clientCount = 0;
  AlarmLevel? _lastAlarmLevel;

  // ─── Internals ──────────────────────────────────────────────────────────────
  HttpServer? _httpServer;
  late final ServerDataStore _dataStore;
  late final WsManager _wsManager;
  Timer? _broadcastTimer;
  double _lastHumidity = 6.05;
  bool _dbInitialized = false;

  // ─── Getters ────────────────────────────────────────────────────────────────
  ServerStatus get status => _status;
  ServerConfig get serverConfig => _serverConfig;
  EmailConfig get emailConfig => _emailConfig;
  String? get errorMessage => _errorMessage;
  List<String> get logs => List.unmodifiable(_logs);
  int get clientCount => _clientCount;
  AlarmLevel? get lastAlarmLevel => _lastAlarmLevel;
  bool get isRunning => _status == ServerStatus.running;

  List<HumidityMeasurement> get humidityData => _dataStore.humidityData;
  List<DeformationMeasurement> get deformationData => _dataStore.deformationData;

  // ─── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _dataStore = ServerDataStore();
    _wsManager = WsManager(
      onLog: _log,
      onClientCountChanged: (count) {
        _clientCount = count;
        _dataStore.connectedClients = count;
        notifyListeners();
      },
    );

    if (!_dbInitialized) {
      await ConfigDatabase.init();
      _dbInitialized = true;
    }
    _serverConfig = await ConfigDatabase.loadServerConfig();
    _emailConfig = await ConfigDatabase.loadEmailConfig();

    // Geçmiş mock veri yükle
    final histHumidity = MockDataService.generateHumidityHistory(count: 200);
    for (final m in histHumidity) {
      _dataStore.addHumidity(m);
    }
    final histDeform = MockDataService.generateDeformationHistory(count: 100);
    for (final m in histDeform) {
      _dataStore.addDeformation(m);
    }
    if (histHumidity.isNotEmpty) {
      _lastHumidity = histHumidity.last.value;
    }

    notifyListeners();
  }

  // ─── Server Lifecycle ────────────────────────────────────────────────────────

  Future<void> startServer() async {
    if (_status != ServerStatus.stopped) return;
    _setStatus(ServerStatus.starting);
    _errorMessage = null;

    try {
      final apiHandler = ApiHandler(_dataStore);

      final router = Router()
        ..get('/ws', webSocketHandler(
          (WebSocketChannel channel) => _wsManager.addClient(channel),
        ))
        ..mount('/', apiHandler.router.call);

      final handler = const Pipeline()
          .addMiddleware(corsHeaders())
          .addMiddleware(logRequests(logger: (msg, isError) {
            if (isError) _log('[HTTP ERR] $msg');
          }))
          .addHandler(router.call);

      _httpServer = await shelf_io.serve(
        handler,
        _serverConfig.host,
        _serverConfig.port,
      );
      _httpServer!.autoCompress = true;

      _log('Sunucu başlatıldı → http://localhost:${_serverConfig.port}');
      _log('WebSocket → ws://localhost:${_serverConfig.port}/ws');

      _startBroadcastTimer();
      _setStatus(ServerStatus.running);
    } catch (e) {
      _errorMessage = e.toString();
      _log('HATA: $_errorMessage');
      _setStatus(ServerStatus.error);
    }
  }

  Future<void> stopServer() async {
    if (!isRunning) return;
    _setStatus(ServerStatus.stopping);
    _broadcastTimer?.cancel();
    await _wsManager.closeAll();
    await _httpServer?.close(force: true);
    _httpServer = null;
    _log('Sunucu durduruldu.');
    _setStatus(ServerStatus.stopped);
  }

  // ─── Config ──────────────────────────────────────────────────────────────────

  Future<void> updateEmailConfig(EmailConfig config) async {
    _emailConfig = config;
    await ConfigDatabase.saveEmailConfig(config);
    _log('Email yapılandırması kaydedildi.');
    notifyListeners();
  }

  Future<void> updateServerConfig(ServerConfig config) async {
    _serverConfig = config;
    await ConfigDatabase.saveServerConfig(config);
    _log('Sunucu yapılandırması kaydedildi.');
    notifyListeners();
  }

  // ─── Email ───────────────────────────────────────────────────────────────────

  Future<bool> sendTestEmail() async {
    _log('Test emaili gönderiliyor...');
    final result = await EmailService.testConnection(_emailConfig);
    if (result.success) {
      _log('Test emaili başarıyla gönderildi.');
    } else {
      _log('Test emaili hatası: ${result.error}');
    }
    return result.success;
  }

  // ─── Broadcast ───────────────────────────────────────────────────────────────

  void _startBroadcastTimer() {
    _broadcastTimer = Timer.periodic(
      Duration(seconds: _serverConfig.broadcastIntervalSeconds),
      (_) => _generateAndBroadcast(),
    );
  }

  void _generateAndBroadcast() {
    // Yeni nem verisi üret
    final humidity = MockDataService.nextHumidity(previousValue: _lastHumidity);
    _lastHumidity = humidity.value;
    _dataStore.addHumidity(humidity);

    // Her 3 döngüde bir deformasyon ekle
    if (_dataStore.humidityData.length % 3 == 0) {
      final deform = MockDataService.nextDeformation();
      _dataStore.addDeformation(deform);
    }

    // Risk hesapla
    final values = _dataStore.humidityData.map((m) => m.value).toList();
    if (values.length >= 2) {
      final imr = ImrCalculator.calculate(values);
      final risk = RiskCalculator.calculateHumidityRisk(
        values: values,
        mean: imr.mean,
        sigma: imr.sigmaEstimate,
      );

      // Alarm seviyesi değiştiyse email gönder
      if (risk.level != _lastAlarmLevel) {
        _lastAlarmLevel = risk.level;
        _maybeSendAlarmEmail(risk);
        notifyListeners();
      }
    }

    // WS broadcast
    _wsManager.broadcast(WsMessage.humidityData([humidity.toJson()]));
    notifyListeners();
  }

  void _maybeSendAlarmEmail(RiskResult risk) {
    final shouldSend = switch (risk.level) {
      AlarmLevel.critical => _emailConfig.sendOnCritical,
      AlarmLevel.high => _emailConfig.sendOnHigh,
      AlarmLevel.medium => _emailConfig.sendOnMedium,
      AlarmLevel.low => false,
    };

    if (!shouldSend || !_emailConfig.isValid) return;

    EmailService.sendAlarmEmail(
      config: _emailConfig,
      level: risk.level,
      subject: '${risk.level.label} — Nem süreci dışına çıkıldı',
      details: risk.reasons.join('\n'),
      timestamp: DateTime.now(),
    ).then((result) {
      if (result.success) {
        _log('Alarm emaili gönderildi (${risk.level.label}).');
      } else {
        _log('Email gönderilemedi: ${result.error}');
      }
    });
  }

  // ─── Logging ─────────────────────────────────────────────────────────────────

  void _log(String message) {
    final now = DateTime.now();
    final ts = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    _logs.add('[$ts] $message');
    if (_logs.length > 500) _logs.removeAt(0);
    debugPrint('[SpcServer] $message');
    notifyListeners();
  }

  void _setStatus(ServerStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await stopServer();
    super.dispose();
  }
}
