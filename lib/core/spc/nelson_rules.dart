/// Nelson kural ihlali — hangi kural, hangi indeksler.
class NelsonViolation {
  const NelsonViolation({
    required this.rule,
    required this.indices,
    required this.description,
  });

  /// Kural numarası (1–8).
  final int rule;

  /// İhlali oluşturan nokta indeksleri (orijinal values listesine göre).
  final List<int> indices;

  final String description;

  @override
  String toString() => 'Nelson K$rule: $description — indeksler: $indices';
}

/// Nelson 8 Kuralı kontrol motoru.
///
/// Tüm metotlar saf fonksiyon — unit-test edilebilir.
abstract final class NelsonRules {
  /// Verilen değerler için tüm 8 Nelson kuralını kontrol eder.
  ///
  /// [values]  — zaman sıralı ölçüm değerleri
  /// [mean]    — x̄ (kontrol merkez çizgisi)
  /// [sigma]   — process sigma (ImrCalculator.sigmaEstimate)
  static List<NelsonViolation> checkAll(
    List<double> values, {
    required double mean,
    required double sigma,
  }) {
    final violations = <NelsonViolation>[];

    void add(int rule, List<int> idx, String desc) {
      if (idx.isNotEmpty) violations.add(NelsonViolation(rule: rule, indices: idx, description: desc));
    }

    add(1, rule1(values, mean: mean, sigma: sigma), 'Bir nokta |z| > 3σ dışında');
    add(2, rule2(values, mean: mean), '9 ardışık nokta ortalamanın aynı tarafında');
    add(3, rule3(values), '6 ardışık nokta sürekli artıyor veya azalıyor');
    add(4, rule4(values), '14 ardışık nokta zigzag (yön değiştiriyor)');
    add(5, rule5(values, mean: mean, sigma: sigma), '2/3 nokta ±2σ dışında (aynı taraf)');
    add(6, rule6(values, mean: mean, sigma: sigma), '4/5 nokta ±1σ dışında (aynı taraf)');
    add(7, rule7(values, mean: mean, sigma: sigma), '15 ardışık nokta ±1σ içinde');
    add(8, rule8(values, mean: mean, sigma: sigma), '8 ardışık nokta ±1σ dışında (iki taraf)');

    return violations;
  }

  // ─── K1 ─────────────────────────────────────────────────────────────────────
  /// 1 nokta |z| > 3 (3σ dışı)
  static List<int> rule1(List<double> values, {required double mean, required double sigma}) {
    if (sigma == 0) return [];
    final result = <int>[];
    for (var i = 0; i < values.length; i++) {
      if (((values[i] - mean) / sigma).abs() > 3) result.add(i);
    }
    return result;
  }

  // ─── K2 ─────────────────────────────────────────────────────────────────────
  /// 9 ardışık nokta ortalamanın aynı tarafında
  static List<int> rule2(List<double> values, {required double mean}) {
    return _runOnSameSide(values, mean: mean, runLength: 9);
  }

  // ─── K3 ─────────────────────────────────────────────────────────────────────
  /// 6 ardışık nokta sürekli artıyor veya azalıyor
  static List<int> rule3(List<double> values) {
    if (values.length < 6) return [];
    const run = 6;
    final result = <int>{};
    for (var i = 0; i <= values.length - run; i++) {
      final slice = values.sublist(i, i + run);
      bool allUp = true, allDown = true;
      for (var j = 1; j < slice.length; j++) {
        if (slice[j] <= slice[j - 1]) allUp = false;
        if (slice[j] >= slice[j - 1]) allDown = false;
      }
      if (allUp || allDown) {
        for (var k = i; k < i + run; k++) { result.add(k); }
      }
    }
    return result.toList()..sort();
  }

  // ─── K4 ─────────────────────────────────────────────────────────────────────
  /// 14 ardışık nokta zigzag (sürekli yön değiştiriyor)
  static List<int> rule4(List<double> values) {
    if (values.length < 14) return [];
    const run = 14;
    final result = <int>{};
    for (var i = 0; i <= values.length - run; i++) {
      final slice = values.sublist(i, i + run);
      bool zigzag = true;
      for (var j = 1; j < slice.length - 1; j++) {
        final prevDir = slice[j] - slice[j - 1];
        final nextDir = slice[j + 1] - slice[j];
        if (prevDir * nextDir >= 0) {
          zigzag = false;
          break;
        }
      }
      if (zigzag) {
        for (var k = i; k < i + run; k++) { result.add(k); }
      }
    }
    return result.toList()..sort();
  }

  // ─── K5 ─────────────────────────────────────────────────────────────────────
  /// 3 noktadan 2'si aynı tarafta ±2σ dışı
  static List<int> rule5(List<double> values, {required double mean, required double sigma}) {
    if (sigma == 0 || values.length < 3) return [];
    final result = <int>{};
    for (var i = 0; i <= values.length - 3; i++) {
      final slice = values.sublist(i, i + 3);
      final pos2sigma = slice.where((v) => v > mean + 2 * sigma).length;
      final neg2sigma = slice.where((v) => v < mean - 2 * sigma).length;
      if (pos2sigma >= 2 || neg2sigma >= 2) {
        for (var k = i; k < i + 3; k++) { result.add(k); }
      }
    }
    return result.toList()..sort();
  }

  // ─── K6 ─────────────────────────────────────────────────────────────────────
  /// 5 noktadan 4'ü aynı tarafta ±1σ dışı
  static List<int> rule6(List<double> values, {required double mean, required double sigma}) {
    if (sigma == 0 || values.length < 5) return [];
    final result = <int>{};
    for (var i = 0; i <= values.length - 5; i++) {
      final slice = values.sublist(i, i + 5);
      final pos1sigma = slice.where((v) => v > mean + sigma).length;
      final neg1sigma = slice.where((v) => v < mean - sigma).length;
      if (pos1sigma >= 4 || neg1sigma >= 4) {
        for (var k = i; k < i + 5; k++) { result.add(k); }
      }
    }
    return result.toList()..sort();
  }

  // ─── K7 ─────────────────────────────────────────────────────────────────────
  /// 15 ardışık nokta ±1σ içinde (katmanlaşma)
  static List<int> rule7(List<double> values, {required double mean, required double sigma}) {
    if (sigma == 0 || values.length < 15) return [];
    const run = 15;
    final result = <int>{};
    for (var i = 0; i <= values.length - run; i++) {
      final slice = values.sublist(i, i + run);
      final allIn1Sigma = slice.every((v) => (v - mean).abs() <= sigma);
      if (allIn1Sigma) {
        for (var k = i; k < i + run; k++) { result.add(k); }
      }
    }
    return result.toList()..sort();
  }

  // ─── K8 ─────────────────────────────────────────────────────────────────────
  /// 8 ardışık nokta ortalamanın iki tarafında ±1σ dışı (karma)
  static List<int> rule8(List<double> values, {required double mean, required double sigma}) {
    if (sigma == 0 || values.length < 8) return [];
    const run = 8;
    final result = <int>{};
    for (var i = 0; i <= values.length - run; i++) {
      final slice = values.sublist(i, i + run);
      final allOutside1Sigma = slice.every((v) => (v - mean).abs() > sigma);
      if (allOutside1Sigma) {
        for (var k = i; k < i + run; k++) { result.add(k); }
      }
    }
    return result.toList()..sort();
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  static List<int> _runOnSameSide(
    List<double> values, {
    required double mean,
    required int runLength,
  }) {
    if (values.length < runLength) return [];
    final result = <int>{};
    var run = 1;
    for (var i = 1; i < values.length; i++) {
      final sameSign = (values[i] > mean) == (values[i - 1] > mean);
      if (sameSign && values[i] != mean) {
        run++;
        if (run >= runLength) {
          for (var k = i - runLength + 1; k <= i; k++) { result.add(k); }
        }
      } else {
        run = 1;
      }
    }
    return result.toList()..sort();
  }
}
