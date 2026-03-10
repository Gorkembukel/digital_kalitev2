/// Nem ölçümü veri modeli.
class HumidityMeasurement {
  final DateTime timestamp;
  final double value; // %rH

  const HumidityMeasurement({
    required this.timestamp,
    required this.value,
  });

  factory HumidityMeasurement.fromJson(Map<String, dynamic> json) =>
      HumidityMeasurement(
        timestamp: DateTime.parse(json['timestamp'] as String),
        value: (json['value'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'value': value,
      };

  @override
  String toString() => 'HumidityMeasurement($timestamp, ${value.toStringAsFixed(3)} %rH)';
}

/// Deformasyon ölçümü veri modeli (karo başına 4 nokta).
class DeformationMeasurement {
  final DateTime timestamp;
  final String tileId;
  final double point1; // mm
  final double point2; // mm
  final double point3; // mm
  final double point4; // mm

  const DeformationMeasurement({
    required this.timestamp,
    required this.tileId,
    required this.point1,
    required this.point2,
    required this.point3,
    required this.point4,
  });

  /// 4 noktanın ortalaması.
  double get average => (point1 + point2 + point3 + point4) / 4.0;

  /// 4 noktanın aralığı (max - min).
  double get range {
    final values = [point1, point2, point3, point4];
    return values.reduce((a, b) => a > b ? a : b) -
        values.reduce((a, b) => a < b ? a : b);
  }

  List<double> get points => [point1, point2, point3, point4];

  factory DeformationMeasurement.fromJson(Map<String, dynamic> json) =>
      DeformationMeasurement(
        timestamp: DateTime.parse(json['timestamp'] as String),
        tileId: json['tile_id'] as String,
        point1: (json['p1'] as num).toDouble(),
        point2: (json['p2'] as num).toDouble(),
        point3: (json['p3'] as num).toDouble(),
        point4: (json['p4'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'tile_id': tileId,
        'p1': point1,
        'p2': point2,
        'p3': point3,
        'p4': point4,
      };

  @override
  String toString() =>
      'DeformationMeasurement($tileId, avg=${average.toStringAsFixed(3)}mm)';
}

/// Vardiya tanımı.
enum Shift {
  morning, // 06:00 – 14:00
  afternoon, // 14:00 – 22:00
  night; // 22:00 – 06:00

  String get label => switch (this) {
        Shift.morning => 'Sabah (06–14)',
        Shift.afternoon => 'Öğleden Sonra (14–22)',
        Shift.night => 'Gece (22–06)',
      };

  /// Verilen saate göre vardiyayı belirler.
  static Shift fromHour(int hour) {
    if (hour >= 6 && hour < 14) return Shift.morning;
    if (hour >= 14 && hour < 22) return Shift.afternoon;
    return Shift.night;
  }

  static Shift fromDateTime(DateTime dt) => fromHour(dt.hour);
}
