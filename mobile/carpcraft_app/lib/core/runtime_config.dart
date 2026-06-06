import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Runtime, user-overridable app configuration.
///
/// The backend base URL can be baked in at build time via
/// `--dart-define=CARPCRAFT_API_BASE_URL=...`, but a fixed build is useless if
/// it points at an unreachable host. This lets the installed app be pointed at
/// any backend (Azure, a LAN dev server, etc.) and persists the choice, so live
/// testing does not require a rebuild.
class RuntimeConfig extends ChangeNotifier {
  RuntimeConfig._();

  static final RuntimeConfig instance = RuntimeConfig._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _baseUrlKey = 'carpcraft_api_base_url_override';

  /// The base URL compiled into this build (or the emulator default).
  static const String compiledBaseUrl = String.fromEnvironment(
    'CARPCRAFT_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  String? _apiBaseUrlOverride;

  String? get apiBaseUrlOverride => _apiBaseUrlOverride;

  bool get hasOverride =>
      _apiBaseUrlOverride != null && _apiBaseUrlOverride!.trim().isNotEmpty;

  /// The base URL the app should actually call.
  String get effectiveBaseUrl {
    final override = _apiBaseUrlOverride;
    if (override != null && override.trim().isNotEmpty) {
      return _normalize(override);
    }
    return compiledBaseUrl;
  }

  Future<void> load() async {
    try {
      final stored = await _storage.read(key: _baseUrlKey);
      if (stored != null && stored.trim().isNotEmpty) {
        _apiBaseUrlOverride = _normalize(stored);
        notifyListeners();
      }
    } catch (_) {
      // Secure storage is best-effort; fall back to the compiled value.
    }
  }

  Future<void> setApiBaseUrl(String? value) async {
    final normalized = (value == null || value.trim().isEmpty)
        ? null
        : _normalize(value);
    _apiBaseUrlOverride = normalized;
    notifyListeners();
    try {
      if (normalized == null) {
        await _storage.delete(key: _baseUrlKey);
      } else {
        await _storage.write(key: _baseUrlKey, value: normalized);
      }
    } catch (_) {
      // Persisting is best-effort; the in-memory value still applies this run.
    }
  }

  /// Trim trailing slashes so `'$baseUrl$path'` joins cleanly.
  static String _normalize(String value) {
    var trimmed = value.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
