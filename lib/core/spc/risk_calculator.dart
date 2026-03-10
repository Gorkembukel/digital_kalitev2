import 'dart:math' as math;
import '../models/alarm_level.dart';
import '../constants/spec_limits.dart';
import 'nelson_rules.dart';

/// Risk değerlendirmesi sonucu.
class RiskResult {
  const RiskResult({
    required this.level,
    required this.oobRate,
    required this.trend,
    required this.nelsonViolations,
    required this.reasons,
  });

  /// Hesaplanan alarm seviyesi.
  final AlarmLevel level;

  /// Son 60 ölçümdeki tolerans dışı oran (0.0 – 1.0).
  final double oobRate;

  /// Son 30 ölçümün doğrusal regresyon eğimi.
  final double trend;

  /// Aktif Nelson kural ihlalleri.
  final List<NelsonViolation> nelsonViolations;

  /// Risk seviyesine yol açan gerekçeler.
  final List<String> reasons;

  int get nelsonViolationCount => nelsonViolations.length;
}

/// Nem verisi için risk hesaplama motoru.
///
/// Tüm metotlar saf fonksiyon — unit-test edilebilir.
abstract final class RiskCalculator {
  /// Nem ölçüm listesi için risk seviyesini hesaplar.
  ///
  /// [values]  — zaman sıralı nem değerleri
  /// [mean]    — process ortalaması (ImrResult.mean)
  /// [sigma]   — process sigma (ImrResult.sigmaEstimate)
  static RiskResult calculateHumidityRisk({
    required List<double> values,
    required double mean,
    required double sigma,
  }) {
    if (values.isEmpty) {
      return const RiskResult(
        level: AlarmLevel.low,
        oobRate: 0,
        trend: 0,
        nelsonViolations: [],
        reasons: ['Veri yok'],
      );
    }

    // Son 60 ölçüm
    final last60 = values.length > 60 ? values.sublist(values.length - 60) : List<double>.from(values);
    final oobRate = _oobRate(last60, lsl: SpecLimits.humidityLSL, usl: SpecLimits.humidityUSL);

    // Son 30 ölçüm için trend (doğrusal regresyon eğimi)
    final last30 = values.length > 30 ? values.sublist(values.length - 30) : List<double>.from(values);
    final trend = _linearSlope(last30);

    // Nelson kuralları (tüm veri üzerinde)
    final violations = NelsonRules.checkAll(values, mean: mean, sigma: sigma);

    // Risk seviyesi ve gerekçeler
    final reasons = <String>[];
    AlarmLevel level = AlarmLevel.low;

    if (oobRate > SpecLimits.riskOobCritical) {
      level = AlarmLevel.critical;
      reasons.add('Tolerans dışı oran %${(oobRate * 100).toStringAsFixed(1)} > %15 (KRİTİK)');
    }
    if (trend.abs() > SpecLimits.riskTrendCritical) {
      level = AlarmLevel.critical;
      reasons.add('Trend eğimi ${trend.toStringAsFixed(4)} > 0.01 (KRİTİK)');
    }

    if (level != AlarmLevel.critical) {
      if (oobRate > SpecLimits.riskOobHigh) {
        level = AlarmLevel.high;
        reasons.add('Tolerans dışı oran %${(oobRate * 100).toStringAsFixed(1)} > %5');
      }
      if (trend.abs() > SpecLimits.riskTrendHigh) {
        level = _max(level, AlarmLevel.high);
        reasons.add('Trend eğimi ${trend.toStringAsFixed(4)} > 0.005');
      }
    }

    if (level == AlarmLevel.low && oobRate > SpecLimits.riskOobMedium) {
      level = AlarmLevel.medium;
      reasons.add('Tolerans dışı oran %${(oobRate * 100).toStringAsFixed(1)} > %1');
    }

    if (violations.isNotEmpty) {
      level = _max(level, AlarmLevel.medium);
      reasons.add('${violations.length} Nelson kural ihlali tespit edildi');
    }

    if (reasons.isEmpty) {
      reasons.add('Süreç kontrol altında');
    }

    return RiskResult(
      level: level,
      oobRate: oobRate,
      trend: trend,
      nelsonViolations: violations,
      reasons: List.unmodifiable(reasons),
    );
  }

  /// Tolerans dışı oran hesaplar.
  static double oobRate(List<double> values, {required double lsl, required double usl}) =>
      _oobRate(values, lsl: lsl, usl: usl);

  /// Son [windowSize] ölçüm için trend eğimi döner.
  static double trendSlope(List<double> values, {int windowSize = 30}) {
    final window = values.length > windowSize
        ? values.sublist(values.length - windowSize)
        : List<double>.from(values);
    return _linearSlope(window);
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  static double _oobRate(List<double> values, {required double lsl, required double usl}) {
    if (values.isEmpty) return 0;
    final oob = values.where((v) => v < lsl || v > usl).length;
    return oob / values.length;
  }

  /// Basit doğrusal regresyon eğimi: Σ((xi-x̄)(yi-ȳ)) / Σ((xi-x̄)²)
  static double _linearSlope(List<double> y) {
    final n = y.length;
    if (n < 2) return 0;

    final xMean = (n - 1) / 2.0;
    final yMean = y.reduce((a, b) => a + b) / n;

    double num = 0, den = 0;
    for (var i = 0; i < n; i++) {
      final dx = i - xMean;
      num += dx * (y[i] - yMean);
      den += dx * dx;
    }
    return den == 0 ? 0 : num / den;
  }

  /// İki alarm seviyesinden daha yüksek olanı döner.
  static AlarmLevel _max(AlarmLevel a, AlarmLevel b) =>
      a.priority >= b.priority ? a : b;
}

/// Özet istatistikler — birden fazla yerde kullanılır.
class SummaryStats {
  const SummaryStats({
    required this.mean,
    required this.min,
    required this.max,
    required this.stddev,
    required this.count,
  });

  final double mean;
  final double min;
  final double max;
  final double stddev;
  final int count;

  factory SummaryStats.fromValues(List<double> values) {
    if (values.isEmpty) {
      return const SummaryStats(mean: 0, min: 0, max: 0, stddev: 0, count: 0);
    }
    final mean = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    return SummaryStats(
      mean: mean,
      min: min,
      max: max,
      stddev: math.sqrt(variance),
      count: values.length,
    );
  }
}
