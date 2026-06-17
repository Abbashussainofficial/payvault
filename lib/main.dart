import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/database/database.dart';
import 'features/auth/auth_provider.dart';
import 'shared/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure database singleton is ready
  AppDatabase.instance;

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const PayVaultApp(),
    ),
  );
}
