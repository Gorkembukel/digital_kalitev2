import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/models/measurement.dart';
import '../../core/spc/imr_calculator.dart';
import '../../core/spc/capability_calculator.dart';
import '../../core/spc/nelson_rules.dart';
import '../../core/spc/risk_calculator.dart';
import '../../core/constants/spec_limits.dart';
import '../../server/models/ws_message.dart';
import '../models/connection_status.dart';
import '../services/http_client_service.dart';
import '../services/ws_client_service.dart';

/// Client tarafının merkezi state yöneticisi.
/// Hem HTTP (ilk yükleme) hem WS (canlı veri) bağlantısını yönetir.
class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider();

  // ─── Config ──────────────────────────────────────────────────────────────
  String _serverUrl = 'http://localhost:8080';
  String get serverUrl => _serverUrl;

  String get wsUrl => '${_serverUrl.replaceFirst('http', 'ws')}/ws';

  // ─── Connection State ─────────────────────────────────────────────────────
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ─── Data ─────────────────────────────────────────────────────────────────
  final List<HumidityMeasurement> _humidity = [];
  final List<DeformationMeasurement> _deformation = [];

  List<HumidityMeasurement> get humidityData => List.unmodifiable(_humidity);
  List<DeformationMeasurement> get deformationData => List.unmodifiable(_deformation);

  int _totalHumidityCount = 0;
  int _totalDeformCount = 0;
  int get totalHumidityCount => _totalHumidityCount;
  int get totalDeformCount => _totalDeformCount;

  // ─── Computed SPC ─────────────────────────────────────────────────────────
  ImrResult? _humidityImr;
  RiskResult? _humidityRisk;
  CapabilityResult? _humidityCapability;
  List<NelsonViolation> _nelsonViolations = [];

  ImrResult? get humidityImr => _humidityImr;
  RiskResult? get humidityRisk => _humidityRisk;
  CapabilityResult? get humidityCapability => _humidityCapability;
  List<NelsonViolation> get nelsonViolations => _nelsonViolations;

  // ─── Services ─────────────────────────────────────────────────────────────
  late HttpClientService _http;
  final WsClientService _ws = WsClientService();
  StreamSubscription? _wsSub;

  // ─── Connect ──────────────────────────────────────────────────────────────

  Future<void> connect(String serverUrl) async {
    _serverUrl = serverUrl.trimRight().replaceAll(RegExp(r'/$'), '');
    _errorMessage = null;
    _setStatus(ConnectionStatus.connecting);

    try {
      _http = HttpClientService(baseUrl: _serverUrl);

      // 1. Ping — sunucu erişilebilir mi?
      final alive = await _http.ping();
      if (!alive) {
        throw Exception('Sunucuya ulaşılamıyor: $_serverUrl');
      }

      // 2. HTTP ile geçmiş veriyi yükle + toplam sayı
      final hum = await _http.fetchHumidity(limit: 300);
      final def = await _http.fetchDeformation(limit: 100);

      _humidity
        ..clear()
        ..addAll(hum);
      _deformation
        ..clear()
        ..addAll(def);

      _totalHumidityCount = await _http.fetchHumidityCount();
      _totalDeformCount = await _http.fetchDeformCount();
      if (_totalHumidityCount == 0) _totalHumidityCount = _humidity.length;
      if (_totalDeformCount == 0) _totalDeformCount = _deformation.length;

      _computeSpc();

      // 3. WebSocket canlı veri
      _ws.connect(wsUrl);
      _wsSub = _ws.messages.listen(_onWsMessage);

      _setStatus(ConnectionStatus.connected);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(ConnectionStatus.error);
    }
  }

  Future<void> disconnect() async {
    await _wsSub?.cancel();
    _ws.disconnect();
    _humidity.clear();
    _deformation.clear();
    _humidityImr = null;
    _humidityRisk = null;
    _humidityCapability = null;
    _nelsonViolations = [];
    _totalHumidityCount = 0;
    _totalDeformCount = 0;
    _setStatus(ConnectionStatus.disconnected);
  }

  /// Veriyi sunucudan yeniden çeker (refresh butonu).
  Future<void> refresh() async {
    if (_status != ConnectionStatus.connected) return;
    try {
      final hum = await _http.fetchHumidity(limit: 300);
      final def = await _http.fetchDeformation(limit: 100);
      _humidity
        ..clear()
        ..addAll(hum);
      _deformation
        ..clear()
        ..addAll(def);
      _computeSpc();
      notifyListeners();
    } catch (_) {}
  }

  // ─── WebSocket handler ────────────────────────────────────────────────────

  void _onWsMessage(WsMessage msg) {
    switch (msg.type) {
      case WsMessageType.humidityData:
        final list = msg.payload['data'] as List?;
        if (list != null) {
          final newItems = list.cast<Map<String, dynamic>>();
          for (final item in newItems) {
            _humidity.add(HumidityMeasurement.fromJson(item));
          }
          _totalHumidityCount += newItems.length;
          // Bellek yönetimi
          if (_humidity.length > 500) {
            _humidity.removeRange(0, _humidity.length - 500);
          }
          _computeSpc();
          notifyListeners();
        }
      case WsMessageType.deformationData:
        final list = msg.payload['data'] as List?;
        if (list != null) {
          for (final item in list.cast<Map<String, dynamic>>()) {
            _deformation.add(DeformationMeasurement.fromJson(item));
          }
          notifyListeners();
        }
      case WsMessageType.status:
        if (msg.payload['event'] == 'disconnected') {
          _setStatus(ConnectionStatus.disconnected);
        }
      default:
        break;
    }
  }

  // ─── Windowed Fetch ───────────────────────────────────────────────────────

  /// [offset, offset+limit) aralığındaki nem ölçümlerini sunucudan çeker.
  Future<List<HumidityMeasurement>> fetchHumidityWindow(int offset, int limit) async {
    try {
      final body = await _http.fetchHumidityWindow(offset: offset, limit: limit);
      final total = body['total'] as int?;
      if (total != null && total > 0) _totalHumidityCount = total;
      final list = body['data'] as List;
      return list.cast<Map<String, dynamic>>().map(HumidityMeasurement.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  /// [offset, offset+limit) aralığındaki deformasyon ölçümlerini sunucudan çeker.
  Future<List<DeformationMeasurement>> fetchDeformWindow(int offset, int limit) async {
    try {
      final body = await _http.fetchDeformWindow(offset: offset, limit: limit);
      final total = body['total'] as int?;
      if (total != null && total > 0) _totalDeformCount = total;
      final list = body['data'] as List;
      return list.cast<Map<String, dynamic>>().map(DeformationMeasurement.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── SPC Computation ──────────────────────────────────────────────────────

  void _computeSpc() {
    final values = _humidity.map((m) => m.value).toList();
    if (values.length < 2) return;

    _humidityImr = ImrCalculator.calculate(values);
    _humidityCapability = CapabilityCalculator.calculate(
      values: values,
      meanMR: _humidityImr!.meanMR,
      usl: SpecLimits.humidityUSL,
      lsl: SpecLimits.humidityLSL,
    );
    _humidityRisk = RiskCalculator.calculateHumidityRisk(
      values: values,
      mean: _humidityImr!.mean,
      sigma: _humidityImr!.sigmaEstimate,
    );
    _nelsonViolations = NelsonRules.checkAll(
      values,
      mean: _humidityImr!.mean,
      sigma: _humidityImr!.sigmaEstimate,
    );
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  void _setStatus(ConnectionStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws.dispose();
    super.dispose();
  }
}
