// Memo suggestions end to end: real Drift DB → repository query →
// provider → chips under the MemoField → tap → Save persists the memo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/locale_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/app/providers/theme_provider.dart';
import 'package:ledgerly/app/router.dart';
import 'package:ledgerly/features/transactions/widgets/category_chip.dart';
import 'package:ledgerly/features/transactions/widgets/memo_field.dart';

import '../support/test_app.dart';

@Dependencies([router, themeMode, userLocalePreference, exchangeRateRepository])
void main() {
  testWidgets(
    'picking a category shows its recent memos; tapping one is saved',
    (tester) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await tester.runAsync(() async {
        await runTestSeed(db);
        final foodId = await getSeededCategoryId(db, 'category.food');
        final cash = await getDefaultAccount(db);
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        for (final (i, memo) in ['Coffee', 'Lunch'].indexed) {
          await insertTestTransaction(
            db,
            accountId: cash.id,
            categoryId: foodId,
            currencyCode: 'USD',
            amountMinorUnits: 500,
            date: yesterday.add(Duration(minutes: i)),
            memo: memo,
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

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add transaction'));
      await tester.pumpAndSettle();

      // No category yet → no suggestions.
      expect(find.byType(ActionChip), findsNothing);

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CategoryChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').last);
      await tester.pumpAndSettle();

      // Most recently used first.
      final lunch = find.widgetWithText(ActionChip, 'Lunch');
      final coffee = find.widgetWithText(ActionChip, 'Coffee');
      expect(lunch, findsOneWidget);
      expect(coffee, findsOneWidget);
      expect(
        tester.getTopLeft(lunch).dx,
        lessThan(tester.getTopLeft(coffee).dx),
      );

      await tester.ensureVisible(coffee);
      await tester.tap(coffee);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(MemoField),
          matching: find.text('Coffee'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      final rows = await tester.runAsync(
        () => db.select(db.transactions).get(),
      );
      expect(rows, hasLength(3));
      final saved = rows!.firstWhere((r) => r.amountMinorUnits == 100);
      expect(saved.memo, 'Coffee');
      expect(tester.takeException(), isNull);
    },
  );
}
