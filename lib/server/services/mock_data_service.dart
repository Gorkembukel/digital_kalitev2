import 'dart:math';
import '../../core/models/measurement.dart';
import '../../core/constants/spec_limits.dart';

/// Gerçek sensör verisi olmadığında kullanılan mock veri üreticisi.
/// Gerçek donanım entegrasyonunda bu sınıf kaldırılacak.
abstract final class MockDataService {
  static final _rng = Random();

  // ─── Nem ─────────────────────────────────────────────────────────────────

  /// Tek bir nem ölçümü üretir.
  /// Gerçekçi bir nem süreci simüle eder (otokorelasyon + drift).
  static HumidityMeasurement nextHumidity({
    double? previousValue,
    bool simulateDrift = false,
    bool simulateOoc = false,
  }) {
    final base = previousValue ?? SpecLimits.humidityTarget;

    // %5 ihtimalle biraz daha büyük gürültü
    final noiseScale = _rng.nextDouble() < 0.05 ? 0.15 : 0.06;
    final noise = (_rng.nextDouble() - 0.5) * 2 * noiseScale;

    // Drift simülasyonu
    final drift = simulateDrift ? 0.003 : 0.0;

    // Otokorelasyon: 0.6 önceki değer + 0.4 yeni gürültü
    var value = base * 0.6 + (SpecLimits.humidityTarget + noise + drift) * 0.4;

    // OOC simülasyonu — bazen spec dışına çık
    if (simulateOoc && _rng.nextDouble() < 0.12) {
      value = _rng.nextBool()
          ? SpecLimits.humidityUSL + _rng.nextDouble() * 0.2
          : SpecLimits.humidityLSL - _rng.nextDouble() * 0.2;
    }

    // Sınırla — gerçekçi aralıkta tut
    value = value.clamp(5.0, 7.5);

    return HumidityMeasurement(
      timestamp: DateTime.now(),
      value: double.parse(value.toStringAsFixed(3)),
    );
  }

  /// Belirtilen sayıda geçmiş nem verisi üretir (başlangıç için).
  static List<HumidityMeasurement> generateHumidityHistory({
    int count = 200,
    bool withDrift = false,
  }) {
    final result = <HumidityMeasurement>[];
    double prev = SpecLimits.humidityTarget;
    final now = DateTime.now();

    for (var i = count - 1; i >= 0; i--) {
      final m = nextHumidity(
        previousValue: prev,
        simulateDrift: withDrift && i < 30,
      );
      // Geçmiş timestamp
      final ts = now.subtract(Duration(minutes: i));
      result.add(HumidityMeasurement(timestamp: ts, value: m.value));
      prev = m.value;
    }
    return result;
  }

  // ─── Deformasyon ────────────────────────────────────────────────────────

  static DeformationMeasurement nextDeformation({String? tileId}) {
    double point() {
      final v = (_rng.nextDouble() - 0.4) * 0.8;
      return double.parse(v.toStringAsFixed(3));
    }

    return DeformationMeasurement(
      timestamp: DateTime.now(),
      tileId: tileId ?? 'KARO-${_rng.nextInt(9999).toString().padLeft(4, '0')}',
      point1: point(),
      point2: point(),
      point3: point(),
      point4: point(),
    );
  }

  /// Deformasyon geçmiş verisi üretir.
  static List<DeformationMeasurement> generateDeformationHistory({int count = 100}) {
    final result = <DeformationMeasurement>[];
    final now = DateTime.now();
    for (var i = count - 1; i >= 0; i--) {
      final m = nextDeformation(
        tileId: 'KARO-${(i + 1).toString().padLeft(4, '0')}',
      );
      final ts = now.subtract(Duration(minutes: i * 3));
      result.add(DeformationMeasurement(
        timestamp: ts,
        tileId: m.tileId,
        point1: m.point1,
        point2: m.point2,
        point3: m.point3,
        point4: m.point4,
      ));
    }
    return result;
  }
}
