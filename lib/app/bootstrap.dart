// Async initialisation sequence executed before `runApp`.
//
// M0 ships a placeholder that only runs the app shell. The full sequence
// from PRD → Bootstrap Sequence lands in M4:
//
//   1. WidgetsFlutterBinding.ensureInitialized()
//   2. Open AppDatabase (runs migrations if schemaVersion changed)
//   3. Initialise LocaleService, resolve device locale for default-currency
//      fallback
//   4. Read user_preferences table
//   5. First-run seed (if empty DB): seed currencies, default categories,
//      one Cash account, default_currency from device locale
//   6. Configure ProviderScope with overrides injecting the opened
//      AppDatabase into appDatabaseProvider
//   7. runApp(ProviderScope(overrides: [...], child: App()))

import 'package:flutter/widgets.dart';
import 'package:ledgerly/app/app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
