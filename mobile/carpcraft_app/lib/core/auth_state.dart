class AuthState {
  AuthState._();

  static final AuthState instance = AuthState._();

  String? accessToken;
  String? accountLabel;

  bool get isSignedIn => accessToken != null && accessToken!.isNotEmpty;

  void setSession({required String token, String? label}) {
    accessToken = token;
    accountLabel = label;
  }

  void clear() {
    accessToken = null;
    accountLabel = null;
  }
}
