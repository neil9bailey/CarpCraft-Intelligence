import 'package:flutter/foundation.dart';

class AppSettingsState extends ChangeNotifier {
  AppSettingsState._();

  static final AppSettingsState instance = AppSettingsState._();

  bool preciseLocationEnabled = false;
  bool aiExplanationsEnabled = true;

  void setPreciseLocationEnabled(bool value) {
    preciseLocationEnabled = value;
    notifyListeners();
  }

  void setAiExplanationsEnabled(bool value) {
    aiExplanationsEnabled = value;
    notifyListeners();
  }
}
