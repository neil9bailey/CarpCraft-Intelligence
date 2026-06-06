import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'runtime_config.dart';

enum BackendStatus { unknown, checking, online, offline }

/// Shared backend reachability state.
///
/// A single source of truth used by both the Settings "Test connection" action
/// and the Dashboard banner, so a successful check in one place updates the
/// other. It probes the backend `/health` endpoint at the currently effective
/// base URL.
class BackendConnectivity extends ChangeNotifier {
  BackendConnectivity._();

  static final BackendConnectivity instance = BackendConnectivity._();

  BackendStatus status = BackendStatus.unknown;
  String? message;
  DateTime? lastCheckedAt;
  String? lastCheckedUrl;

  bool get isOnline => status == BackendStatus.online;
  bool get isChecking => status == BackendStatus.checking;

  /// Probe `GET <baseUrl>/health`. Returns true when the backend answers 2xx.
  /// Pass [overrideUrl] to test a candidate URL before it is saved.
  Future<bool> check({String? overrideUrl}) async {
    final url = (overrideUrl != null && overrideUrl.trim().isNotEmpty)
        ? _normalize(overrideUrl)
        : RuntimeConfig.instance.effectiveBaseUrl;

    status = BackendStatus.checking;
    message = 'Checking $url…';
    notifyListeners();

    var ok = false;
    String resultMessage;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client
          .getUrl(Uri.parse('$url/health'))
          .timeout(const Duration(seconds: 8));
      final response =
          await request.close().timeout(const Duration(seconds: 8));
      await response.drain<void>();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        ok = true;
        resultMessage = 'Connected to $url';
      } else {
        resultMessage = 'Backend at $url returned HTTP ${response.statusCode}';
      }
    } on TimeoutException {
      resultMessage =
          'Timed out reaching $url. Check the URL and that the backend is running.';
    } on SocketException catch (error) {
      resultMessage = 'Cannot reach $url: ${error.message}';
    } catch (error) {
      resultMessage = 'Connection check failed: $error';
    } finally {
      client.close(force: true);
    }

    status = ok ? BackendStatus.online : BackendStatus.offline;
    message = resultMessage;
    lastCheckedAt = DateTime.now();
    lastCheckedUrl = url;
    notifyListeners();
    return ok;
  }

  static String _normalize(String value) {
    var trimmed = value.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
