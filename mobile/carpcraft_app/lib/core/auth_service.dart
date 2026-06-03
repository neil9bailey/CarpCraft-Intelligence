import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_state.dart';

class CarpCraftAuthService {
  CarpCraftAuthService();

  static const tenantId = String.fromEnvironment(
    'ENTRA_TENANT_ID',
    defaultValue: '67f8be6c-07da-4a7c-bb0a-d6bcb38cd6da',
  );
  static const clientId = String.fromEnvironment('ENTRA_CLIENT_ID');
  static const apiScope = String.fromEnvironment('ENTRA_API_SCOPE');
  static const redirectUrl = String.fromEnvironment(
    'ENTRA_REDIRECT_URL',
    defaultValue: 'com.carpcraft.intelligence://oauthredirect',
  );
  static const loginHint = String.fromEnvironment('ENTRA_LOGIN_HINT');

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'carpcraft.entra.access_token';
  static const _refreshTokenKey = 'carpcraft.entra.refresh_token';
  static const _expiresAtKey = 'carpcraft.entra.expires_at';
  static const _accountLabelKey = 'carpcraft.entra.account_label';
  static const _pendingStartedAtKey = 'carpcraft.entra.pending_started_at';
  static const _pendingStateKey = 'carpcraft.entra.pending_state';
  static const _pendingCodeVerifierKey =
      'carpcraft.entra.pending_code_verifier';

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _redirectSubscription;
  static bool _initialLinkChecked = false;

  bool get isConfigured => clientId.isNotEmpty && apiScope.isNotEmpty;
  static String get clientIdSummary => clientId.length < 8
      ? 'not configured'
      : '${clientId.substring(0, 8)}...${clientId.substring(clientId.length - 4)}';
  static String get scopeSummary =>
      apiScope.isEmpty ? 'not configured' : apiScope.split('/').last;

  Future<void> startRedirectHandling() async {
    _redirectSubscription ??= _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handleRedirectUri(uri)),
      onError: (Object error) => AuthState.instance.markSignInFailed(
          'Could not read Microsoft sign-in redirect: $error'),
    );

    if (!_initialLinkChecked) {
      _initialLinkChecked = true;
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleRedirectUri(initialLink);
      }
    }
  }

  Future<void> signIn() async {
    if (!isConfigured) {
      throw const AuthConfigurationException(
          'ENTRA_CLIENT_ID and ENTRA_API_SCOPE must be configured.');
    }

    AuthState.instance.markSignInStarted();
    final state = _secureRandomString(32);
    final codeVerifier = _secureRandomString(64);
    final codeChallenge = _codeChallenge(codeVerifier);

    await Future.wait([
      _storage.write(
        key: _pendingStartedAtKey,
        value: DateTime.now().toUtc().toIso8601String(),
      ),
      _storage.write(key: _pendingStateKey, value: state),
      _storage.write(key: _pendingCodeVerifierKey, value: codeVerifier),
    ]);

    final authorizationUri = Uri.parse(
      'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize',
    ).replace(queryParameters: {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUrl,
      'response_mode': 'query',
      'scope': _scope,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
      if (loginHint.isNotEmpty) 'login_hint': loginHint,
    });

    final launched = await launchUrl(
      authorizationUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      AuthState.instance
          .markSignInFailed('Could not open Microsoft sign-in browser.');
      throw const AuthConfigurationException(
          'Could not open Microsoft sign-in browser.');
    }
    AuthState.instance.markSignInBrowserOpened();
  }

  Future<void> restoreSession() async {
    if (!isConfigured) {
      return;
    }

    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAt = _parseDate(await _storage.read(key: _expiresAtKey));
    final label = await _storage.read(key: _accountLabelKey);

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        !_isExpiringSoon(expiresAt)) {
      AuthState.instance.setSession(
        token: accessToken,
        label: label ?? 'DIIAC account',
        expiresAt: expiresAt,
        statusMessage: 'DIIAC Entra session restored.',
      );
      await _clearPendingSignIn();
      return;
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _exchangeRefreshToken(refreshToken);
        await _clearPendingSignIn();
        return;
      } catch (error) {
        await _clearStoredSession();
        AuthState.instance.markSignInFailed(
            'Stored DIIAC Entra session could not be refreshed: $error');
        return;
      }
    }

    final pendingStartedAt =
        _parseDate(await _storage.read(key: _pendingStartedAtKey));
    if (pendingStartedAt != null &&
        pendingStartedAt.isBefore(
            DateTime.now().toUtc().subtract(const Duration(minutes: 15)))) {
      AuthState.instance.markSignInReturnedWithoutToken();
      await _clearPendingSignIn();
    }
  }

  void signOut() {
    unawaited(_clearStoredSession());
    AuthState.instance.clear();
  }

  Future<void> _handleRedirectUri(Uri uri) async {
    if (!_matchesRedirectUri(uri)) {
      return;
    }

    final error = uri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      final description = uri.queryParameters['error_description'] ?? error;
      await _clearPendingSignIn();
      AuthState.instance.markSignInFailed(
          'Microsoft sign-in returned an error: $description');
      return;
    }

    final code = uri.queryParameters['code'];
    final returnedState = uri.queryParameters['state'];
    if (code == null || code.isEmpty) {
      return;
    }

    final expectedState = await _storage.read(key: _pendingStateKey);
    final codeVerifier = await _storage.read(key: _pendingCodeVerifierKey);
    if (expectedState == null ||
        expectedState.isEmpty ||
        codeVerifier == null ||
        codeVerifier.isEmpty) {
      AuthState.instance.markSignInFailed(
          'Microsoft sign-in returned, but no pending local auth request was found.');
      return;
    }
    if (returnedState != expectedState) {
      await _clearPendingSignIn();
      AuthState.instance.markSignInFailed(
          'Microsoft sign-in returned with an invalid state value.');
      return;
    }

    AuthState.instance.markAuthorizationCodeReceived();
    try {
      await _exchangeAuthorizationCode(code, codeVerifier);
      await _clearPendingSignIn();
    } catch (error) {
      await _clearPendingSignIn();
      AuthState.instance
          .markSignInFailed('Microsoft token exchange failed: $error');
    }
  }

  Future<void> _exchangeAuthorizationCode(
      String authorizationCode, String codeVerifier) async {
    final payload = await _postTokenForm({
      'grant_type': 'authorization_code',
      'client_id': clientId,
      'scope': _scope,
      'code': authorizationCode,
      'redirect_uri': redirectUrl,
      'code_verifier': codeVerifier,
    });
    await _storeAndApplyTokenPayload(
      payload,
      statusMessage: 'DIIAC Entra sign-in complete.',
    );
  }

  Future<void> _exchangeRefreshToken(String refreshToken) async {
    final payload = await _postTokenForm({
      'grant_type': 'refresh_token',
      'client_id': clientId,
      'scope': _scope,
      'refresh_token': refreshToken,
    });
    await _storeAndApplyTokenPayload(
      payload,
      fallbackRefreshToken: refreshToken,
      statusMessage: 'DIIAC Entra session refreshed.',
    );
  }

  Future<Map<String, dynamic>> _postTokenForm(Map<String, String> form) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
          'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token');
      final request = await client.postUrl(uri);
      request.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      request.write(Uri(queryParameters: form).query);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (decoded is Map<String, dynamic>) {
          final description =
              decoded['error_description'] ?? decoded['error'] ?? body;
          throw AuthConfigurationException(description.toString());
        }
        throw AuthConfigurationException(body);
      }
      if (decoded is! Map<String, dynamic>) {
        throw const AuthConfigurationException(
            'Microsoft token response was not JSON.');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _storeAndApplyTokenPayload(
    Map<String, dynamic> payload, {
    String? fallbackRefreshToken,
    required String statusMessage,
  }) async {
    final token = payload['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AuthConfigurationException(
          'Microsoft Entra did not return an access token.');
    }

    final refreshToken =
        payload['refresh_token'] as String? ?? fallbackRefreshToken;
    final expiresIn = payload['expires_in'];
    final expiresAt = expiresIn is num
        ? DateTime.now().toUtc().add(Duration(seconds: expiresIn.toInt()))
        : null;
    const label = 'DIIAC account';

    await _storage.write(key: _accessTokenKey, value: token);
    await _storage.write(key: _accountLabelKey, value: label);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    if (expiresAt != null) {
      await _storage.write(
        key: _expiresAtKey,
        value: expiresAt.toIso8601String(),
      );
    } else {
      await _storage.delete(key: _expiresAtKey);
    }

    AuthState.instance.setSession(
      token: token,
      label: label,
      expiresAt: expiresAt,
      statusMessage: statusMessage,
    );
  }

  Future<void> _clearStoredSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresAtKey),
      _storage.delete(key: _accountLabelKey),
      _clearPendingSignIn(),
    ]);
  }

  Future<void> _clearPendingSignIn() async {
    await Future.wait([
      _storage.delete(key: _pendingStartedAtKey),
      _storage.delete(key: _pendingStateKey),
      _storage.delete(key: _pendingCodeVerifierKey),
    ]);
  }

  bool _matchesRedirectUri(Uri uri) {
    final expected = Uri.parse(redirectUrl);
    return uri.scheme == expected.scheme && uri.host == expected.host;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  bool _isExpiringSoon(DateTime? expiresAt) {
    if (expiresAt == null) {
      return false;
    }
    return expiresAt.isBefore(
      DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
  }

  String get _scope => 'openid profile offline_access $apiScope';

  String _codeChallenge(String verifier) {
    return _base64UrlNoPadding(sha256.convert(utf8.encode(verifier)).bytes);
  }

  String _secureRandomString(int byteCount) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteCount, (_) => random.nextInt(256));
    return _base64UrlNoPadding(bytes);
  }

  String _base64UrlNoPadding(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

class AuthConfigurationException implements Exception {
  const AuthConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}
