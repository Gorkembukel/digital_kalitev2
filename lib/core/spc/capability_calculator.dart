import 'dart:math' as math;

/// Kapasite analizi sonuçları.
class CapabilityResult {
  const CapabilityResult({
    required this.mean,
    required this.sigmaShort,
    required this.sigmaLong,
    required this.cp,
    required this.cpu,
    required this.cpl,
    required this.cpk,
    required this.pp,
    required this.ppu,
    required this.ppl,
    required this.ppk,
    required this.ppm,
    required this.usl,
    required this.lsl,
  });

  final double mean;

  /// Kısa dönem sigma (I-MR bazlı): σ̂ = MR̄ / d₂
  final double sigmaShort;

  /// Uzun dönem sigma (popülasyon std): σ_p = std(vals, ddof=0)
  final double sigmaLong;

  // ─── Kısa dönem (potential) ────────────────────────────────────
  final double cp;
  final double cpu;
  final double cpl;
  final double cpk;

  // ─── Uzun dönem (performance) ──────────────────────────────────
  final double pp;
  final double ppu;
  final double ppl;
  final double ppk;

  /// Tahmini PPM (Parts Per Million) — normal dağılım varsayımı.
  final double ppm;

  final double usl;
  final double lsl;

  String get cpkGrade {
    if (cpk >= 1.67) return 'Mükemmel';
    if (cpk >= 1.33) return 'Yeterli';
    if (cpk >= 1.00) return 'Marjinal';
    return 'Yetersiz';
  }
}

/// Kapasite indeksleri hesaplama motoru.
///
/// Tüm metotlar saf fonksiyon — unit-test edilebilir.
abstract final class CapabilityCalculator {
  /// Ana hesaplama metodu.
  ///
  /// [meanMR] = I-MR hesaplamasından gelen MR̄
  /// [usl] / [lsl] = spesifikasyon limitleri
  static CapabilityResult calculate({
    required List<double> values,
    required double meanMR,
    required double usl,
    required double lsl,
  }) {
    assert(values.length >= 2, 'Kapasite için en az 2 değer gerekli.');
    assert(usl > lsl, 'USL, LSL\'den büyük olmalı.');

    final mean = _mean(values);
    final sigmaShort = meanMR / 1.128; // d₂ for n=2
    final sigmaLong = _stddev(values);

    // Kısa dönem
    final cp = sigmaShort == 0 ? double.infinity : (usl - lsl) / (6 * sigmaShort);
    final cpu = sigmaShort == 0 ? double.infinity : (usl - mean) / (3 * sigmaShort);
    final cpl = sigmaShort == 0 ? double.infinity : (mean - lsl) / (3 * sigmaShort);
    final cpk = math.min(cpu, cpl);

    // Uzun dönem
    final pp = sigmaLong == 0 ? double.infinity : (usl - lsl) / (6 * sigmaLong);
    final ppu = sigmaLong == 0 ? double.infinity : (usl - mean) / (3 * sigmaLong);
    final ppl = sigmaLong == 0 ? double.infinity : (mean - lsl) / (3 * sigmaLong);
    final ppk = math.min(ppu, ppl);

    // PPM — P(X > USL) + P(X < LSL), normal dağılım varsayımı
    final ppm = sigmaLong == 0
        ? 0.0
        : (_normalCdfUpper((usl - mean) / sigmaLong) +
               _normalCdfUpper((mean - lsl) / sigmaLong)) *
            1000000;

    return CapabilityResult(
      mean: mean,
      sigmaShort: sigmaShort,
      sigmaLong: sigmaLong,
      cp: cp,
      cpu: cpu,
      cpl: cpl,
      cpk: cpk,
      pp: pp,
      ppu: ppu,
      ppl: ppl,
      ppk: ppk,
      ppm: ppm,
      usl: usl,
      lsl: lsl,
    );
  }

  /// Histogram için bin (çubuk) verileri üretir.
  ///
  /// [binCount] = çubuk sayısı (varsayılan: Sturges kuralı).
  static List<HistogramBin> histogram(
    List<double> values, {
    int? binCount,
    double? lsl,
    double? usl,
  }) {
    if (values.isEmpty) return [];

    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final n = binCount ?? _sturgesBins(values.length);
    final width = (max - min) / n;
    if (width == 0) return [];

    final bins = List.generate(n, (i) {
      final lower = min + i * width;
      final upper = lower + width;
      final count = values.where((v) => i == n - 1 ? v >= lower && v <= upper : v >= lower && v < upper).length;
      final inSpec = (lsl == null || lower >= lsl) && (usl == null || upper <= usl);
      return HistogramBin(lower: lower, upper: upper, count: count, inSpec: inSpec);
    });
    return bins;
  }

  /// Normal dağılım yoğunluk fonksiyonu — grafik eğrisi için.
  static double normalPdf(double x, double mean, double sigma) {
    if (sigma == 0) return 0;
    final z = (x - mean) / sigma;
    return (1 / (sigma * math.sqrt(2 * math.pi))) * math.exp(-0.5 * z * z);
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  static double _mean(List<double> xs) =>
      xs.reduce((a, b) => a + b) / xs.length;

  /// Popülasyon standart sapması (ddof=0).
  static double _stddev(List<double> xs) {
    if (xs.length < 2) return 0;
    final m = _mean(xs);
    final variance = xs.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / xs.length;
    return math.sqrt(variance);
  }

  /// P(Z > z) — standart normal üst kuyruk olasılığı.
  /// Hart (1968) yaklaşımı; istatistik kullanım için yeterli doğruluk.
  static double _normalCdfUpper(double z) {
    if (z < 0) return 1 - _normalCdfUpper(-z);
    if (z > 8) return 0;
    // Abramowitz & Stegun 26.2.17
    const p = 0.2316419;
    const b = [0.319381530, -0.356563782, 1.781477937, -1.821255978, 1.330274429];
    final t = 1 / (1 + p * z);
    final pdf = math.exp(-0.5 * z * z) / math.sqrt(2 * math.pi);
    final poly = b[0] * t +
        b[1] * t * t +
        b[2] * t * t * t +
        b[3] * t * t * t * t +
        b[4] * t * t * t * t * t;
    return pdf * poly;
  }

  static int _sturgesBins(int n) => (1 + 3.322 * math.log(n) / math.ln10).round().clamp(5, 50);
}

/// Tek bir histogram çubuğu.
class HistogramBin {
  const HistogramBin({
    required this.lower,
    required this.upper,
    required this.count,
    required this.inSpec,
  });

  final double lower;
  final double upper;
  final int count;

  /// Bu çubuğun tamamı spesifikasyon içinde mi?
  final bool inSpec;

  double get midpoint => (lower + upper) / 2;
}
