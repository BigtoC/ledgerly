// M6 Unit 2 + Unit 3 — Integration tests for the first-launch and
// subsequent-launch flows.
//
// Unit 2 verifies the bootstrap pipeline:
//   - empty-DB seed + splash gate enabled → splash with date prompt.
//   - pre-seeded first transaction → Home renders the tile on initial
//     subscribe (proves the Drift→UI stream pipeline reaches Home
//     without a mid-test repository write).
//
// Unit 3 covers the subsequent-launch path: `splash_enabled = true` and
// `splash_start_date` already set in `user_preferences` → splash
// renders the day counter (not the date-picker prompt) and Enter pops
// to Home.
//
// Mid-test repository writes do not propagate to already-subscribed
// Home streams under FakeAsync; the form-modal save flow that exposes
// that path is covered at the widget layer in
// `test/widget/features/transactions/transaction_form_screen_test.dart`
// and `test/widget/features/home/home_screen_test.dart`. This file
// scopes its assertions to seeded-state coverage.

import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/home/home_screen.dart';
import 'package:ledgerly/features/home/widgets/transaction_tile.dart';
import 'package:ledgerly/features/splash/splash_screen.dart';

import '../support/test_app.dart';

void main() {
  group('first-launch bootstrap (Unit 2)', () {
    testWidgets('empty DB → splash with date-picker prompt visible', (
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

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Set start date'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'with a seeded first transaction, Home boots and renders the tile',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() async {
          await runTestSeed(db);
          final foodId = await getSeededCategoryId(db, 'category.food');
          final cash = await getDefaultAccount(db);
          await insertTestTransaction(
            db,
            accountId: cash.id,
            categoryId: foodId,
            currencyCode: 'USD',
            amountMinorUnits: 100,
            date: DateTime.now(),
          );
        });

        // Skip splash so the assertion focuses on Home's initial subscribe.
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
        // Home subscribes to `watchByDay(today)` on first frame; the
        // pre-seeded row appears in the initial emission.
        expect(find.byType(TransactionTile), findsOneWidget);
        expect(find.text('Food'), findsAtLeastNWidgets(1));

        final rows = await tester.runAsync(
          () => db.select(db.transactions).get(),
        );
        expect(rows, hasLength(1));
        expect(rows!.single.amountMinorUnits, 100);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('subsequent splash-enabled launch (Unit 3)', () {
    testWidgets(
      'splash_enabled + start_date set → day counter visible (no date prompt)',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() async {
          await runTestSeed(db);
          final prefs = DriftUserPreferencesRepository(db);
          await prefs.setSplashEnabled(true);
          await prefs.setSplashStartDate(
            DateTime.now().subtract(const Duration(days: 30)),
          );
        });

        final container = makeTestContainer(db: db);
        addTearDown(container.dispose);

        await tester.pumpWidget(buildTestApp(container: container));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(SplashScreen), findsOneWidget);
        // Configured-date path: the date-picker prompt must NOT appear.
        expect(find.text('Set start date'), findsNothing);
        expect(find.text('Enter'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
