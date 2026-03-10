/// Dosya kaynağı yapılandırması — CSV (nem) ve XLSX (deformasyon) yolları.
class FileConfig {
  final String csvPath;   // Nem verisi — .csv
  final String xlsxPath; // Deformasyon verisi — .xlsx

  const FileConfig({
    required this.csvPath,
    required this.xlsxPath,
  });

  static const empty = FileConfig(csvPath: '', xlsxPath: '');

  bool get hasCsvPath => csvPath.trim().isNotEmpty;
  bool get hasXlsxPath => xlsxPath.trim().isNotEmpty;

  FileConfig copyWith({String? csvPath, String? xlsxPath}) => FileConfig(
        csvPath: csvPath ?? this.csvPath,
        xlsxPath: xlsxPath ?? this.xlsxPath,
      );

  Map<String, dynamic> toMap() => {
        'csv_path': csvPath,
        'xlsx_path': xlsxPath,
      };

  factory FileConfig.fromMap(Map map) => FileConfig(
        csvPath: (map['csv_path'] as String?) ?? '',
        xlsxPath: (map['xlsx_path'] as String?) ?? '',
      );
}
