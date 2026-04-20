// M0 smoke test.
//
// Scope: proves the app scaffold boots through the real startup path
// (`main()` -> `bootstrap()` -> `runApp`) without throwing during initial
// layout.
//
// Evolves in M4: the template for all M5 widget tests wraps this with a
// ProviderScope that overrides `appDatabaseProvider` with an in-memory
// Drift database.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/main.dart' as app;

void main() {
  group('M0 smoke', () {
    testWidgets(
      'main boots into the placeholder shell without startup errors',
      (tester) async {
        await app.main();
        await tester.pump();
        await tester.pump();

        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.text('Ledgerly'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
