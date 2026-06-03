import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  AuthState._();

  static final AuthState instance = AuthState._();

  String? accessToken;
  String? accountLabel;
  DateTime? accessTokenExpiresAt;
  bool apiAuthRequired = false;
  bool signInInProgress = false;
  String authStatusMessage = 'Not signed in.';
  String? lastApiAuthMessage;

  bool get isSignedIn => accessToken != null && accessToken!.isNotEmpty;

  void setSession({
    required String token,
    String? label,
    DateTime? expiresAt,
    String statusMessage = 'DIIAC Entra sign-in complete.',
  }) {
    accessToken = token;
    accountLabel = label;
    accessTokenExpiresAt = expiresAt;
    apiAuthRequired = false;
    signInInProgress = false;
    authStatusMessage = statusMessage;
    lastApiAuthMessage = null;
    notifyListeners();
  }

  void clear() {
    accessToken = null;
    accountLabel = null;
    accessTokenExpiresAt = null;
    apiAuthRequired = false;
    signInInProgress = false;
    authStatusMessage = 'Signed out.';
    lastApiAuthMessage = null;
    notifyListeners();
  }

  void markApiAuthRequired(String message) {
    apiAuthRequired = true;
    lastApiAuthMessage = message;
    authStatusMessage = message;
    notifyListeners();
  }

  void markSignInStarted() {
    signInInProgress = true;
    authStatusMessage = 'Opening Microsoft sign-in...';
    notifyListeners();
  }

  void markSignInFailed(String message) {
    signInInProgress = false;
    authStatusMessage = message;
    notifyListeners();
  }

  void markSignInReturnedWithoutToken() {
    signInInProgress = false;
    authStatusMessage =
        'Returned from Microsoft sign-in, but no Entra token was captured. '
        'Retry once; if it repeats, capture Android auth logs.';
    notifyListeners();
  }
}
