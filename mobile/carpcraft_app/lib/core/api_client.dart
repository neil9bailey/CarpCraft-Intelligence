import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'auth_state.dart';

class CarpCraftApiException implements Exception {
  const CarpCraftApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CarpCraftApiClient {
  const CarpCraftApiClient({
    this.baseUrl = const String.fromEnvironment(
      'CARPCRAFT_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    ),
    this.userId = const String.fromEnvironment(
      'CARPCRAFT_USER_ID',
      defaultValue: 'mobile-local-user',
    ),
    this.timeout = const Duration(seconds: 2),
  });

  final String baseUrl;
  final String userId;
  final Duration timeout;

  Future<List<dynamic>> getList(String path) async {
    final response = await _send('GET', path);
    if (response is List<dynamic>) {
      return response;
    }
    throw const CarpCraftApiException(
        'Expected a list response from CarpCraft API.');
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final response = await _send('GET', path);
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const CarpCraftApiException(
        'Expected an object response from CarpCraft API.');
  }

  Future<Map<String, dynamic>> postMap(
      String path, Map<String, dynamic> body) async {
    final response = await _send('POST', path, body: body);
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const CarpCraftApiException(
        'Expected an object response from CarpCraft API.');
  }

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? body}) async {
    final client = HttpClient();
    client.connectionTimeout = timeout;
    try {
      final request = await client
          .openUrl(method, Uri.parse('$baseUrl$path'))
          .timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set('X-CarpCraft-User-Id', userId);
      final token = AuthState.instance.accessToken;
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(timeout);
      final payload =
          await response.transform(utf8.decoder).join().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CarpCraftApiException(
            'CarpCraft API returned ${response.statusCode}: $payload');
      }
      if (payload.trim().isEmpty) {
        return null;
      }
      return jsonDecode(payload);
    } on TimeoutException catch (error) {
      throw CarpCraftApiException('CarpCraft API timed out: $error');
    } on SocketException catch (error) {
      throw CarpCraftApiException('CarpCraft API unavailable: $error');
    } finally {
      client.close(force: true);
    }
  }
}
