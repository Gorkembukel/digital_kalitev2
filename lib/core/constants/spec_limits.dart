/// Spesifikasyon limitleri — üretim toleransları.
abstract final class SpecLimits {
  // ─── Nem (%rH) ───────────────────────────────────────────────
  static const double humidityLSL = 5.80;
  static const double humidityUSL = 6.30;
  static const double humidityTarget = 6.05;

  // ─── Deformasyon / VitrA Standartları (mm) ───────────────────
  static const double deformVitraLSL = -0.7;
  static const double deformVitraUSL = 1.0;

  // ─── Deformasyon / EN14411 (mm) ──────────────────────────────
  static const double deformEN14411LSL = -2.0;
  static const double deformEN14411USL = 2.0;

  // ─── Kapasite Yeterlilik Sınırları ───────────────────────────
  static const double cpkExcellent = 1.67;
  static const double cpkAdequate = 1.33;
  static const double cpkMarginal = 1.00;
  // cpk < 1.00 → Yetersiz

  // ─── Risk / Alarm Eşikleri (nem için) ────────────────────────
  static const double riskOobCritical = 0.15; // tolerans dışı oran
  static const double riskOobHigh = 0.05;
  static const double riskOobMedium = 0.01;

  static const double riskTrendCritical = 0.01; // |eğim| (30dk pencere)
  static const double riskTrendHigh = 0.005;

  /// Bir değerin nem spesifikasyonu içinde olup olmadığını kontrol eder.
  static bool isHumidityInSpec(double value) =>
      value >= humidityLSL && value <= humidityUSL;

  /// Bir değerin VitrA deformasyon spesifikasyonu içinde olup olmadığını kontrol eder.
  static bool isDeformVitraInSpec(double value) =>
      value >= deformVitraLSL && value <= deformVitraUSL;

  /// Bir değerin EN14411 deformasyon spesifikasyonu içinde olup olmadığını kontrol eder.
  static bool isDeformEN14411InSpec(double value) =>
      value >= deformEN14411LSL && value <= deformEN14411USL;
}
