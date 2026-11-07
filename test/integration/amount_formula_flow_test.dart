// Keypad formula round trip through the real Drift database: type a
// formula on Add, save, reopen the row on Edit in a fresh container, check
// the keypad recalculates it, edit it, and save again. The percent flow
// (issue #144) drives the app shell: Home → Add → keypad Save → Edit.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/exchange_rates_provider.dart';
import 'package:ledgerly/app/providers/locale_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/app/providers/theme_provider.dart';
import 'package:ledgerly/app/router.dart';
import 'package:ledgerly/ui/features/home/views/transaction_tile.dart';
import 'package:ledgerly/ui/features/transactions/views/amount_display.dart';
import 'package:ledgerly/ui/features/transactions/views/calculator_keypad.dart';
import 'package:ledgerly/ui/features/transactions/views/category_chip.dart';
import 'package:ledgerly/ui/features/transactions/view_models/keypad_state.dart';
import 'package:ledgerly/ui/features/transactions/view_models/transaction_form_controller.dart';
import 'package:ledgerly/ui/features/transactions/view_models/transaction_form_state.dart';

import '../support/test_app.dart';

@Dependencies([
  TransactionFormController,
  categoryRepository,
  router,
  themeMode,
  userLocalePreference,
  exchangeRateRepository,
  exchangeRates,
])
void main() {
  test(
    'formula saved on Add reloads on Edit, recalculates, and saves edits',
    () async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await runTestSeed(db);
      final foodId = await getSeededCategoryId(db, 'category.food');

      @Dependencies([TransactionFormController])
      ProviderContainer open() {
        final c = makeTestContainer(db: db);
        addTearDown(c.dispose);
        // Keep the auto-dispose form controller alive between commands.
        c.listen(transactionFormControllerProvider, (_, _) {});
        return c;
      }

      @Dependencies([TransactionFormController])
      TransactionFormData form(ProviderContainer c) =>
          c.read(transactionFormControllerProvider) as TransactionFormData;

      // Add: 3.5 + 10.5 + 11 + 3, saved without pressing =.
      final add = open();
      final adder = add.read(transactionFormControllerProvider.notifier);
      await adder.hydrateForAdd();
      final food = await add.read(categoryRepositoryProvider).getById(foodId);
      adder
        ..selectCategory(food!)
        ..appendDigit(3)
        ..appendDecimal()
        ..appendDigit(5)
        ..applyOperator(CalcOperator.add)
        ..appendDigit(1)
        ..appendDigit(0)
        ..appendDecimal()
        ..appendDigit(5)
        ..applyOperator(CalcOperator.add)
        ..appendDigit(1)
        ..appendDigit(1)
        ..applyOperator(CalcOperator.add)
        ..appendDigit(3);
      final saved = (await adder.save() as SaveTransactionSaved).transaction;

      final row = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(saved.id))).getSingle();
      expect(row.amountMinorUnits, 2800);
      expect(row.amountFormula, '3.5+10.5+11+3');

      // Edit in a fresh container: the keypad is rebuilt from the text.
      final edit = open();
      final editor = edit.read(transactionFormControllerProvider.notifier);
      await editor.hydrateForEdit(row.id);
      expect(form(edit).amountMinorUnits, 2800);
      expect(form(edit).keypad.showingResult, isTrue);
      expect(form(edit).keypad.formula(decimals: 2), '3.5+10.5+11+3');

      // Backspace the 3, type 5: recalculates to 30.00.
      editor
        ..backspace()
        ..appendDigit(5);
      expect(form(edit).amountMinorUnits, 3000);
      await editor.save();

      final edited = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(row.id))).getSingle();
      expect(edited.amountMinorUnits, 3000);
      expect(edited.amountFormula, '3.5+10.5+11+5');
    },
  );

  testWidgets(
    '200 − 10 % saved from the keypad reopens as 200 − 10% = 180 (#144)',
    (tester) async {
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add transaction'));
      await tester.pumpAndSettle();
      for (final key in ['2', '0', '0', '−', '1', '0', '%']) {
        await tester.tap(
          find.descendant(
            of: find.byType(CalculatorKeypad),
            matching: find.text(key),
          ),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byType(CategoryChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      final rows = await tester.runAsync(
        () => db.select(db.transactions).get(),
      );
      expect(rows!.single.amountMinorUnits, 18000);
      expect(rows.single.amountFormula, '200-10%');

      await tester.tap(find.byType(TransactionTile));
      await tester.pumpAndSettle();

      final display = find.byType(AmountDisplay);
      expect(
        find.descendant(of: display, matching: find.text('200 − 10% =')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: display, matching: find.text('180.00')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
