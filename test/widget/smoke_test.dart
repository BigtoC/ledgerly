// M4 smoke test (replaces M0 body, same file path so CI entry keeps passing).
//
// Scope: proves the app shell boots via `buildTestApp` (in-memory DB, no disk),
// localizations are wired, and the first-run splash path is reached without
// errors. Becomes the copy-paste template for every M5 widget test.
//
// Note: `runTestSeed` must be called inside `tester.runAsync` because Drift's
// async operations use real timers which do not advance inside `testWidgets`'s
// FakeAsync zone.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/features/splash/splash_screen.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

import '../support/test_app.dart';

void main() {
  group('M4 smoke', () {
    testWidgets(
      'app boots with in-memory DB, reaches splash on first run, no errors',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        final container = makeTestContainer(db: db);
        addTearDown(container.dispose);

        await tester.pumpWidget(buildTestApp(container: container));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // App widget tree is present.
        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.onGenerateTitle, isNotNull);

        final splashContext = tester.element(find.byType(SplashScreen));
        expect(AppLocalizations.of(splashContext).appTitle, 'Ledgerly');

        // First-run: splash route is reached (splash_enabled defaults to true,
        // start_date defaults to null from fresh unseeded DB).
        expect(find.byType(SplashScreen), findsOneWidget);

        // The "Set start date" prompt is shown (no start date yet).
        expect(find.text('Set start date'), findsOneWidget);

        // No unhandled exceptions during initial layout.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'seeded DB: first-run splash shows Enter CTA after setting a date',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        // Drift uses real timers during seed; run outside FakeAsync so they
        // can fire without needing a pump to advance the clock.
        await tester.runAsync(() => runTestSeed(db));
        final container = makeTestContainer(db: db);
        addTearDown(container.dispose);

        await tester.pumpWidget(buildTestApp(container: container));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.text('Set start date'), findsOneWidget);

        // Tap "Set start date" — the placeholder writes DateTime.now().
        await tester.tap(find.text('Set start date'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('Enter'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
