// M6 Unit 6 — Integration test for archived-state rendering.
//
// PRD's archive-instead-of-delete rule means archived rows disappear
// from pickers but stay visible elsewhere:
//   - Categories: hidden from the picker stream (`watchAll(includeArchived: false)`).
//   - Accounts: visible in the management screen's "Archived" section.
//   - Historical transactions on Home: still render with the archived
//     category metadata because Home watches with `includeArchived: true`.
//
// The category picker's modal Drift-stream subscription does not settle
// reliably in FakeAsync, so the picker UI is verified at the widget
// layer (see `test/widget/features/categories/category_picker_test.dart`).
// This integration test instead asserts the repository-level stream
// contract (the SSOT for picker visibility) and the Home / Accounts UI
// surfaces that DO render archived rows.

import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/features/accounts/accounts_screen.dart';
import 'package:ledgerly/features/home/home_screen.dart';
import 'package:ledgerly/features/home/widgets/transaction_tile.dart';

import '../support/test_app.dart';

void main() {
  group('archived-state rendering (Unit 6)', () {
    testWidgets(
      'archived category: hidden from picker stream, Home tile still renders the name',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() => runTestSeed(db));

        late int foodId;
        await tester.runAsync(() async {
          foodId = await getSeededCategoryId(db, 'category.food');
          final cash = await getDefaultAccount(db);
          await insertTestTransaction(
            db,
            accountId: cash.id,
            categoryId: foodId,
            currencyCode: 'USD',
            amountMinorUnits: 100,
            date: DateTime.now(),
          );
          // Archive Food after the historical row exists.
          await DriftCategoryRepository(db).archive(foodId);
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
        // Historical row still renders with the archived category name.
        expect(find.byType(TransactionTile), findsOneWidget);
        expect(find.text('Food'), findsAtLeastNWidgets(1));

        // Repository contract: the picker-facing stream
        // (`includeArchived: false`) must exclude archived rows.
        final pickerCategories = await tester.runAsync(() async {
          return DriftCategoryRepository(
            db,
          ).watchAll(type: CategoryType.expense, includeArchived: false).first;
        });
        expect(
          pickerCategories!.any((c) => c.id == foodId),
          isFalse,
          reason:
              'Archived Food must not appear in the active-only picker stream',
        );

        // Repository contract for archive-aware paths (e.g. Home tile
        // metadata): `includeArchived: true` still includes archived rows.
        final allCategories = await tester.runAsync(() async {
          return DriftCategoryRepository(
            db,
          ).watchAll(type: CategoryType.expense, includeArchived: true).first;
        });
        expect(
          allCategories!.any((c) => c.id == foodId && c.isArchived),
          isTrue,
          reason:
              'Archived Food remains queryable when includeArchived is true',
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'archived account: visible in Accounts management Archived section',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() => runTestSeed(db));

        // Seed creates a USD Cash account; add a second active account
        // so archiving Cash does not strand the form / pickers, then
        // archive Cash via the repository.
        await tester.runAsync(() async {
          final cashAccount = await getDefaultAccount(db);
          final investmentTypeId = await getAccountTypeId(
            db,
            'accountType.investment',
          );
          await createTestAccount(
            db,
            name: 'Brokerage',
            currencyCode: 'USD',
            accountTypeId: investmentTypeId,
          );
          await DriftAccountRepository(
            db,
            DriftCurrencyRepository(db),
          ).archive(cashAccount.id);
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

        // Navigate to Accounts via the bottom-nav tab.
        await tester.tap(find.text('Accounts'));
        await tester.pumpAndSettle();
        expect(find.byType(AccountsScreen), findsOneWidget);

        // The Archived section header is visible because there is an
        // archived account; Cash row appears beneath it. "Cash" can
        // also surface as an account-type label, hence the relaxed
        // count assertion — we only care that the archived account row
        // is rendered alongside the active Brokerage row.
        expect(find.text('Archived'), findsOneWidget);
        expect(find.text('Cash'), findsAtLeastNWidgets(1));
        expect(find.text('Brokerage'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );
  });
}
