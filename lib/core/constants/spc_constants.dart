/// SPC kontrol diyagramı katsayıları (ASTM / Shewhart tabloları).
///
/// n = alt grup büyüklüğü (2..10)
abstract final class SpcConstants {
  /// d₂ — Standart sapma tahmini için MR katsayısı.
  static const Map<int, double> d2 = {
    2: 1.128,
    3: 1.693,
    4: 2.059,
    5: 2.326,
    6: 2.534,
    7: 2.704,
    8: 2.847,
    9: 2.970,
    10: 3.078,
  };

  /// D₃ — R kontrol alt sınırı katsayısı.
  static const Map<int, double> d3 = {
    2: 0.000,
    3: 0.000,
    4: 0.000,
    5: 0.000,
    6: 0.000,
    7: 0.076,
    8: 0.136,
    9: 0.184,
    10: 0.223,
  };

  /// D₄ — R kontrol üst sınırı katsayısı.
  static const Map<int, double> d4 = {
    2: 3.267,
    3: 2.574,
    4: 2.282,
    5: 2.114,
    6: 2.004,
    7: 1.924,
    8: 1.864,
    9: 1.816,
    10: 1.777,
  };

  /// A₂ — X-bar kontrol limiti katsayısı.
  static const Map<int, double> a2 = {
    2: 1.880,
    3: 1.023,
    4: 0.729,
    5: 0.577,
    6: 0.483,
    7: 0.419,
    8: 0.373,
    9: 0.337,
    10: 0.308,
  };

  // ─── I-MR sabit değerleri (n=2) ────────────────────────────────
  static const double imrD2 = 1.128;
  static const double imrD4 = 3.267;

  /// Verilen n için d₂ değerini döner. n ∈ [2,10] dışında ArgumentError fırlatır.
  static double getD2(int n) => _get(d2, n, 'd2');

  /// Verilen n için D₃ değerini döner.
  static double getD3(int n) => _get(d3, n, 'D3');

  /// Verilen n için D₄ değerini döner.
  static double getD4(int n) => _get(d4, n, 'D4');

  /// Verilen n için A₂ değerini döner.
  static double getA2(int n) => _get(a2, n, 'A2');

  static double _get(Map<int, double> table, int n, String name) {
    final val = table[n];
    if (val == null) {
      throw ArgumentError('SPC katsayısı $name için n=$n geçersiz. [2..10]');
    }
    return val;
  }

  /// Desteklenen alt grup büyüklükleri.
  static const List<int> supportedSubgroupSizes = [2, 3, 4, 5, 6, 7, 8, 9, 10];
}
