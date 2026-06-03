import 'package:flutter/material.dart';

import 'app.dart';
import 'core/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = CarpCraftAuthService();
  await authService.startRedirectHandling();
  await authService.restoreSession();
  runApp(const CarpCraftApp());
}
