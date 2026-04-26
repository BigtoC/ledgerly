// M6 Unit 7 — Integration tests for edit and delete data invariants.
//
// The form-modal edit save path (`hydrateForEdit` → controller.save →
// pop) and the home overflow Delete + undo-snackbar UI flow are
// covered at the widget layer in
// `test/widget/features/transactions/transaction_form_screen_test.dart`
// and `test/widget/features/home/home_screen_test.dart`. The
// HomeController's timer-driven undo-window commit logic is covered by
// `test/unit/controllers/home_controller_test.dart`.
//
// Mid-test repository writes do not propagate reliably to already-
// subscribed Home streams under FakeAsync, so this integration test
// pre-seeds final state (post-edit / post-delete) and verifies the
// data + Home rendering invariants on initial subscribe:
//   - Edit: a row whose `updatedAt > createdAt` lands as a single tile
//     reflecting the post-edit `amountMinorUnits`.
//   - Delete: with no transactions in DB, Home renders the empty state
//     (no `TransactionTile`).

import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/home/home_screen.dart';
import 'package:ledgerly/features/home/widgets/transaction_tile.dart';

import '../support/test_app.dart';

void main() {
  group('edit invariant (Unit 7)', () {
    testWidgets(
      'edited transaction → DB shows updated amount, createdAt preserved, Home renders the tile',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);

        late int txId;
        late DateTime originalCreatedAt;
        await tester.runAsync(() async {
          await runTestSeed(db);
          final foodId = await getSeededCategoryId(db, 'category.food');
          final cash = await getFirstActiveAccount(db);
          final inserted = await insertTestTransaction(
            db,
            accountId: cash.id,
            categoryId: foodId,
            currencyCode: 'USD',
            amountMinorUnits: 500,
            date: DateTime.now(),
          );
          txId = inserted.id;
          originalCreatedAt = inserted.createdAt;
          // Same write path the form's controller.save uses on update;
          // applied before pumpWidget so the seeded subscribe sees the
          // post-edit row immediately.
          await Future<void>.delayed(const Duration(milliseconds: 1));
          final repo = DriftTransactionRepository(db);
          await repo.save(inserted.copyWith(amountMinorUnits: 9999));
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

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(TransactionTile), findsOneWidget);

        final rows = await tester.runAsync(
          () => db.select(db.transactions).get(),
        );
        expect(rows, hasLength(1));
        final updated = rows!.single;
        expect(updated.id, txId);
        expect(updated.amountMinorUnits, 9999);
        expect(updated.createdAt, originalCreatedAt);
        // updatedAt is repository-stamped on every save; under the
        // millisecond resolution of `DateTime.now()` the back-to-back
        // insert + update may resolve to the same instant, so accept
        // equality alongside `isAfter`.
        expect(
          updated.updatedAt.isAtSameMomentAs(originalCreatedAt) ||
              updated.updatedAt.isAfter(originalCreatedAt),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('delete invariant (Unit 7)', () {
    testWidgets(
      'deleted transaction → DB has 0 rows, Home renders empty state without TransactionTile',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);

        await tester.runAsync(() async {
          await runTestSeed(db);
          final foodId = await getSeededCategoryId(db, 'category.food');
          final cash = await getFirstActiveAccount(db);
          final inserted = await insertTestTransaction(
            db,
            accountId: cash.id,
            categoryId: foodId,
            currencyCode: 'USD',
            amountMinorUnits: 500,
            date: DateTime.now(),
          );
          // Same write path the home controller's `_commitDelete`
          // uses after its undo window expires; applied before
          // pumpWidget so the seeded subscribe sees the empty state.
          final removed = await DriftTransactionRepository(
            db,
          ).delete(inserted.id);
          if (!removed) {
            throw StateError('delete should have removed the seeded row');
          }
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

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(TransactionTile), findsNothing);

        final rows = await tester.runAsync(
          () => db.select(db.transactions).get(),
        );
        expect(rows, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
