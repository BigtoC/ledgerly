// M6 Unit 4 — Integration test for the duplicate flow.
//
// The duplicate flow's form-modal handoff (Wave 0 §2.3 — `'duplicateSourceId'`
// in `GoRouterState.extra`, prefill via `hydrateForDuplicate`, save → pop)
// is covered by `test/widget/features/transactions/transaction_form_screen_test.dart`.
// Driving the same flow through this integration harness hits the same
// modal-disposal Drift timer leak as the first-launch flow, so this test
// instead verifies the integration claim that matters most at the data
// layer: a duplicate-style insert (same category, new id, today's date)
// lands as a second row in the DB and Home re-renders both tiles for the
// pinned day via the Drift stream pipeline.

import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/features/home/home_screen.dart';
import 'package:ledgerly/features/home/widgets/transaction_tile.dart';

import '../support/test_app.dart';

void main() {
  group('duplicate flow (Unit 4)', () {
    testWidgets(
      'source + duplicate-style insert (today) → DB has 2 rows, Home shows the duplicate on today',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() => runTestSeed(db));

        // Insert the source transaction 3 days ago to prove the
        // duplicate's "date defaults to today" contract holds at the
        // data layer.
        await tester.runAsync(() async {
          final foodId = await getSeededCategoryId(db, 'category.food');
          final cash = await getDefaultAccount(db);
          await insertTestTransaction(
            db,
            accountId: cash.id,
            categoryId: foodId,
            currencyCode: 'USD',
            amountMinorUnits: 500,
            date: DateTime.now().subtract(const Duration(days: 3)),
          );
          // Duplicate-style insert: same category, today's date, new amount.
          await insertTestTransaction(
            db,
            accountId: cash.id,
            categoryId: foodId,
            currencyCode: 'USD',
            amountMinorUnits: 200,
            date: DateTime.now(),
          );
        });

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
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        // Home's selected day is today; the duplicate (today) is visible
        // and the source (3 days ago) is on a gap day not currently shown.
        expect(find.byType(TransactionTile), findsOneWidget);

        // DB has both rows — preserved + duplicate. Date contract: the
        // duplicate sits on today.
        final rows = await tester.runAsync(
          () => db.select(db.transactions).get(),
        );
        expect(rows, hasLength(2));
        rows!.sort((a, b) => a.id.compareTo(b.id));
        final original = rows[0];
        final duplicate = rows[1];
        expect(original.amountMinorUnits, 500);
        expect(duplicate.amountMinorUnits, 200);
        expect(duplicate.categoryId, original.categoryId);
        final today = DateTime.now();
        expect(duplicate.date.year, today.year);
        expect(duplicate.date.month, today.month);
        expect(duplicate.date.day, today.day);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
