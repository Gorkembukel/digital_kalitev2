import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../core/models/measurement.dart';

/// REST API handler — HTTP endpoint'leri tanımlar.
class ApiHandler {
  ApiHandler(this._dataStore);

  /// Ölçüm verilerinin tutulduğu paylaşımlı store referansı.
  final ServerDataStore _dataStore;

  Router get router {
    final r = Router();
    r.get('/api/status', _handleStatus);
    r.get('/api/humidity', _handleHumidity);
    r.get('/api/humidity/latest', _handleHumidityLatest);
    r.get('/api/deformation', _handleDeformation);
    r.get('/api/deformation/latest', _handleDeformationLatest);
    return r;
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  Response _handleStatus(Request req) {
    return _json({
      'status': 'running',
      'uptime': _dataStore.uptimeSeconds,
      'humidityCount': _dataStore.humidityData.length,
      'deformationCount': _dataStore.deformationData.length,
      'connectedClients': _dataStore.connectedClients,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Response _handleHumidity(Request req) {
    final limitParam = req.url.queryParameters['limit'];
    final limit = int.tryParse(limitParam ?? '') ?? 200;
    final data = _dataStore.humidityData;
    final slice = data.length > limit ? data.sublist(data.length - limit) : data;
    return _json({
      'count': slice.length,
      'data': slice.map((m) => m.toJson()).toList(),
    });
  }

  Response _handleHumidityLatest(Request req) {
    final data = _dataStore.humidityData;
    if (data.isEmpty) return _json({'data': null});
    return _json({'data': data.last.toJson()});
  }

  Response _handleDeformation(Request req) {
    final limitParam = req.url.queryParameters['limit'];
    final limit = int.tryParse(limitParam ?? '') ?? 100;
    final data = _dataStore.deformationData;
    final slice = data.length > limit ? data.sublist(data.length - limit) : data;
    return _json({
      'count': slice.length,
      'data': slice.map((m) => m.toJson()).toList(),
    });
  }

  Response _handleDeformationLatest(Request req) {
    final data = _dataStore.deformationData;
    if (data.isEmpty) return _json({'data': null});
    return _json({'data': data.last.toJson()});
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Response _json(Map<String, dynamic> body) => Response.ok(
        jsonEncode(body),
        headers: {HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8'},
      );
}

/// Sunucu veri deposu — in-memory, thread-safe değil ama single-isolate'de yeterli.
class ServerDataStore {
  final List<HumidityMeasurement> humidityData = [];
  final List<DeformationMeasurement> deformationData = [];
  int connectedClients = 0;
  final DateTime _startTime = DateTime.now();

  int get uptimeSeconds =>
      DateTime.now().difference(_startTime).inSeconds;

  /// Maksimum in-memory veri sayısı (bellek yönetimi).
  static const int maxHumidityRecords = 5000;
  static const int maxDeformationRecords = 2000;

  void addHumidity(HumidityMeasurement m) {
    humidityData.add(m);
    if (humidityData.length > maxHumidityRecords) {
      humidityData.removeAt(0);
    }
  }

  void addDeformation(DeformationMeasurement m) {
    deformationData.add(m);
    if (deformationData.length > maxDeformationRecords) {
      deformationData.removeAt(0);
    }
  }
}
