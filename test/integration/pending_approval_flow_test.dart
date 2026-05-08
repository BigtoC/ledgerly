// End-to-end integration test for pending approval flow.
//
// Exercises: seed → insert pending row → land on Home → approve →
// verify pending row deleted and transaction inserted.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

import '../support/test_app.dart';

void main() {
  group('Pending approval flow', () {
    late AppDatabase db;

    setUp(() async {
      db = newTestAppDatabase();
      await runTestSeed(db);
    });

    tearDown(() async => db.close());

    testWidgets('approved pending row becomes a transaction on Home', (
      tester,
    ) async {
      late DriftTransactionRepository txRepo;
      late DriftPendingTransactionRepository pendingRepo;
      late int categoryId;
      late Account account;
      await tester.runAsync(() async {
        txRepo = DriftTransactionRepository(db);
        pendingRepo = DriftPendingTransactionRepository(db, txRepo: txRepo);
        categoryId = await getSeededCategoryId(db, 'category.food');
        account = await getDefaultAccount(db);

        await pendingRepo.insert(
          source: 'recurring',
          amountMinorUnits: 1599,
          currencyCode: account.currency.code,
          categoryId: categoryId,
          accountId: account.id,
          memo: 'Netflix',
          date: DateTime.now(),
          fetchedAt: DateTime.now(),
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

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Pending row deleted from DB.
      final pendingRows = await tester.runAsync(
        () => pendingRepo.watchAll().first,
      );
      expect(pendingRows, isEmpty);

      // Transaction inserted (historical + Netflix).
      final txns = await tester.runAsync(
        () => txRepo.watchByDay(DateTime.now()).first,
      );
      expect(txns, isNotNull);
      final transactions = txns!;
      expect(transactions.any((tx) => tx.memo == 'Netflix'), isTrue);
      expect(
        transactions.firstWhere((tx) => tx.memo == 'Netflix').amountMinorUnits,
        1599,
      );
    });

    testWidgets(
      'approving one of N daily pending rows leaves the others on screen',
      (tester) async {
        // Regression for user report: a daily recurring rule generates one
        // pending row per missed day. Approving the most recent row must
        // leave the older days' rows visible in the section.
        final txRepo = DriftTransactionRepository(db);
        final pendingRepo = DriftPendingTransactionRepository(
          db,
          txRepo: txRepo,
        );
        final categoryId = await getSeededCategoryId(db, 'category.food');
        final account = await getDefaultAccount(db);

        // Seed history so HomeData (and PendingSection) renders.
        await insertTestTransaction(
          db,
          accountId: account.id,
          categoryId: categoryId,
          currencyCode: account.currency.code,
          amountMinorUnits: 100,
          memo: 'historical',
        );

        // Three pending rows from a single (daily) rule, three different
        // dates. Memos are unique so we can find each tile by text.
        Future<void> seed(int day, String memo) => pendingRepo.insert(
          source: 'recurring',
          amountMinorUnits: 1599,
          currencyCode: account.currency.code,
          categoryId: categoryId,
          accountId: account.id,
          memo: memo,
          date: DateTime(2026, 5, day),
          fetchedAt: DateTime(2026, 5, day),
        );
        await seed(6, 'Day6');
        await seed(7, 'Day7');
        await seed(8, 'Day8');

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

        expect(find.text('Day6'), findsOneWidget);
        expect(find.text('Day7'), findsOneWidget);
        expect(find.text('Day8'), findsOneWidget);

        // Approve the middle one. The approve circles all share the same
        // icon, so target the one inside the Day7 tile.
        final approveOnDay7 = find.descendant(
          of: find.ancestor(
            of: find.text('Day7'),
            matching: find.byType(ListTile),
          ),
          matching: find.byIcon(Icons.check),
        );
        expect(approveOnDay7, findsOneWidget);

        await tester.tap(approveOnDay7);
        await tester.pumpAndSettle();

        // The other two pending rows must still be in the section.
        expect(find.text('Day6'), findsOneWidget);
        expect(find.text('Day8'), findsOneWidget);

        // And the DB confirms only one row was deleted.
        final remaining = await pendingRepo.watchAll().first;
        expect(remaining, hasLength(2));

        // The new transaction must be dated 2026-05-07 (the pending row's
        // original date), NOT today. Read directly from the DB to bypass
        // any UI filtering.
        final approvedTx = await tester.runAsync(() async {
          final all = await db.select(db.transactions).get();
          return all.firstWhere((t) => t.memo == 'Day7');
        });
        expect(approvedTx, isNotNull);
        expect(approvedTx!.date, DateTime(2026, 5, 7));
      },
    );
  });
}
