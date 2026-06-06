import 'package:flutter/material.dart';

import 'app.dart';
import 'core/auth_service.dart';
import 'core/runtime_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RuntimeConfig.instance.load();
  final authService = CarpCraftAuthService();
  await authService.startRedirectHandling();
  await authService.restoreSession();
  runApp(const CarpCraftApp());
}
