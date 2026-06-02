import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  AuthState._();

  static final AuthState instance = AuthState._();

  String? accessToken;
  String? accountLabel;
  bool apiAuthRequired = false;
  String? lastApiAuthMessage;

  bool get isSignedIn => accessToken != null && accessToken!.isNotEmpty;

  void setSession({required String token, String? label}) {
    accessToken = token;
    accountLabel = label;
    apiAuthRequired = false;
    lastApiAuthMessage = null;
    notifyListeners();
  }

  void clear() {
    accessToken = null;
    accountLabel = null;
    apiAuthRequired = false;
    lastApiAuthMessage = null;
    notifyListeners();
  }

  void markApiAuthRequired(String message) {
    apiAuthRequired = true;
    lastApiAuthMessage = message;
    notifyListeners();
  }
}
