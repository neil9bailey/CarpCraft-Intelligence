import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  AuthState._();

  static final AuthState instance = AuthState._();

  String? accessToken;
  String? accountLabel;
  bool apiAuthRequired = false;
  bool signInInProgress = false;
  String authStatusMessage = 'Not signed in.';
  String? lastApiAuthMessage;

  bool get isSignedIn => accessToken != null && accessToken!.isNotEmpty;

  void setSession({required String token, String? label}) {
    accessToken = token;
    accountLabel = label;
    apiAuthRequired = false;
    signInInProgress = false;
    authStatusMessage = 'DIIAC Entra sign-in complete.';
    lastApiAuthMessage = null;
    notifyListeners();
  }

  void clear() {
    accessToken = null;
    accountLabel = null;
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
}
