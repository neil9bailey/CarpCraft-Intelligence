import 'package:flutter/material.dart';

import 'app.dart';
import 'core/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CarpCraftAuthService().restoreSession();
  runApp(const CarpCraftApp());
}
