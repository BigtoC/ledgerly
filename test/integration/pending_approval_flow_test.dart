// End-to-end integration test for pending approval flow.
//
// Exercises: seed → insert pending row → land on Home → approve →
// verify pending row deleted and transaction inserted. Also covers the
// Settings › Pending transactions page (/settings/pending).

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/locale_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/app/providers/theme_provider.dart';
import 'package:ledgerly/app/router.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

import '../support/test_app.dart';

@Dependencies([router, themeMode, userLocalePreference, exchangeRateRepository])
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
      'approving one of N pending rows on the same day leaves the others on '
      'screen',
      (tester) async {
        // Regression for user report: when multiple rules each have a
        // pending dated for the same day visible on Home, approving one
        // tile must NOT remove the others. Pendings are day-scoped (each
        // Home day's view shows only that day's pending rows), so we seed
        // all three on today's date for them to be visible at once.
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

        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);

        // Three pending rows all dated today (mirrors the device-DB
        // scenario where multiple daily rules each produced one
        // today-dated pending). Memos are unique so we can find each
        // tile by text.
        Future<void> seed(String memo) => pendingRepo.insert(
          source: 'recurring',
          amountMinorUnits: 1599,
          currencyCode: account.currency.code,
          categoryId: categoryId,
          accountId: account.id,
          memo: memo,
          date: todayMidnight,
          fetchedAt: todayMidnight,
        );
        await seed('Day6');
        await seed('Day7');
        await seed('Day8');

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

        // The new transaction must carry the pending row's date (today,
        // since we seeded today-dated pendings to keep them all visible on
        // the default Home view). Read directly from the DB to bypass any
        // UI filtering.
        final approvedTx = await tester.runAsync(() async {
          final all = await db.select(db.transactions).get();
          return all.firstWhere((t) => t.memo == 'Day7');
        });
        expect(approvedTx, isNotNull);
        expect(approvedTx!.date, todayMidnight);
      },
    );

    testWidgets('PendingSection only shows pending rows whose date matches the '
        'selected day on Home', (tester) async {
      // Bug repro from device DB 2026-05-09: multiple daily rules each
      // generate a today-dated pending row. The user navigated to a
      // past day's Home view and saw the global pending tiles still
      // rendered, mistook them for past-day pendings, and tapped
      // approve. The correct UX is: each Home day's view shows only
      // the pending rows dated for that day (PendingSection is
      // day-scoped, not global).
      final txRepo = DriftTransactionRepository(db);
      final pendingRepo = DriftPendingTransactionRepository(db, txRepo: txRepo);
      final categoryId = await getSeededCategoryId(db, 'category.food');
      final account = await getDefaultAccount(db);

      // Seed history so HomeData renders.
      await insertTestTransaction(
        db,
        accountId: account.id,
        categoryId: categoryId,
        currencyCode: account.currency.code,
        amountMinorUnits: 100,
        memo: 'historical',
      );

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final twoDaysAgo = todayMidnight.subtract(const Duration(days: 2));

      // Two pending rows: one dated TODAY (should be visible on Home's
      // default today view), one dated TWO DAYS AGO (must be hidden on
      // today's view).
      await pendingRepo.insert(
        source: 'recurring',
        amountMinorUnits: 1599,
        currencyCode: account.currency.code,
        categoryId: categoryId,
        accountId: account.id,
        memo: 'TodayPending',
        date: todayMidnight,
        fetchedAt: todayMidnight,
      );
      await pendingRepo.insert(
        source: 'recurring',
        amountMinorUnits: 1599,
        currencyCode: account.currency.code,
        categoryId: categoryId,
        accountId: account.id,
        memo: 'PastPending',
        date: twoDaysAgo,
        fetchedAt: todayMidnight,
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

      // On today's view, only today's pending must be visible.
      expect(
        find.text('TodayPending'),
        findsOneWidget,
        reason: 'today-dated pending must show on today view',
      );
      expect(
        find.text('PastPending'),
        findsNothing,
        reason:
            'past-dated pending must NOT show on today view — '
            'PendingSection is day-scoped',
      );
    });

    testWidgets(
      "Settings pending page approves and skips; Home's skip undo still "
      'works afterwards',
      (tester) async {
        late DriftPendingTransactionRepository pendingRepo;
        await tester.runAsync(() async {
          final txRepo = DriftTransactionRepository(db);
          pendingRepo = DriftPendingTransactionRepository(db, txRepo: txRepo);
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

          final today = DateTime.now();
          final todayMidnight = DateTime(today.year, today.month, today.day);
          for (final memo in ['Netflix', 'Spotify', 'Gym']) {
            await pendingRepo.insert(
              source: 'recurring',
              amountMinorUnits: 1599,
              currencyCode: account.currency.code,
              categoryId: categoryId,
              accountId: account.id,
              memo: memo,
              date: todayMidnight,
              fetchedAt: todayMidnight,
            );
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
        final router = container.read(routerProvider);

        Future<List<String?>> storedMemos() async =>
            (await tester.runAsync(() => pendingRepo.watchAll().first))!
                .map((p) => p.memo)
                .toList();

        /// Swipes [memo]'s row and taps Skip once; returns 1 s after the
        /// tap, when any earlier snackbar has left and the Undo one entered.
        Future<void> skip(String memo) async {
          await tester.drag(find.text(memo), const Offset(-300, 0));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.tap(find.text('Skip once'));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump(const Duration(milliseconds: 500));
        }

        await tester.pumpWidget(buildTestApp(container: container));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        router.go('/settings/pending');
        await tester.pumpAndSettle();
        expect(find.text('Netflix'), findsOneWidget);
        expect(find.text('Spotify'), findsOneWidget);
        expect(find.text('Gym'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.ancestor(
              of: find.text('Netflix'),
              matching: find.byType(ListTile),
            ),
            matching: find.byIcon(Icons.check),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Approved — Netflix'), findsOneWidget);
        expect(await storedMemos(), ['Gym', 'Spotify']);

        // Skip, then Undo, on the page: the row comes back and stays.
        await skip('Spotify');
        expect(find.text('Spotify'), findsNothing);
        expect(find.text('Skipped this occurrence'), findsOneWidget);
        tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Spotify'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        expect(await storedMemos(), ['Gym', 'Spotify']);

        // A skip left alone on the page commits once the window lapses.
        await skip('Gym');
        expect(find.text('Gym'), findsNothing);
        await tester.pump(const Duration(seconds: 4));
        // The Undo snackbar finishes leaving.
        await tester.pump(const Duration(milliseconds: 300));
        expect(await storedMemos(), ['Spotify']);
        expect(find.byType(SnackBarAction), findsNothing);

        router.go('/settings');
        await tester.pumpAndSettle();
        router.go('/home');
        await tester.pumpAndSettle();

        // Home's skip still gets its Undo snackbar from the shell host.
        await skip('Spotify');
        expect(find.text('Skipped this occurrence'), findsOneWidget);

        tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Spotify'), findsOneWidget);
      },
    );

    // Note: a previous test asserted that approving a past-dated pending
    // tile from today's view pinned Home to that past day so the new tx
    // was immediately visible. With day-scoping (PendingSection only shows
    // tiles whose date matches the selected day), past tiles are no longer
    // reachable from today's view — the user navigates to the past day
    // first, sees the tile, and approves there. The new tx then appears in
    // that day's list naturally via watchByDay re-emission. The earlier
    // pinDay-after-approve call in pending_section.dart remains as a
    // harmless no-op safety net (item.date == selectedDay in the
    // day-scoped flow).
  });
}
