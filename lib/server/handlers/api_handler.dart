import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../core/models/measurement.dart';
import '../services/file_reader_service.dart';

/// REST API handler — HTTP endpoint'leri tanımlar.
class ApiHandler {
  ApiHandler(this._dataStore);

  /// Ölçüm verilerinin tutulduğu paylaşımlı store referansı.
  final ServerDataStore _dataStore;

  Router get router {
    final r = Router();
    r.get('/api/status', _handleStatus);
    r.get('/api/humidity/count', _handleHumidityCount);
    r.get('/api/humidity/latest', _handleHumidityLatest);
    r.get('/api/humidity', _handleHumidity);
    r.get('/api/deformation/count', _handleDeformCount);
    r.get('/api/deformation/latest', _handleDeformationLatest);
    r.get('/api/deformation', _handleDeformation);
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

  Response _handleHumidityCount(Request req) =>
      _json({'total': _dataStore.humidityTotalCount});

  Response _handleDeformCount(Request req) =>
      _json({'total': _dataStore.deformTotalCount});

  Future<Response> _handleHumidity(Request req) async {
    final limitParam = req.url.queryParameters['limit'];
    final offsetParam = req.url.queryParameters['offset'];
    final limit = int.tryParse(limitParam ?? '') ?? 300;
    final offset = int.tryParse(offsetParam ?? '');

    if (offset != null && _dataStore.csvPath != null && _dataStore.csvPath!.isNotEmpty) {
      try {
        final path = _dataStore.csvPath!;
        final rows = await Isolate.run(
          () => FileReaderService.readCsvRange(path, offset, limit),
        );
        return _json({
          'total': _dataStore.humidityTotalCount,
          'offset': offset,
          'count': rows.length,
          'data': rows.map((m) => m.toJson()).toList(),
        });
      } catch (_) {}
    }
    // Fallback: from RAM
    final data = _dataStore.humidityData;
    final slice = data.length > limit ? data.sublist(data.length - limit) : data;
    return _json({
      'total': _dataStore.humidityTotalCount > 0 ? _dataStore.humidityTotalCount : slice.length,
      'offset': _dataStore.humidityTotalCount - slice.length,
      'count': slice.length,
      'data': slice.map((m) => m.toJson()).toList(),
    });
  }

  Response _handleHumidityLatest(Request req) {
    final data = _dataStore.humidityData;
    if (data.isEmpty) return _json({'data': null});
    return _json({'data': data.last.toJson()});
  }

  Future<Response> _handleDeformation(Request req) async {
    final limitParam = req.url.queryParameters['limit'];
    final offsetParam = req.url.queryParameters['offset'];
    final limit = int.tryParse(limitParam ?? '') ?? 100;
    final offset = int.tryParse(offsetParam ?? '');

    if (offset != null && _dataStore.xlsxPath != null && _dataStore.xlsxPath!.isNotEmpty) {
      try {
        final path = _dataStore.xlsxPath!;
        final rows = await Isolate.run(
          () => FileReaderService.readXlsxRange(path, offset, limit),
        );
        return _json({
          'total': _dataStore.deformTotalCount,
          'offset': offset,
          'count': rows.length,
          'data': rows.map((m) => m.toJson()).toList(),
        });
      } catch (_) {}
    }
    // Fallback: from RAM
    final data = _dataStore.deformationData;
    final slice = data.length > limit ? data.sublist(data.length - limit) : data;
    return _json({
      'total': _dataStore.deformTotalCount > 0 ? _dataStore.deformTotalCount : slice.length,
      'offset': _dataStore.deformTotalCount - slice.length,
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

  // ─── Windowing support ────────────────────────────────────────────────────
  String? csvPath;
  String? xlsxPath;
  int humidityTotalCount = 0;
  int deformTotalCount = 0;
  static const int kRamBuffer = 1000; // rows in RAM

  int get uptimeSeconds =>
      DateTime.now().difference(_startTime).inSeconds;

  /// Maksimum in-memory streaming kaydı (canlı yayında sınır — bulk yüklemede uygulanmaz).
  static const int maxHumidityRecords = 50000;
  static const int maxDeformationRecords = 20000;

  /// Tek tek canlı veri ekle (cap uygulanır).
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

  /// Toplu dosya yüklemesi — cap uygulamaz, tüm veriyi direkt ekler.
  void loadHumidityBulk(List<HumidityMeasurement> rows) {
    humidityData.addAll(rows);
  }

  void loadDeformationBulk(List<DeformationMeasurement> rows) {
    deformationData.addAll(rows);
  }
}
