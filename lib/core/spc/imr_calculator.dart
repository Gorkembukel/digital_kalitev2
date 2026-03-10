import '../constants/spc_constants.dart';

/// I-MR (Individuals & Moving Range) kontrol diyagramı sonuçları.
class ImrResult {
  const ImrResult({
    required this.values,
    required this.movingRanges,
    required this.mean,
    required this.meanMR,
    required this.sigmaEstimate,
    required this.uclI,
    required this.lclI,
    required this.uclMR,
    required this.oocIndividuals,
    required this.oocMovingRanges,
  });

  /// Ham ölçüm değerleri.
  final List<double> values;

  /// Hareketli aralıklar MR[i] = |val[i] - val[i-1]|, uzunluk = values.length - 1.
  final List<double> movingRanges;

  /// Genel ortalama x̄.
  final double mean;

  /// MR ortalaması R̄_MR.
  final double meanMR;

  /// Kısa dönem sigma tahmini σ = MR̄ / d₂.
  final double sigmaEstimate;

  /// Bireysel değerler üst kontrol sınırı.
  final double uclI;

  /// Bireysel değerler alt kontrol sınırı.
  final double lclI;

  /// Hareketli aralık üst kontrol sınırı.
  final double uclMR;

  /// Kontrol dışı bireysel değerlerin indeksleri.
  final List<int> oocIndividuals;

  /// Kontrol dışı hareketli aralıkların indeksleri (MR dizisine göre).
  final List<int> oocMovingRanges;

  /// Toplam OOC nokta sayısı (I + MR).
  int get totalOoc => oocIndividuals.length + oocMovingRanges.length;

  /// Kontrol dışı oran (sadece bireysel değerlere göre).
  double get oocRate =>
      values.isEmpty ? 0.0 : oocIndividuals.length / values.length;
}

/// I-MR kontrol diyagramı hesaplama motoru.
///
/// Tüm metotlar saf fonksiyon — state tutmaz, unit-test edilebilir.
abstract final class ImrCalculator {
  /// Verilen değer listesi için I-MR sonucunu hesaplar.
  ///
  /// [values] en az 2 elemanlı olmalıdır.
  static ImrResult calculate(List<double> values) {
    assert(values.length >= 2, 'I-MR için en az 2 veri noktası gerekli.');

    final mean = _mean(values);
    final mrs = _movingRanges(values);
    final meanMR = _mean(mrs);

    const d2 = SpcConstants.imrD2;
    const d4 = SpcConstants.imrD4;

    final sigma = meanMR / d2;
    final uclI = mean + 3 * sigma;
    final lclI = mean - 3 * sigma;
    final uclMR = d4 * meanMR;

    final oocI = <int>[];
    for (var i = 0; i < values.length; i++) {
      if (values[i] > uclI || values[i] < lclI) oocI.add(i);
    }

    final oocMR = <int>[];
    for (var i = 0; i < mrs.length; i++) {
      if (mrs[i] > uclMR) oocMR.add(i);
    }

    return ImrResult(
      values: List.unmodifiable(values),
      movingRanges: List.unmodifiable(mrs),
      mean: mean,
      meanMR: meanMR,
      sigmaEstimate: sigma,
      uclI: uclI,
      lclI: lclI,
      uclMR: uclMR,
      oocIndividuals: List.unmodifiable(oocI),
      oocMovingRanges: List.unmodifiable(oocMR),
    );
  }

  /// Verilen indeksteki z-skoru hesaplar.
  static double zScore(double value, double mean, double sigma) {
    if (sigma == 0) return 0;
    return (value - mean) / sigma;
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  static double _mean(List<double> xs) {
    if (xs.isEmpty) return 0;
    return xs.reduce((a, b) => a + b) / xs.length;
  }

  static List<double> _movingRanges(List<double> values) {
    final mrs = <double>[];
    for (var i = 1; i < values.length; i++) {
      mrs.add((values[i] - values[i - 1]).abs());
    }
    return mrs;
  }
}
