// M6 review follow-up — real mutation-flow integration coverage.
//
// These tests intentionally drive the production app shell instead of
// pre-seeding final state: Home -> TransactionFormScreen -> repository save ->
// route pop -> Home stream refresh. This is the coverage that seeded-state
// tests cannot provide.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/features/home/home_screen.dart';
import 'package:ledgerly/features/home/widgets/transaction_tile.dart';
import 'package:ledgerly/features/transactions/widgets/category_chip.dart';

import '../support/test_app.dart';

void main() {
  group('transaction mutation integration', () {
    Future<void> pumpHome(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    Future<void> enterAmountAndFood(WidgetTester tester, String digits) async {
      for (final codeUnit in digits.codeUnits) {
        await tester.tap(find.text(String.fromCharCode(codeUnit)));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byType(CategoryChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').last);
      await tester.pumpAndSettle();
    }

    Future<void> saveForm(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('Home FAB -> Add form -> Save persists row and returns Home', (
      tester,
    ) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await tester.runAsync(() => runTestSeed(db));

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
      await pumpHome(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(TransactionTile), findsNothing);

      await tester.tap(find.byTooltip('Add transaction'));
      await tester.pumpAndSettle();
      expect(find.text('Add transaction'), findsOneWidget);

      await enterAmountAndFood(tester, '1');
      await saveForm(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(TransactionTile), findsOneWidget);

      final rows = await tester.runAsync(
        () => db.select(db.transactions).get(),
      );
      expect(rows, hasLength(1));
      expect(rows!.single.amountMinorUnits, 100);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home duplicate action saves a second row dated today', (
      tester,
    ) async {
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
      await pumpHome(tester);

      await tester.tap(find.byKey(const ValueKey('homeTile:1:menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();

      expect(find.text('Add transaction'), findsOneWidget);
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      await saveForm(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      final rows = await tester.runAsync(
        () => db.select(db.transactions).get(),
      );
      expect(rows, hasLength(2));
      rows!.sort((a, b) => a.id.compareTo(b.id));
      expect(rows[0].amountMinorUnits, 500);
      expect(rows[1].amountMinorUnits, 200);
      expect(rows[1].categoryId, rows[0].categoryId);
      final today = DateTime.now();
      expect(rows[1].date.year, today.year);
      expect(rows[1].date.month, today.month);
      expect(rows[1].date.day, today.day);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'gap day: Add from empty-day state pins the new row to that day',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        // Seed a transaction on yesterday so Home opens with history but
        // today is a gap day (no transactions today).
        await tester.runAsync(() async {
          await runTestSeed(db);
          final foodId = await getSeededCategoryId(db, 'category.food');
          final cash = await getDefaultAccount(db);
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          await insertTestTransaction(
            db,
            accountId: cash.id,
            categoryId: foodId,
            currencyCode: 'USD',
            amountMinorUnits: 100,
            date: yesterday,
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
        await pumpHome(tester);

        // Today is a gap day — the empty-day message should be visible.
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('No transaction'), findsOneWidget);
        expect(find.byType(TransactionTile), findsNothing);

        await tester.tap(find.byTooltip('Add transaction'));
        await tester.pumpAndSettle();
        expect(find.text('Add transaction'), findsOneWidget);

        await enterAmountAndFood(tester, '5');
        await saveForm(tester);

        // Home should show the new tile; the gap-day message should be gone.
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(TransactionTile), findsOneWidget);
        expect(find.text('No transaction'), findsNothing);

        final rows = await tester.runAsync(
          () => db.select(db.transactions).get(),
        );
        expect(rows, hasLength(2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Home row edit saves through form and updates the DB row', (
      tester,
    ) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      late int txId;
      late DateTime originalCreatedAt;
      await tester.runAsync(() async {
        await runTestSeed(db);
        final foodId = await getSeededCategoryId(db, 'category.food');
        final cash = await getDefaultAccount(db);
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
      await pumpHome(tester);

      await tester.tap(find.byType(TransactionTile));
      await tester.pumpAndSettle();
      expect(find.text('Edit transaction'), findsOneWidget);

      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      await saveForm(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      final rows = await tester.runAsync(
        () => db.select(db.transactions).get(),
      );
      expect(rows, hasLength(1));
      final updated = rows!.single;
      expect(updated.id, txId);
      expect(updated.amountMinorUnits, 900);
      expect(updated.createdAt, originalCreatedAt);
      expect(
        updated.updatedAt.isAtSameMomentAs(originalCreatedAt) ||
            updated.updatedAt.isAfter(originalCreatedAt),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
