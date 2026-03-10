import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import '../../core/models/measurement.dart';

/// CSV ve XLSX dosyalarından ölçüm verisi okuyan servis.
abstract final class FileReaderService {
  // ─── CSV — Nem ─────────────────────────────────────────────────────────────

  /// CSV dosyasını okur ve tüm geçerli nem ölçümlerini döner.
  /// Format: zaman | nem | alt tolerans | üst tolerans
  /// Değer: "5.93 %rH" gibi string.
  static List<HumidityMeasurement> readCsv(String path) {
    final file = File(path);
    if (!file.existsSync()) return [];

    final lines = file.readAsLinesSync();
    final result = <HumidityMeasurement>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Ayırıcıyı otomatik tespit et (tab veya noktalı virgül veya virgül)
      final sep = _detectSeparator(line);
      final cols = line.split(sep);
      if (cols.length < 2) continue;

      // İlk sütun zaman, ikinci sütun nem değeri
      final tsRaw = cols[0].trim();
      final valRaw = cols[1].trim();

      // Sayısal içermiyorsa header satırı — atla
      if (!_hasDigit(valRaw)) continue;

      final dt = _parseDateTime(tsRaw);
      if (dt == null) continue;

      final value = _parseHumidityValue(valRaw);
      if (value == null) continue;

      result.add(HumidityMeasurement(timestamp: dt, value: value));
    }

    return result;
  }

  // ─── XLSX — Deformasyon ────────────────────────────────────────────────────

  /// XLSX dosyasını okur ve tüm geçerli deformasyon ölçümlerini döner.
  /// Sütunlar: 0=makine, 1=ürün kodu, 2=ebat, 3=ton/parti,
  ///            4=P1, 5=P2, 6=P3, 7=P4, 8=VitrA tolerans, 9=EN14411 tolerans
  /// İlk 2 satır başlık — atlanır.
  static List<DeformationMeasurement> readXlsx(String path) {
    final file = File(path);
    if (!file.existsSync()) return [];

    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    // İlk sayfayı kullan
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null) return [];

    final rows = sheet.rows;
    final result = <DeformationMeasurement>[];

    // Toplam satır sayısına göre geriye dönük zaman damgası ata
    // (XLSX'de timestamp sütunu yok — synthetic)
    final dataRowCount = rows.length - 2; // 2 başlık satırı
    if (dataRowCount <= 0) return [];

    final now = DateTime.now();

    for (int i = 2; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 8) continue;

      final p1 = _cellDouble(row, 4);
      final p2 = _cellDouble(row, 5);
      final p3 = _cellDouble(row, 6);
      final p4 = _cellDouble(row, 7);

      if (p1 == null || p2 == null || p3 == null || p4 == null) continue;

      // Geriye dönük zaman ata — her veri 5dk aralıklı varsayım
      final minutesAgo = (rows.length - 1 - i) * 5;
      final timestamp = now.subtract(Duration(minutes: minutesAgo));

      // Ürün/makine bilgisi tileId için
      final machine = _cellString(row, 0);
      final product = _cellString(row, 1);
      final tileId = '${machine}_$product'.replaceAll(' ', '_');

      result.add(DeformationMeasurement(
        timestamp: timestamp,
        point1: p1,
        point2: p2,
        point3: p3,
        point4: p4,
        tileId: tileId.isEmpty ? 'tile_${i - 1}' : tileId,
      ));
    }

    return result;
  }

  // ─── CSV — Sayım & Aralık ──────────────────────────────────────────────────

  /// Sadece geçerli veri satırlarını sayar (başlık ve boş satırlar hariç).
  static int getCsvRowCount(String path) {
    final file = File(path);
    if (!file.existsSync()) return 0;
    final lines = file.readAsLinesSync();
    int count = 0;
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final sep = _detectSeparator(line);
      final cols = line.split(sep);
      if (cols.length < 2) continue;
      final valRaw = cols[1].trim();
      if (!_hasDigit(valRaw)) continue;
      final dt = _parseDateTime(cols[0].trim());
      if (dt == null) continue;
      if (_parseHumidityValue(valRaw) == null) continue;
      count++;
    }
    return count;
  }

  /// [offset] kaçıncı geçerli satırdan başlanacağı (0-based). [limit] kaç satır.
  static List<HumidityMeasurement> readCsvRange(String path, int offset, int limit) {
    final file = File(path);
    if (!file.existsSync()) return [];
    final lines = file.readAsLinesSync();
    final result = <HumidityMeasurement>[];
    int validIdx = 0;
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final sep = _detectSeparator(line);
      final cols = line.split(sep);
      if (cols.length < 2) continue;
      final valRaw = cols[1].trim();
      if (!_hasDigit(valRaw)) continue;
      final dt = _parseDateTime(cols[0].trim());
      if (dt == null) continue;
      final value = _parseHumidityValue(valRaw);
      if (value == null) continue;
      if (validIdx >= offset && validIdx < offset + limit) {
        result.add(HumidityMeasurement(timestamp: dt, value: value));
      }
      validIdx++;
      if (validIdx >= offset + limit) break;
    }
    return result;
  }

  // ─── XLSX — Sayım & Aralık ─────────────────────────────────────────────────

  static int getXlsxRowCount(String path) {
    final file = File(path);
    if (!file.existsSync()) return 0;
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null) return 0;
    int count = 0;
    for (int i = 2; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.length < 8) continue;
      if (_cellDouble(row, 4) != null && _cellDouble(row, 5) != null &&
          _cellDouble(row, 6) != null && _cellDouble(row, 7) != null) {
        count++;
      }
    }
    return count;
  }

  static List<DeformationMeasurement> readXlsxRange(String path, int offset, int limit) {
    final file = File(path);
    if (!file.existsSync()) return [];
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null) return [];

    // Geçerli satır indekslerini topla
    final allValid = <int>[];
    for (int i = 2; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.length < 8) continue;
      if (_cellDouble(row, 4) != null && _cellDouble(row, 5) != null &&
          _cellDouble(row, 6) != null && _cellDouble(row, 7) != null) {
        allValid.add(i);
      }
    }

    final total = allValid.length;
    final result = <DeformationMeasurement>[];
    final now = DateTime.now();

    for (int vi = offset; vi < offset + limit && vi < total; vi++) {
      final i = allValid[vi];
      final row = sheet.rows[i];
      final p1 = _cellDouble(row, 4)!;
      final p2 = _cellDouble(row, 5)!;
      final p3 = _cellDouble(row, 6)!;
      final p4 = _cellDouble(row, 7)!;
      final minutesAgo = (total - 1 - vi) * 5;
      final timestamp = now.subtract(Duration(minutes: minutesAgo));
      final machine = _cellString(row, 0);
      final product = _cellString(row, 1);
      final tileId = '${machine}_$product'.replaceAll(' ', '_');
      result.add(DeformationMeasurement(
        timestamp: timestamp, point1: p1, point2: p2, point3: p3, point4: p4,
        tileId: tileId.isEmpty ? 'tile_$vi' : tileId,
      ));
    }
    return result;
  }

  // ─── CSV Tail (byte-offset tabanlı, sadece yeni satırlar) ─────────────────

  /// Dosyayı [fromByteOffset] byte'ından itibaren okur, sadece yeni satırları parse eder.
  /// Döner: (yeniSatırlar, güncellenmişByteOffset).
  /// Yarım satır sorununu önlemek için son tam '\n' öncesine kadar okur.
  static (List<HumidityMeasurement>, int) readNewCsvRows(
      String path, int fromByteOffset) {
    final file = File(path);
    if (!file.existsSync()) return ([], fromByteOffset);

    final fileLen = file.lengthSync();
    if (fileLen <= fromByteOffset) return ([], fromByteOffset);

    final raf = file.openSync();
    try {
      raf.setPositionSync(fromByteOffset);
      final newBytes = raf.readSync(fileLen - fromByteOffset);

      // Son tam satırı bul — yarım yazılmış satırı dışla
      final lastNL = newBytes.lastIndexOf(10); // ASCII '\n'
      if (lastNL < 0) return ([], fromByteOffset);

      final completeBytes = newBytes.sublist(0, lastNL);
      final newByteOffset = fromByteOffset + lastNL + 1;

      final text = utf8.decode(completeBytes, allowMalformed: true);
      final result = <HumidityMeasurement>[];
      for (final line in text.split('\n')) {
        if (line.trim().isEmpty) continue;
        final sep = _detectSeparator(line);
        final cols = line.split(sep);
        if (cols.length < 2) continue;
        final valRaw = cols[1].trim();
        if (!_hasDigit(valRaw)) continue;
        final dt = _parseDateTime(cols[0].trim());
        if (dt == null) continue;
        final value = _parseHumidityValue(valRaw);
        if (value == null) continue;
        result.add(HumidityMeasurement(timestamp: dt, value: value));
      }
      return (result, newByteOffset);
    } finally {
      raf.closeSync();
    }
  }

  // ─── Yardımcı ──────────────────────────────────────────────────────────────

  static String _detectSeparator(String line) {
    if (line.contains('\t')) return '\t';
    if (line.contains(';')) return ';';
    return ',';
  }

  static bool _hasDigit(String s) => s.contains(RegExp(r'\d'));

  /// "5.93 %rH" veya "5.93" → 5.93
  static double? _parseHumidityValue(String raw) {
    // %rH veya % ve benzeri birimleri temizle
    final cleaned = raw
        .replaceAll(RegExp(r'[%rRhH]'), '')
        .trim();
    return double.tryParse(cleaned);
  }

  /// Farklı tarih formatlarını dene.
  /// Örnekler: "44927.5" (Excel serial), "2024-01-15 08:30", "15.01.2024 08:30"
  static DateTime? _parseDateTime(String raw) {
    // Excel sayısal serial tarihi (örn. 44927.123)
    final serial = double.tryParse(raw);
    if (serial != null && serial > 40000) {
      return _excelSerialToDateTime(serial);
    }

    // ISO 8601 — "2024-01-15 08:30:00" veya "2024-01-15T08:30:00"
    final iso = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (iso != null) return iso;

    // Türkçe format — "15.01.2024 08:30"
    final dotMatch = RegExp(
            r'^(\d{1,2})\.(\d{1,2})\.(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?$')
        .firstMatch(raw.trim());
    if (dotMatch != null) {
      return DateTime(
        int.parse(dotMatch.group(3)!),
        int.parse(dotMatch.group(2)!),
        int.parse(dotMatch.group(1)!),
        int.parse(dotMatch.group(4)!),
        int.parse(dotMatch.group(5)!),
        int.parse(dotMatch.group(6) ?? '0'),
      );
    }

    return null;
  }

  /// Excel serial tarihi → Dart DateTime.
  /// Excel epoch: 1900-01-00 (1 = 1900-01-01, 2 = 1900-01-02...).
  /// Dart epoch: 1970-01-01.
  static DateTime _excelSerialToDateTime(double serial) {
    // Excel'de 1900-02-29 bug'ı var — 60'tan büyük serials 1 eksik sayılır
    final adjusted = serial > 60 ? serial - 1 : serial;
    final days = adjusted.floor();
    final fraction = adjusted - days;
    final date = DateTime(1900, 1, 1).add(Duration(days: days - 1));
    final secondsOfDay = (fraction * 86400).round();
    return date.add(Duration(seconds: secondsOfDay));
  }

  static double? _cellDouble(List<Data?> row, int col) {
    if (col >= row.length) return null;
    final cell = row[col];
    if (cell == null) return null;
    final v = cell.value;
    if (v is DoubleCellValue) return v.value;
    if (v is IntCellValue) return v.value.toDouble();
    if (v is TextCellValue) return double.tryParse(v.value.text ?? '');
    return null;
  }

  static String _cellString(List<Data?> row, int col) {
    if (col >= row.length) return '';
    final cell = row[col];
    if (cell == null) return '';
    final v = cell.value;
    if (v is TextCellValue) return v.value.text ?? '';
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    return '';
  }
}
