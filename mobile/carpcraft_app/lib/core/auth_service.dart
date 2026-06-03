import 'dart:async';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_state.dart';

class CarpCraftAuthService {
  CarpCraftAuthService({FlutterAppAuth? appAuth})
      : _appAuth = appAuth ?? const FlutterAppAuth();

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

  final FlutterAppAuth _appAuth;

  bool get isConfigured => clientId.isNotEmpty && apiScope.isNotEmpty;
  static String get clientIdSummary => clientId.length < 8
      ? 'not configured'
      : '${clientId.substring(0, 8)}...${clientId.substring(clientId.length - 4)}';
  static String get scopeSummary =>
      apiScope.isEmpty ? 'not configured' : apiScope.split('/').last;

  Future<void> signIn() async {
    if (!isConfigured) {
      throw const AuthConfigurationException(
          'ENTRA_CLIENT_ID and ENTRA_API_SCOPE must be configured.');
    }
    AuthState.instance.markSignInStarted();
    await _storage.write(
      key: _pendingStartedAtKey,
      value: DateTime.now().toUtc().toIso8601String(),
    );
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl:
              'https://login.microsoftonline.com/$tenantId/v2.0/.well-known/openid-configuration',
          scopes: ['openid', 'profile', 'offline_access', apiScope],
          additionalParameters:
              loginHint.isEmpty ? null : const {'login_hint': loginHint},
        ),
      );
      await _storeAndApplyTokenResponse(result);
    } catch (error) {
      AuthState.instance.markSignInFailed('Microsoft sign-in failed: $error');
      rethrow;
    } finally {
      await _storage.delete(key: _pendingStartedAtKey);
    }
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
      await _storage.delete(key: _pendingStartedAtKey);
      return;
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final refreshed = await _appAuth.token(
          TokenRequest(
            clientId,
            redirectUrl,
            discoveryUrl:
                'https://login.microsoftonline.com/$tenantId/v2.0/.well-known/openid-configuration',
            scopes: ['openid', 'profile', 'offline_access', apiScope],
            refreshToken: refreshToken,
          ),
        );
        await _storeAndApplyTokenResponse(
          refreshed,
          fallbackRefreshToken: refreshToken,
          statusMessage: 'DIIAC Entra session refreshed.',
        );
        await _storage.delete(key: _pendingStartedAtKey);
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
        pendingStartedAt.isAfter(
            DateTime.now().toUtc().subtract(const Duration(minutes: 15)))) {
      AuthState.instance.markSignInReturnedWithoutToken();
      await _storage.delete(key: _pendingStartedAtKey);
    }
  }

  void signOut() {
    unawaited(_clearStoredSession());
    AuthState.instance.clear();
  }

  Future<void> _storeAndApplyTokenResponse(
    TokenResponse result, {
    String? fallbackRefreshToken,
    String statusMessage = 'DIIAC Entra sign-in complete.',
  }) async {
    final token = result.accessToken;
    if (token == null || token.isEmpty) {
      throw const AuthConfigurationException(
          'Microsoft Entra did not return an access token.');
    }

    final refreshToken = result.refreshToken ?? fallbackRefreshToken;
    final expiresAt = result.accessTokenExpirationDateTime;
    const label = 'DIIAC account';

    await _storage.write(key: _accessTokenKey, value: token);
    await _storage.write(key: _accountLabelKey, value: label);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    if (expiresAt != null) {
      await _storage.write(
        key: _expiresAtKey,
        value: expiresAt.toUtc().toIso8601String(),
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
      _storage.delete(key: _pendingStartedAtKey),
    ]);
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
}

class AuthConfigurationException implements Exception {
  const AuthConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}
