// End-to-end integration test for pending approval flow.
//
// Exercises: seed → insert pending row → land on Home → approve →
// verify pending row deleted and transaction inserted.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/data/database/app_database.dart';
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
      final txRepo = DriftTransactionRepository(db);
      final pendingRepo = DriftPendingTransactionRepository(db, txRepo: txRepo);
      final categoryId = await getSeededCategoryId(db, 'category.food');
      final account = await getDefaultAccount(db);

      // Seed at least one historical transaction so HomeController emits
      // HomeData (and therefore mounts PendingSection). HomeEmpty does not
      // render the section.
      await insertTestTransaction(
        db,
        accountId: account.id,
        categoryId: categoryId,
        currencyCode: account.currency.code,
        amountMinorUnits: 100,
        memo: 'historical',
      );

      // Insert a pending row directly (simulating recurring generation).
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
      final pendingRows = await pendingRepo.watchAll().first;
      expect(pendingRows, isEmpty);

      // Transaction inserted (historical + Netflix).
      final txns = await txRepo.watchByDay(DateTime.now()).first;
      expect(txns.any((tx) => tx.memo == 'Netflix'), isTrue);
      expect(
        txns.firstWhere((tx) => tx.memo == 'Netflix').amountMinorUnits,
        1599,
      );
    });
  });
}
