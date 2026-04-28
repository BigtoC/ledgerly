// M6 Unit 5 — Integration test for multi-currency seeded-state rendering.
//
// PRD's MVP currency policy forbids auto-conversion: when the user has
// transactions in multiple currencies, the Home summary strip groups
// totals by the original currency code. This test seeds USD + JPY rows,
// boots the app past splash, and verifies the strip renders both groups
// with their currency-prefixed amounts.
//
// Repository-level multi-currency aggregation behaviour is already
// covered by `test/unit/repositories/transaction_repository_test.dart`
// — this test only proves the wiring from real DB → controller → strip.

import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/features/home/home_screen.dart';
import 'package:ledgerly/features/home/widgets/summary_strip.dart';

import '../support/test_app.dart';

void main() {
  group('multi-currency seeded-state rendering (Unit 5)', () {
    testWidgets(
      'USD + JPY transactions → summary strip renders two currency groups',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() => runTestSeed(db));

        // Seed creates a USD Cash account + categories. Add a JPY
        // Investment account, then insert one expense per currency.
        await tester.runAsync(() async {
          final foodId = await getSeededCategoryId(db, 'category.food');
          final cash = await getDefaultAccount(db);

          final investmentTypeId = await getAccountTypeId(
            db,
            'accountType.investment',
          );
          final yenAccount = await createTestAccount(
            db,
            name: 'Yen Account',
            currencyCode: 'JPY',
            accountTypeId: investmentTypeId,
          );

          // USD expense — $1.00 today.
          await insertTestTransaction(
            db,
            accountId: cash.id,
            categoryId: foodId,
            currencyCode: 'USD',
            amountMinorUnits: 100,
            date: DateTime.now(),
          );

          // JPY expense — ¥500 today.
          await insertTestTransaction(
            db,
            accountId: yenAccount.id,
            categoryId: foodId,
            currencyCode: 'JPY',
            amountMinorUnits: 500,
            date: DateTime.now(),
          );
        });

        // Skip splash so the strip is the focus of the assertion.
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
        expect(find.byType(SummaryStrip), findsOneWidget);

        // Both currency-prefixed amounts must render. `MoneyFormatter`
        // uses each currency's symbol, so the strip carries '\$1.00' for
        // USD and '¥500' for JPY (en_US default locale).
        expect(find.textContaining(r'$1.00'), findsAtLeastNWidgets(1));
        expect(find.textContaining('¥500'), findsAtLeastNWidgets(1));

        // Sanity check: the strip must NOT collapse into a single
        // currency. The month-net signed total proves the second group.
        expect(find.textContaining(r'-$1.00'), findsAtLeastNWidgets(1));
        expect(find.textContaining('-¥500'), findsAtLeastNWidgets(1));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'same-account cross-currency: USD + JPY on one account → two groups in summary',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() => runTestSeed(db));

        // Insert both USD and JPY transactions against the single seeded
        // USD Cash account — cross-currency saves are now allowed.
        await tester.runAsync(() async {
          final foodId = await getSeededCategoryId(db, 'category.food');
          final cash = await getDefaultAccount(db);

          // USD expense — $1.00 today.
          await insertTestTransaction(
            db,
            accountId: cash.id,
            categoryId: foodId,
            currencyCode: 'USD',
            amountMinorUnits: 100,
            date: DateTime.now(),
          );

          // JPY expense on the SAME USD account — cross-currency.
          await insertTestTransaction(
            db,
            accountId: cash.id,
            categoryId: foodId,
            currencyCode: 'JPY',
            amountMinorUnits: 500,
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
        expect(find.byType(SummaryStrip), findsOneWidget);

        // Both currency groups must appear in the summary strip.
        expect(find.textContaining(r'$1.00'), findsAtLeastNWidgets(1));
        expect(find.textContaining('¥500'), findsAtLeastNWidgets(1));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'all transactions in same currency → summary strip has one group',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() => runTestSeed(db));

        await tester.runAsync(() async {
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

        expect(find.byType(SummaryStrip), findsOneWidget);
        expect(find.textContaining(r'$1.00'), findsAtLeastNWidgets(1));
        // No JPY transaction → no yen formatted amount.
        expect(find.textContaining('¥'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
