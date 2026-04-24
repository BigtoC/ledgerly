// M4 §7.5 — Integration test: bootstrap → first-run flow → home.
//
// Two variants:
//   1. First run (splash_enabled=true, no start date) → set the start date
//      on the Splash route → tap "Enter" → HomeScreen.
//   2. Subsequent run (splash_enabled=false) → HomeScreen directly (G10).
//
// Note: `runTestSeed` and direct repository writes run inside `tester.runAsync`
// because Drift uses real timers that do not advance inside FakeAsync.
// Interaction-triggered writes (via `tester.tap`) are fire-and-forget and let
// subsequent `pump` calls fire any queued timers.

import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/home/home_screen.dart';
import 'package:ledgerly/features/splash/splash_screen.dart';

import '../support/test_app.dart';

void main() {
  group('bootstrap → home integration', () {
    testWidgets('first run: splash → set date → enter → home', (tester) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await tester.runAsync(() => runTestSeed(db));
      final container = makeTestContainer(db: db);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Splash route reached; date prompt visible.
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Set start date'), findsOneWidget);

      // User taps — placeholder writes DateTime.now().
      await tester.tap(find.text('Set start date'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // UI rebuilt with "Enter" CTA.
      expect(find.text('Enter'), findsOneWidget);

      // Tap "Enter" → /home.
      await tester.tap(find.text('Enter'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('subsequent run: splash_enabled=false → home directly (G10)', (
      tester,
    ) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await tester.runAsync(() => runTestSeed(db));

      // Disable splash in the DB before pumping — simulates a user who
      // toggled the setting in a previous session. Direct repo write uses
      // real timers, so must run inside `runAsync`.
      final prefs = DriftUserPreferencesRepository(db);
      await tester.runAsync(() => prefs.setSplashEnabled(false));

      // Override the gate snapshot with the pre-read value so the very
      // first frame already knows splash is disabled. This proves G10:
      // SplashScreen is never constructed, not just navigated away from.
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('splash toggle in settings causes live re-route to home', (
      tester,
    ) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await tester.runAsync(() => runTestSeed(db));
      final container = makeTestContainer(db: db);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Start on splash (date not set, so date prompt shows).
      expect(find.byType(SplashScreen), findsOneWidget);

      // Simulate a settings write while the splash is showing. The write
      // must happen outside FakeAsync so Drift's real timers can advance;
      // subsequent pumps let the queued stream emission flow through
      // Riverpod → refreshListenable → GoRouter.redirect.
      final prefs = DriftUserPreferencesRepository(db);
      await tester.runAsync(() => prefs.setSplashEnabled(false));
      await tester.pumpAndSettle();

      // The SplashGateSnapshot's stream subscription fires, notifies the
      // router, which redirects from /splash to /home.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });
  });
}
