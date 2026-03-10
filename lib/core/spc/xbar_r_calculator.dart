import '../constants/spc_constants.dart';

/// Tek bir alt grup.
class Subgroup {
  const Subgroup({
    required this.index,
    required this.values,
    required this.mean,
    required this.range,
  });

  final int index;
  final List<double> values;

  /// Grup ortalaması x̄.
  final double mean;

  /// Grup aralığı R = max - min.
  final double range;
}

/// X-bar / R kontrol diyagramı sonuçları.
class XbarRResult {
  const XbarRResult({
    required this.subgroups,
    required this.grandMean,
    required this.meanRange,
    required this.sigmaEstimate,
    required this.uclXbar,
    required this.lclXbar,
    required this.uclR,
    required this.lclR,
    required this.oocXbar,
    required this.oocR,
    required this.subgroupSize,
  });

  final List<Subgroup> subgroups;

  /// Genel ortalama x̄̄.
  final double grandMean;

  /// Ortalama aralık R̄.
  final double meanRange;

  /// Sigma tahmini R̄ / d₂.
  final double sigmaEstimate;

  final double uclXbar;
  final double lclXbar;
  final double uclR;
  final double lclR;

  /// Kontrol dışı X-bar nokta indeksleri (subgroups listesine göre).
  final List<int> oocXbar;

  /// Kontrol dışı R nokta indeksleri.
  final List<int> oocR;

  final int subgroupSize;

  int get totalOoc => oocXbar.length + oocR.length;
}

/// X-bar / R kontrol diyagramı hesaplama motoru.
abstract final class XbarRCalculator {
  /// [values] listesini [n] büyüklüğünde alt gruplara bölerek X-bar/R hesaplar.
  ///
  /// Kalan veriler (tam grup oluşturmayan) göz ardı edilir.
  /// [n] ∈ [2, 10] olmalıdır.
  static XbarRResult calculate(List<double> values, {required int n}) {
    assert(
      SpcConstants.supportedSubgroupSizes.contains(n),
      'Alt grup büyüklüğü n=$n desteklenmiyor. [2..10] aralığında olmalı.',
    );
    assert(values.length >= n, 'Yetersiz veri: en az $n nokta gerekli.');

    final subgroups = _buildSubgroups(values, n);

    final grandMean = _mean(subgroups.map((s) => s.mean).toList());
    final meanRange = _mean(subgroups.map((s) => s.range).toList());

    final a2 = SpcConstants.getA2(n);
    final d2 = SpcConstants.getD2(n);
    final d3 = SpcConstants.getD3(n);
    final d4 = SpcConstants.getD4(n);

    final sigma = meanRange / d2;
    final uclXbar = grandMean + a2 * meanRange;
    final lclXbar = grandMean - a2 * meanRange;
    final uclR = d4 * meanRange;
    final lclR = d3 * meanRange;

    final oocXbar = <int>[];
    final oocR = <int>[];

    for (var i = 0; i < subgroups.length; i++) {
      final s = subgroups[i];
      if (s.mean > uclXbar || s.mean < lclXbar) oocXbar.add(i);
      if (s.range > uclR || s.range < lclR) oocR.add(i);
    }

    return XbarRResult(
      subgroups: List.unmodifiable(subgroups),
      grandMean: grandMean,
      meanRange: meanRange,
      sigmaEstimate: sigma,
      uclXbar: uclXbar,
      lclXbar: lclXbar,
      uclR: uclR,
      lclR: lclR,
      oocXbar: List.unmodifiable(oocXbar),
      oocR: List.unmodifiable(oocR),
      subgroupSize: n,
    );
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  static List<Subgroup> _buildSubgroups(List<double> values, int n) {
    final result = <Subgroup>[];
    final groupCount = values.length ~/ n;

    for (var g = 0; g < groupCount; g++) {
      final slice = values.sublist(g * n, g * n + n);
      final mean = _mean(slice);
      final range = slice.reduce((a, b) => a > b ? a : b) -
          slice.reduce((a, b) => a < b ? a : b);
      result.add(Subgroup(index: g, values: slice, mean: mean, range: range));
    }
    return result;
  }

  static double _mean(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
}
