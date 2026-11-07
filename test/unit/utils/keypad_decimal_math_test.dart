// Pure-helper tests for `KeypadState` — the Wave 2 §8 calculator-keypad
// state machine. Lives under utils because it is currency-aware integer
// arithmetic; no Flutter, Riverpod, or Drift bindings.
//
// Test IDs map to Wave 2 §8 / risk #1 (decimal-overflow clamp).
//
// Mental model:
//   - `amountMinorUnits` is the canonical integer amount, stored in the
//     currency's minor units (USD: cents, JPY: yen, ETH: wei).
//   - In *integer mode* (no decimal pressed yet), pressing a digit shifts
//     the existing minor-unit value by 10 and adds `digit * 10^decimals`.
//   - Pressing `.` enters *fractional mode* and tracks how many digits
//     after the decimal point have been entered. Further presses clamp
//     once `fractionalDigitsEntered == decimals`.

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/ui/features/transactions/view_models/amount_formula.dart';
import 'package:ledgerly/ui/features/transactions/view_models/keypad_state.dart';

/// A whole-number operand as the keypad records it.
FormulaOperand _whole(int minorUnits) => (
  amountMinorUnits: minorUnits,
  fractionalDigitsEntered: 0,
  isFractionalMode: false,
  isPercent: false,
);

void main() {
  group('KeypadState.push — integer mode', () {
    test('K02: push(1) on USD shifts to 100 minor units', () {
      final s = const KeypadState.initial().push(1, decimals: 2);
      expect(s.amountMinorUnits, 100);
      expect(s.isFractionalMode, isFalse);
    });

    test('K04: push(1).push(2).push(3) on JPY (decimals=0) yields 123', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 0)
          .push(2, decimals: 0)
          .push(3, decimals: 0);
      expect(s.amountMinorUnits, 123);
      expect(s.isFractionalMode, isFalse);
    });

    test('K05: push(0) on empty state stays at 0', () {
      final s = const KeypadState.initial().push(0, decimals: 2);
      expect(s.amountMinorUnits, 0);
    });
  });

  group('KeypadState.pushDecimal', () {
    test('K10: enters fractional mode on USD', () {
      final s = const KeypadState.initial().pushDecimal(decimals: 2);
      expect(s.isFractionalMode, isTrue);
      expect(s.fractionalDigitsEntered, 0);
      expect(s.amountMinorUnits, 0);
    });

    test('K11: rejects decimal on JPY (decimals=0)', () {
      // For a zero-decimal currency the decimal point is meaningless. The
      // keypad widget greys it out; the helper must also be a no-op so a
      // mistaken caller cannot toggle fractional mode.
      final s = const KeypadState.initial().pushDecimal(decimals: 0);
      expect(s.isFractionalMode, isFalse);
      expect(s.amountMinorUnits, 0);
    });

    test('K12: idempotent — second pushDecimal does not change state', () {
      final s = const KeypadState.initial()
          .pushDecimal(decimals: 2)
          .pushDecimal(decimals: 2);
      expect(s.isFractionalMode, isTrue);
      expect(s.fractionalDigitsEntered, 0);
    });
  });

  group('KeypadState.push — fractional mode', () {
    test('K21: 1 . 0 5 on USD → 105 minor units, 2 fractional digits', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .pushDecimal(decimals: 2)
          .push(0, decimals: 2)
          .push(5, decimals: 2);
      expect(s.amountMinorUnits, 105);
      expect(s.fractionalDigitsEntered, 2);
    });

    test('K22: . 5 on USD with no integer part → 50 minor units', () {
      // ".5" must produce 0.50 = 50 minor units, not 5.
      final s = const KeypadState.initial()
          .pushDecimal(decimals: 2)
          .push(5, decimals: 2);
      expect(s.amountMinorUnits, 50);
      expect(s.fractionalDigitsEntered, 1);
    });

    test('K23: clamp — 1 . 2 3 4 on USD drops the 4', () {
      // Risk #1: more digits than `currency.decimals` are silently dropped.
      // Helper must clamp at fractionalDigitsEntered == decimals.
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .pushDecimal(decimals: 2)
          .push(2, decimals: 2)
          .push(3, decimals: 2)
          .push(4, decimals: 2);
      expect(s.amountMinorUnits, 123);
      expect(s.fractionalDigitsEntered, 2);
    });
  });

  group('KeypadState — ETH-scale (decimals = 18)', () {
    test('K30: 1 . 5 on ETH → 1.5 * 10^18 = 1500000000000000000', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 18)
          .pushDecimal(decimals: 18)
          .push(5, decimals: 18);
      expect(s.amountMinorUnits, 1500000000000000000);
      expect(s.fractionalDigitsEntered, 1);
    });
  });

  group('KeypadState.pop — backspace', () {
    test('K40: pop in integer mode removes the last integer digit', () {
      final s0 = const KeypadState.initial()
          .push(1, decimals: 2)
          .push(2, decimals: 2);
      expect(s0.amountMinorUnits, 1200);
      final s1 = s0.pop(decimals: 2);
      expect(s1.amountMinorUnits, 100);
      expect(s1.isFractionalMode, isFalse);
    });

    test('K41: pop on a single-digit integer state returns 0', () {
      final s = const KeypadState.initial()
          .push(7, decimals: 2)
          .pop(decimals: 2);
      expect(s.amountMinorUnits, 0);
    });

    test('K42: pop on initial state is a no-op', () {
      final s = const KeypadState.initial().pop(decimals: 2);
      expect(s.amountMinorUnits, 0);
      expect(s.isFractionalMode, isFalse);
    });

    test('K43: pop in fractional mode removes the last fractional digit', () {
      // 1.05 → backspace → 1.0
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .pushDecimal(decimals: 2)
          .push(0, decimals: 2)
          .push(5, decimals: 2)
          .pop(decimals: 2);
      expect(s.amountMinorUnits, 100);
      expect(s.fractionalDigitsEntered, 1);
      expect(s.isFractionalMode, isTrue);
    });

    test('K44: pop with fractionalDigitsEntered=0 exits fractional mode', () {
      // 1. → backspace → 1 (back in integer mode).
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .pushDecimal(decimals: 2)
          .pop(decimals: 2);
      expect(s.amountMinorUnits, 100);
      expect(s.fractionalDigitsEntered, 0);
      expect(s.isFractionalMode, isFalse);
    });
  });

  group('KeypadState.clear', () {
    test('K50: clear resets to initial', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .pushDecimal(decimals: 2)
          .push(5, decimals: 2)
          .clear();
      expect(s.amountMinorUnits, 0);
      expect(s.fractionalDigitsEntered, 0);
      expect(s.isFractionalMode, isFalse);
    });
  });

  group('KeypadState — calculator fields', () {
    test('K60: initial state has no expression and no current input', () {
      const s = KeypadState.initial();

      expect(s.leftOperand(decimals: 2), isNull);
      expect(s.operator, isNull);
      expect(s.isEvaluating, isFalse);
      expect(s.showingResult, isFalse);
      expect(s.rightOperand, isNull);
      expect(s.hasCurrentInput, isFalse);
      expect(s.hasExpression, isFalse);
      expect(s.hasVisibleInput, isFalse);
    });
  });

  group('KeypadState.pushOperator', () {
    test('K69: operator on a truly untouched keypad is a no-op', () {
      const s = KeypadState.initial();

      final result = s.pushOperator(CalcOperator.add, decimals: 2);

      expect(result, s);
    });

    test(
      'K70: first operator stores the left operand and clears the input',
      () {
        final s = const KeypadState.initial()
            .push(1, decimals: 2)
            .push(2, decimals: 2); // 12.00

        final result = s.pushOperator(CalcOperator.add, decimals: 2);

        expect(result.leftOperand(decimals: 2), 1200);
        expect(result.operator, CalcOperator.add);
        expect(result.isEvaluating, isTrue);
        expect(result.amountMinorUnits, 0);
        expect(result.hasCurrentInput, isFalse);
      },
    );

    test('K71: tapping a different operator before right input replaces the pending operator', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .push(2, decimals: 2)
          .pushOperator(CalcOperator.multiply, decimals: 2);

      final result = s.pushOperator(CalcOperator.subtract, decimals: 2);

      expect(result.leftOperand(decimals: 2), 1200);
      expect(result.operator, CalcOperator.subtract);
      expect(result.amountMinorUnits, 0);
      expect(result.isEvaluating, isTrue);
      expect(result.hasCurrentInput, isFalse);
    });

    test('K72: repeating the same operator with no right input is a no-op', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .pushOperator(CalcOperator.add, decimals: 2);

      final result = s.pushOperator(CalcOperator.add, decimals: 2);
      expect(result, s);
    });

    test('K73: explicit integer zero counts as divide-by-zero input', () {
      final s = const KeypadState.initial()
          .push(7, decimals: 2)
          .pushOperator(CalcOperator.divide, decimals: 2)
          .push(0, decimals: 2);

      final result = s.equals(decimals: 2);

      expect(result.amountMinorUnits, 0);
      expect(result.showingResult, isTrue);
      expect(result.rightOperand, 0);
    });

    test('K74: explicit fractional zero also counts as right input', () {
      final s = const KeypadState.initial()
          .push(7, decimals: 2)
          .pushOperator(CalcOperator.divide, decimals: 2)
          .pushDecimal(decimals: 2)
          .push(0, decimals: 2);

      final result = s.equals(decimals: 2);

      expect(result.amountMinorUnits, 0);
      expect(result.showingResult, isTrue);
      expect(result.rightOperand, 0);
    });

    test('K80: 12 + 5 = 17', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .push(2, decimals: 2)
          .pushOperator(CalcOperator.add, decimals: 2)
          .push(5, decimals: 2);

      final result = s.equals(decimals: 2);
      expect(result.amountMinorUnits, 1700);
    });

    test('K81: 150 - 50 = 100', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .push(5, decimals: 2)
          .push(0, decimals: 2)
          .pushOperator(CalcOperator.subtract, decimals: 2)
          .push(5, decimals: 2)
          .push(0, decimals: 2);

      final result = s.equals(decimals: 2);
      expect(result.amountMinorUnits, 10000);
    });

    test('K82: 2 × 3 = 6', () {
      final s = const KeypadState.initial()
          .push(2, decimals: 2)
          .pushOperator(CalcOperator.multiply, decimals: 2)
          .push(3, decimals: 2);

      final result = s.equals(decimals: 2);
      expect(result.amountMinorUnits, 600);
    });

    test('K83: 100 ÷ 3 = 33.33', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .push(0, decimals: 2)
          .push(0, decimals: 2)
          .pushOperator(CalcOperator.divide, decimals: 2)
          .push(3, decimals: 2);

      final result = s.equals(decimals: 2);
      expect(result.amountMinorUnits, 3333);
    });

    test('K84: division half-up tie rounds up (1 ÷ 8 = 0.13)', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .pushOperator(CalcOperator.divide, decimals: 2)
          .push(8, decimals: 2);

      final result = s.equals(decimals: 2);
      expect(result.amountMinorUnits, 13);
    });

    test('K85: multiplication half-up tie rounds up (0.05 × 0.10 = 0.01)', () {
      final s = const KeypadState.initial()
          .pushDecimal(decimals: 2)
          .push(0, decimals: 2)
          .push(5, decimals: 2)
          .pushOperator(CalcOperator.multiply, decimals: 2)
          .pushDecimal(decimals: 2)
          .push(1, decimals: 2)
          .push(0, decimals: 2);

      final result = s.equals(decimals: 2);
      expect(result.amountMinorUnits, 1);
    });

    test('K86: subtraction underflow clamps to zero', () {
      final s = const KeypadState.initial()
          .push(3, decimals: 2)
          .pushOperator(CalcOperator.subtract, decimals: 2)
          .push(5, decimals: 2);

      final result = s.equals(decimals: 2);
      expect(result.amountMinorUnits, 0);
      expect(result.showingResult, isTrue);
    });
  });

  group('KeypadState — chaining and equals', () {
    test(
      'K87: a second operator chains instead of finishing (1 + 2 + 4 = 7)',
      () {
        final chained = const KeypadState.initial()
            .push(1, decimals: 2)
            .pushOperator(CalcOperator.add, decimals: 2)
            .push(2, decimals: 2)
            .pushOperator(CalcOperator.add, decimals: 2);

        expect(chained.leftOperand(decimals: 2), 300);
        expect(chained.operator, CalcOperator.add);
        expect(chained.isEvaluating, isTrue);
        expect(chained.showingResult, isFalse);
        expect(chained.amountMinorUnits, 0);

        final result = chained.push(4, decimals: 2).equals(decimals: 2);

        expect(result.amountMinorUnits, 700);
        expect(result.showingResult, isTrue);
        expect(result.leftOperand(decimals: 2), 300);
        expect(result.operator, CalcOperator.add);
        expect(result.rightOperand, 400);
      },
    );

    test('K88: chains evaluate strictly left to right (2 + 3 × 4 = 20)', () {
      final result = const KeypadState.initial()
          .push(2, decimals: 2)
          .pushOperator(CalcOperator.add, decimals: 2)
          .push(3, decimals: 2)
          .pushOperator(CalcOperator.multiply, decimals: 2)
          .push(4, decimals: 2)
          .equals(decimals: 2);

      expect(result.amountMinorUnits, 2000);
    });

    test('K89: equals with no right input drops the dangling operator', () {
      final result = const KeypadState.initial()
          .push(1, decimals: 2)
          .pushOperator(CalcOperator.add, decimals: 2)
          .equals(decimals: 2);

      expect(result.amountMinorUnits, 100);
      expect(result.showingResult, isTrue);
      expect(result.isEvaluating, isFalse);
      expect(result.leftOperand(decimals: 2), isNull);
      expect(result.operator, isNull);
    });

    test('K89b: equals without a pending expression is a no-op', () {
      final typed = const KeypadState.initial().push(5, decimals: 2);
      expect(typed.equals(decimals: 2), typed);

      const empty = KeypadState.initial();
      expect(empty.equals(decimals: 2), empty);

      final shown = typed
          .pushOperator(CalcOperator.add, decimals: 2)
          .push(1, decimals: 2)
          .equals(decimals: 2);
      expect(shown.equals(decimals: 2), shown);
    });

    test(
      'K89c: an operator after equals keeps calculating from the result',
      () {
        final result = const KeypadState.initial()
            .push(1, decimals: 2)
            .pushOperator(CalcOperator.add, decimals: 2)
            .push(2, decimals: 2)
            .equals(decimals: 2)
            .pushOperator(CalcOperator.add, decimals: 2)
            .push(4, decimals: 2)
            .equals(decimals: 2);

        expect(result.amountMinorUnits, 700);
      },
    );
  });

  group('KeypadState — editing the current operand', () {
    test('K90: digit during evaluating preserves the pending expression', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .pushOperator(CalcOperator.add, decimals: 2);

      final result = s.push(5, decimals: 2);

      expect(result.amountMinorUnits, 500);
      expect(result.leftOperand(decimals: 2), 100);
      expect(result.operator, CalcOperator.add);
      expect(result.isEvaluating, isTrue);
      expect(result.hasCurrentInput, isTrue);
    });

    test(
      'K91: decimal during evaluating marks the right operand as started',
      () {
        final s = const KeypadState.initial()
            .push(1, decimals: 2)
            .pushOperator(CalcOperator.add, decimals: 2);

        final result = s.pushDecimal(decimals: 2);

        expect(result.leftOperand(decimals: 2), 100);
        expect(result.operator, CalcOperator.add);
        expect(result.isEvaluating, isTrue);
        expect(result.hasCurrentInput, isTrue);
      },
    );

    test('K92: digit during showingResult clears the old expression and starts fresh', () {
      final s = KeypadState(
        amountMinorUnits: 1700,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        formulaOperands: [_whole(1200), _whole(500)],
        formulaOperators: [CalcOperator.add],
        showingResult: true,
        hasCurrentInput: false,
      );

      final result = s.push(3, decimals: 2);

      expect(result.amountMinorUnits, 300);
      expect(result.leftOperand(decimals: 2), isNull);
      expect(result.operator, isNull);
      expect(result.showingResult, isFalse);
      expect(result.hasCurrentInput, isTrue);
    });

    test('K92b: decimal during showingResult clears the old expression and starts a fresh fractional input', () {
      final s = KeypadState(
        amountMinorUnits: 1700,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        formulaOperands: [_whole(1200), _whole(500)],
        formulaOperators: [CalcOperator.add],
        showingResult: true,
        hasCurrentInput: false,
      );

      final result = s.pushDecimal(decimals: 2);

      expect(result.amountMinorUnits, 0);
      expect(result.leftOperand(decimals: 2), isNull);
      expect(result.operator, isNull);
      expect(result.showingResult, isFalse);
      expect(result.isFractionalMode, isTrue);
      expect(result.hasCurrentInput, isTrue);
    });

    test('K92c: operator during showingResult starts the next expression from the result', () {
      // 17 + = leaves 17.00 with no formula behind it, so the operator
      // starts a new formula from the result rather than continuing one.
      final s = KeypadState(
        amountMinorUnits: 1700,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        showingResult: true,
      );

      final result = s.pushOperator(CalcOperator.multiply, decimals: 2);

      expect(result.amountMinorUnits, 0);
      expect(result.formulaOperands, [_whole(1700)]);
      expect(result.formulaOperators, [CalcOperator.multiply]);
      expect(result.leftOperand(decimals: 2), 1700);
      expect(result.operator, CalcOperator.multiply);
      expect(result.isEvaluating, isTrue);
      expect(result.showingResult, isFalse);
      expect(result.hasCurrentInput, isFalse);
    });

    test('K93: pop with an empty right operand cancels the expression', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .push(2, decimals: 2)
          .pushOperator(CalcOperator.add, decimals: 2);

      final result = s.pop(decimals: 2);

      expect(result.amountMinorUnits, 1200);
      expect(result.leftOperand(decimals: 2), isNull);
      expect(result.operator, isNull);
      expect(result.isEvaluating, isFalse);
      expect(result.hasCurrentInput, isTrue);
    });

    test(
      'K94: pop with a non-empty right operand preserves the expression',
      () {
        final s = const KeypadState.initial()
            .push(1, decimals: 2)
            .push(2, decimals: 2)
            .pushOperator(CalcOperator.add, decimals: 2)
            .push(5, decimals: 2);

        final result = s.pop(decimals: 2);

        expect(result.amountMinorUnits, 0);
        expect(result.leftOperand(decimals: 2), 1200);
        expect(result.operator, CalcOperator.add);
        expect(result.isEvaluating, isTrue);
        expect(result.hasCurrentInput, isFalse);
      },
    );

    test('K95: backspacing an explicit zero returns to the empty-right-operand state', () {
      final s = const KeypadState.initial()
          .push(7, decimals: 2)
          .pushOperator(CalcOperator.divide, decimals: 2)
          .push(0, decimals: 2);

      final result = s.pop(decimals: 2);

      expect(result.amountMinorUnits, 0);
      expect(result.operator, CalcOperator.divide);
      expect(result.isEvaluating, isTrue);
      expect(result.hasCurrentInput, isFalse);
    });

    test('K96: clear resets every expression field', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .pushOperator(CalcOperator.add, decimals: 2)
          .push(5, decimals: 2);

      final result = s.clear();

      expect(result.amountMinorUnits, 0);
      expect(result.leftOperand(decimals: 2), isNull);
      expect(result.operator, isNull);
      expect(result.isEvaluating, isFalse);
      expect(result.showingResult, isFalse);
      expect(result.rightOperand, isNull);
      expect(result.hasCurrentInput, isFalse);
    });

    test('K97: pop on a result without a formula backtracks one digit', () {
      // 17 + = leaves 17.00 with no formula behind it.
      final s = KeypadState(
        amountMinorUnits: 1700,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        showingResult: true,
      );

      final result = s.pop(decimals: 2);

      expect(result.amountMinorUnits, 100);
      expect(result.leftOperand(decimals: 2), isNull);
      expect(result.operator, isNull);
      expect(result.showingResult, isFalse);
      expect(result.hasCurrentInput, isTrue);
    });

    test(
      'K97b: pop on a result reopens the formula and edits its last operand',
      () {
        final s = const KeypadState.initial()
            .push(1, decimals: 2)
            .pushDecimal(decimals: 2)
            .push(5, decimals: 2)
            .pushOperator(CalcOperator.add, decimals: 2)
            .push(2, decimals: 2)
            .equals(decimals: 2); // 1.5 + 2 = 3.50

        final result = s.pop(decimals: 2); // 1.5 +

        expect(result.showingResult, isFalse);
        expect(result.isEvaluating, isTrue);
        expect(result.leftOperand(decimals: 2), 150);
        expect(result.operator, CalcOperator.add);
        expect(result.amountMinorUnits, 0);
        expect(result.hasCurrentInput, isFalse);
      },
    );

    test(
      'K98: pop on a zero result without a formula exits the result state',
      () {
        final s = KeypadState(
          amountMinorUnits: 0,
          fractionalDigitsEntered: 0,
          isFractionalMode: false,
          showingResult: true,
        );

        final result = s.pop(decimals: 2);

        expect(result.showingResult, isFalse);
        expect(result.leftOperand(decimals: 2), isNull);
        expect(result.operator, isNull);
        expect(result.amountMinorUnits, 0);
      },
    );
  });

  group('KeypadState.pushPercent (issue #144)', () {
    // `%` turns the operand being typed into a percent, based on the
    // operator before it: of the running total for + and −, a fraction for
    // × and ÷, and a fraction straight away when there is no operator.
    KeypadState keys(String typed, {int decimals = 2}) {
      var s = const KeypadState.initial();
      for (final key in typed.split(' ')) {
        s = switch (key) {
          '+' => s.pushOperator(CalcOperator.add, decimals: decimals),
          '-' => s.pushOperator(CalcOperator.subtract, decimals: decimals),
          '*' => s.pushOperator(CalcOperator.multiply, decimals: decimals),
          '/' => s.pushOperator(CalcOperator.divide, decimals: decimals),
          '%' => s.pushPercent(decimals: decimals),
          '=' => s.equals(decimals: decimals),
          '<' => s.pop(decimals: decimals),
          '.' => s.pushDecimal(decimals: decimals),
          _ =>
            key
                .split('')
                .fold(s, (k, d) => k.push(int.parse(d), decimals: decimals)),
        };
      }
      return s;
    }

    test('K100: 200 − 10 % = 180', () {
      expect(keys('200 - 10 % =').amountMinorUnits, 18000);
    });

    test('K101: 200 + 10 % = 220', () {
      expect(keys('200 + 10 % =').amountMinorUnits, 22000);
    });

    test('K102: 200 × 10 % = 20', () {
      expect(keys('200 * 10 % =').amountMinorUnits, 2000);
    });

    test('K103: 200 ÷ 10 % = 2000', () {
      expect(keys('200 / 10 % =').amountMinorUnits, 200000);
    });

    test('K104: 10 % with no operator shows 0.1 straight away', () {
      final s = keys('10 %');
      expect(s.showingResult, isTrue);
      expect(s.amountMinorUnits, 10);
    });

    test(
      'K105: the operand keeps its typed value and is marked as a percent',
      () {
        final s = keys('200 - 10 %');
        expect(s.isEvaluating, isTrue);
        expect(s.isPercent, isTrue);
        expect(s.amountMinorUnits, 1000);
      },
    );

    test('K106: % with no operand typed is a no-op', () {
      expect(keys('%'), const KeypadState.initial());
      final pending = keys('200 -');
      expect(pending.pushPercent(decimals: 2), pending);
    });

    test('K107: % pressed twice is a no-op', () {
      final once = keys('200 - 10 %');
      expect(once.pushPercent(decimals: 2), once);
    });

    test('K108: ⌫ after % removes the % and keeps the operand', () {
      final s = keys('200 - 10 % <');
      expect(s, keys('200 - 10'));
    });

    test('K109: ⌫ after 10 % gives back 10', () {
      expect(keys('10 % <'), keys('10'));
    });

    test('K109b: ⌫ on the operator after 10 % goes back to the 0.1 result', () {
      expect(keys('10 % + <'), keys('10 %'));
      expect(keys('10 % * <').equals(decimals: 2).amountMinorUnits, 10);
    });

    test('K110: digits and . after % are ignored', () {
      final s = keys('200 - 10 %');
      expect(s.push(5, decimals: 2), s);
      expect(s.pushDecimal(decimals: 2), s);
    });

    test('K111: % on a result is a no-op', () {
      final s = keys('200 - 10 =');
      expect(s.pushPercent(decimals: 2), s);
    });

    test('K112: an operator after % commits the percent and chains', () {
      expect(keys('200 - 10 % + 5 =').amountMinorUnits, 18500);
    });

    test('K113: a percent of zero divides to zero', () {
      expect(keys('200 / 0 % =').amountMinorUnits, 0);
    });

    test('K114: JPY rounds the percent half away from zero', () {
      expect(keys('200 - 10 % =', decimals: 0).amountMinorUnits, 180);
      // 155 − 15.5 → 155 − 16
      expect(keys('155 - 10 % =', decimals: 0).amountMinorUnits, 139);
      expect(keys('200 * 10 % =', decimals: 0).amountMinorUnits, 20);
      expect(keys('200 / 10 % =', decimals: 0).amountMinorUnits, 2000);
      // 0.1 yen rounds to 0
      expect(keys('10 %', decimals: 0).amountMinorUnits, 0);
    });

    test('K115: ETH (18 decimals) keeps full precision', () {
      // Operands stay under 9.2 ETH, the most an int holds in wei.
      const eth = 1000000000000000000;
      // 2 − 5 % = 1.9
      expect(keys('2 - 5 % =', decimals: 18).amountMinorUnits, eth ~/ 10 * 19);
      expect(keys('2 * 5 % =', decimals: 18).amountMinorUnits, eth ~/ 10);
      expect(keys('0 . 2 / 5 % =', decimals: 18).amountMinorUnits, eth * 4);
      expect(keys('5 %', decimals: 18).amountMinorUnits, eth ~/ 20);
    });
  });
}
