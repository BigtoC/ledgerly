// M4 §7.10 — Theme reactivity test (T7.5).
//
// Verifies that calling `setThemeMode(ThemeMode.dark)` on the repository
// triggers the `_themeModeStreamProvider` → `themeModeProvider` chain and
// causes `MaterialApp` to rebuild with dark brightness.
//
// Note: DB operations (seed + setThemeMode) must run inside `tester.runAsync`
// because Drift uses real timers that do not advance inside FakeAsync. After
// the write completes, bounded `pump` calls propagate the stream emission
// through Riverpod to the widget tree.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/app.dart';
import 'package:ledgerly/app/providers/app_database_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';

import '../../support/test_app.dart';

void main() {
  group('theme reactivity', () {
    // M4 known issue: live DB writes in a testWidgets body cannot both
    // complete (Drift needs real timers) and notify FakeAsync-bound Riverpod
    // stream subscribers in the same turn. Re-enable once we settle on the
    // test pattern for live-stream tests (candidates: real-DB integration
    // harness, stream provider overrides, or switching Drift to a sync
    // in-memory variant in tests).
    testWidgets(
      'setThemeMode(dark) rebuilds MaterialApp with dark brightness',
      skip: true,
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() => runTestSeed(db));

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            // Pre-seed gate so the first frame lands at HomeScreen (avoids
            // navigating through splash in this test).
            splashGateSnapshotProvider.overrideWithValue(
              SplashGateSnapshot.withInitial(enabled: false, startDate: null),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Baseline: default theme is light.
        final lightBrightness = Theme.of(
          tester.element(find.byType(Scaffold).first),
        ).brightness;
        expect(lightBrightness, Brightness.light);

        // Switch to dark. Run the DB write via `runAsync` so its real timers
        // can fire, then pump twice inside FakeAsync so the queued stream
        // emission microtask delivers the update and the widget rebuilds.
        await tester.runAsync(
          () => container
              .read(userPreferencesRepositoryProvider)
              .setThemeMode(ThemeMode.dark),
        );
        // Flush microtasks (stream emission → provider update → markNeedsBuild).
        await tester.pump();
        // Advance clock so the AnimatedTheme transition completes.
        await tester.pump(const Duration(seconds: 1));

        final darkBrightness = Theme.of(
          tester.element(find.byType(Scaffold).first),
        ).brightness;
        expect(darkBrightness, Brightness.dark);
      },
    );

    // M4 known issue: see sibling test. Same live-DB-to-FakeAsync gap.
    testWidgets(
      'setThemeMode(light) after dark reverts to light brightness',
      skip: true,
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() => runTestSeed(db));

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            splashGateSnapshotProvider.overrideWithValue(
              SplashGateSnapshot.withInitial(enabled: false, startDate: null),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        final prefs = container.read(userPreferencesRepositoryProvider);
        await tester.runAsync(() => prefs.setThemeMode(ThemeMode.dark));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        await tester.runAsync(() => prefs.setThemeMode(ThemeMode.light));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        final brightness = Theme.of(
          tester.element(find.byType(Scaffold).first),
        ).brightness;
        expect(brightness, Brightness.light);
      },
    );
  });
}
