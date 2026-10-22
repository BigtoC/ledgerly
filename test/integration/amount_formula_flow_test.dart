// Keypad formula round trip through the real Drift database: type a
// formula on Add, save, reopen the row on Edit in a fresh container, check
// the keypad recalculates it, edit it, and save again.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/features/transactions/keypad_state.dart';
import 'package:ledgerly/features/transactions/transaction_form_controller.dart';
import 'package:ledgerly/features/transactions/transaction_form_state.dart';

import '../support/test_app.dart';

@Dependencies([TransactionFormController, categoryRepository])
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
      final saved = await adder.save();

      final row = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(saved!.id))).getSingle();
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
}
