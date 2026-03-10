import 'dart:io';
import 'package:hive/hive.dart';
import '../models/email_config.dart';
import '../models/file_config.dart';
import '../models/server_config.dart';

/// Hive tabanlı yapılandırma veritabanı.
/// pure Dart — native plugin gerektirmez.
abstract final class ConfigDatabase {
  static const _configBox = 'vitra_spc_config';
  static const _emailKey = 'email_config';
  static const _serverKey = 'server_config';
  static const _fileKey = 'file_config';

  static bool _initialized = false;

  /// Uygulamanın başında bir kez çağrılmalıdır.
  static Future<void> init() async {
    if (_initialized) return;
    final dir = _appDataDir();
    Directory(dir).createSync(recursive: true);
    Hive.init(dir);
    _initialized = true;
  }

  // ─── Email Config ──────────────────────────────────────────────────────────

  static Future<EmailConfig> loadEmailConfig() async {
    final box = await Hive.openBox<Map>(_configBox);
    final raw = box.get(_emailKey);
    await box.close();
    if (raw == null) return EmailConfig.empty;
    return EmailConfig.fromMap(raw);
  }

  static Future<void> saveEmailConfig(EmailConfig config) async {
    final box = await Hive.openBox<Map>(_configBox);
    await box.put(_emailKey, config.toMap());
    await box.close();
  }

  // ─── File Config ───────────────────────────────────────────────────────────

  static Future<FileConfig> loadFileConfig() async {
    final box = await Hive.openBox<Map>(_configBox);
    final raw = box.get(_fileKey);
    await box.close();
    if (raw == null) return FileConfig.empty;
    return FileConfig.fromMap(raw);
  }

  static Future<void> saveFileConfig(FileConfig config) async {
    final box = await Hive.openBox<Map>(_configBox);
    await box.put(_fileKey, config.toMap());
    await box.close();
  }

  // ─── Server Config ─────────────────────────────────────────────────────────

  static Future<ServerConfig> loadServerConfig() async {
    final box = await Hive.openBox<Map>(_configBox);
    final raw = box.get(_serverKey);
    await box.close();
    if (raw == null) return const ServerConfig();
    return ServerConfig.fromMap(raw);
  }

  static Future<void> saveServerConfig(ServerConfig config) async {
    final box = await Hive.openBox<Map>(_configBox);
    await box.put(_serverKey, config.toMap());
    await box.close();
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  static String _appDataDir() {
    if (Platform.isWindows) {
      return '${Platform.environment['APPDATA'] ?? Directory.current.path}'
          '\\VitrA_SPC';
    }
    if (Platform.isMacOS) {
      return '${Platform.environment['HOME'] ?? '.'}'
          '/Library/Application Support/VitrA_SPC';
    }
    // Linux
    return '${Platform.environment['HOME'] ?? '.'}/.vitra_spc';
  }
}
