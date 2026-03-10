import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/models/measurement.dart';

/// HTTP üzerinden sunucudan veri çeken servis.
class HttpClientService {
  HttpClientService({required this.baseUrl});

  final String baseUrl;

  static const _timeout = Duration(seconds: 10);

  // ─── Status ───────────────────────────────────────────────────────────────

  /// Sunucunun erişilebilir olup olmadığını kontrol eder.
  Future<bool> ping() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/status'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchStatus() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/status'))
        .timeout(_timeout);
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Humidity ─────────────────────────────────────────────────────────────

  Future<List<HumidityMeasurement>> fetchHumidity({int limit = 300}) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/humidity?limit=$limit'))
        .timeout(_timeout);
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List;
    return list
        .cast<Map<String, dynamic>>()
        .map(HumidityMeasurement.fromJson)
        .toList();
  }

  // ─── Deformation ──────────────────────────────────────────────────────────

  Future<List<DeformationMeasurement>> fetchDeformation({int limit = 100}) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/deformation?limit=$limit'))
        .timeout(_timeout);
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List;
    return list
        .cast<Map<String, dynamic>>()
        .map(DeformationMeasurement.fromJson)
        .toList();
  }

  // ─── Windowed (offset/limit) ──────────────────────────────────────────────

  /// Ham JSON döner: {'total': int, 'offset': int, 'count': int, 'data': List}
  Future<Map<String, dynamic>> fetchHumidityWindow({
    required int offset,
    required int limit,
  }) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/humidity?offset=$offset&limit=$limit'))
        .timeout(_timeout);
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<int> fetchHumidityCount() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/humidity/count'))
          .timeout(_timeout);
      _checkStatus(res);
      return (jsonDecode(res.body) as Map<String, dynamic>)['total'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> fetchDeformWindow({
    required int offset,
    required int limit,
  }) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/deformation?offset=$offset&limit=$limit'))
        .timeout(_timeout);
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<int> fetchDeformCount() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/deformation/count'))
          .timeout(_timeout);
      _checkStatus(res);
      return (jsonDecode(res.body) as Map<String, dynamic>)['total'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  void _checkStatus(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }
  }
}
