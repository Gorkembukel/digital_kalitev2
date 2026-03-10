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

  // ─── Private ──────────────────────────────────────────────────────────────

  void _checkStatus(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }
  }
}
