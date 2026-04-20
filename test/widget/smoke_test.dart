// M0 smoke test.
//
// Scope: proves the app scaffold compiles and boots into a MaterialApp
// without throwing during initial layout. Intentionally does not assert
// against concrete UI copy — that belongs in feature-level widget tests.
//
// Evolves in M4: the template for all M5 widget tests wraps this with a
// ProviderScope that overrides `appDatabaseProvider` with an in-memory
// Drift database.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/app.dart';

void main() {
  group('M0 smoke', () {
    testWidgets('App boots into a MaterialApp without startup errors',
        (tester) async {
      await tester.pumpWidget(const App());

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
