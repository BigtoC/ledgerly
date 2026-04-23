// M4 §7.7 — Router redirect state machine tests.
//
// Uses `testWidgets` with an explicit `ProviderContainer` override so the
// `routerProvider` reads a pre-seeded `SplashGateSnapshot` whose state is
// controlled by each test case. No live DB interaction required.

import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/home/home_screen.dart';
import 'package:ledgerly/features/splash/splash_screen.dart';

import '../../support/test_app.dart';

void main() {
  group('router redirect', () {
    testWidgets('splashEnabled=true: / → /splash', (tester) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: true, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('splashEnabled=false: / → /home (G10)', (tester) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
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
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets(
      'splashEnabled=true with startDate set: /splash shows Enter CTA',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        // SplashScreen reads `splashStartDateProvider` (a live Drift stream),
        // not the `SplashGateSnapshot`, so we must seed the DB so the stream
        // actually emits a non-null value.
        final prefs = DriftUserPreferencesRepository(db);
        await tester.runAsync(
          () => prefs.setSplashStartDate(DateTime(2025, 1, 1)),
        );

        final container = makeTestContainer(
          db: db,
          extraOverrides: [
            splashGateSnapshotProvider.overrideWithValue(
              SplashGateSnapshot.withInitial(
                enabled: true,
                startDate: DateTime(2025, 1, 1),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(buildTestApp(container: container));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(SplashScreen), findsOneWidget);
        // SplashScreen renders "Enter" when startDate is set.
        expect(find.text('Enter'), findsOneWidget);
      },
    );
  });
}
