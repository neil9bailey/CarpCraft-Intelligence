import 'package:flutter_appauth/flutter_appauth.dart';

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

  final FlutterAppAuth _appAuth;

  bool get isConfigured => clientId.isNotEmpty && apiScope.isNotEmpty;

  Future<void> signIn() async {
    if (!isConfigured) {
      throw const AuthConfigurationException(
          'ENTRA_CLIENT_ID and ENTRA_API_SCOPE must be configured.');
    }
    AuthState.instance.markSignInStarted();
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl:
              'https://login.microsoftonline.com/$tenantId/v2.0/.well-known/openid-configuration',
          scopes: ['openid', 'profile', apiScope],
        ),
      );
      final token = result.accessToken;
      if (token == null || token.isEmpty) {
        throw const AuthConfigurationException(
            'Microsoft Entra did not return an access token.');
      }
      AuthState.instance.setSession(
          token: token, label: result.idToken != null ? 'DIIAC account' : null);
    } catch (error) {
      AuthState.instance.markSignInFailed('Microsoft sign-in failed: $error');
      rethrow;
    }
  }

  void signOut() {
    AuthState.instance.clear();
  }
}

class AuthConfigurationException implements Exception {
  const AuthConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}
