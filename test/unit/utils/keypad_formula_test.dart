// Formula tracking on `KeypadState`: the keypad remembers every operand as
// typed so the expression can be stored, reloaded, recalculated, and edited.

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/transactions/amount_formula.dart';
import 'package:ledgerly/features/transactions/keypad_state.dart';

const _usd = 2;

/// Types [keys] into [start]. Digits and `.` enter numbers, `+ - * /` are
/// operators, `=` is equals, `<` is backspace, `C` is clear.
KeypadState type(
  String keys, {
  int decimals = _usd,
  KeypadState start = const KeypadState.initial(),
}) {
  var s = start;
  for (final key in keys.split('')) {
    s = switch (key) {
      '.' => s.pushDecimal(decimals: decimals),
      '+' => s.pushOperator(CalcOperator.add, decimals: decimals),
      '-' => s.pushOperator(CalcOperator.subtract, decimals: decimals),
      '*' => s.pushOperator(CalcOperator.multiply, decimals: decimals),
      '/' => s.pushOperator(CalcOperator.divide, decimals: decimals),
      '=' => s.equals(decimals: decimals),
      '<' => s.pop(decimals: decimals),
      'C' => s.clear(),
      _ => s.push(int.parse(key), decimals: decimals),
    };
  }
  return s;
}

KeypadState load(String formula, {int decimals = _usd}) =>
    KeypadState.fromFormula(
      parseAmountFormula(formula, decimals: decimals)!,
      decimals: decimals,
    );

int finished(KeypadState s, {int decimals = _usd}) =>
    s.equals(decimals: decimals).amountMinorUnits;

void main() {
  group('formula while typing', () {
    test('records every operand as typed', () {
      final s = type('3.5+10.5+11+3');
      expect(s.formula(decimals: _usd), '3.5+10.5+11+3');
      expect(finished(s), 2800);
    });

    test('equals keeps the formula', () {
      final s = type('3.5+10.5+11+3=');
      expect(s.showingResult, isTrue);
      expect(s.amountMinorUnits, 2800);
      expect(s.formula(decimals: _usd), '3.5+10.5+11+3');
    });

    test('a dangling operator is left out', () {
      expect(type('1+2+').formula(decimals: _usd), '1+2');
      final done = type('1+2+=');
      expect(done.amountMinorUnits, 300);
      expect(done.formula(decimals: _usd), '1+2');
    });

    test('a single operand is not a formula', () {
      expect(type('28').formula(decimals: _usd), isNull);
      expect(type('28+').formula(decimals: _usd), isNull);
      expect(type('28+=').formula(decimals: _usd), isNull);
      expect(const KeypadState.initial().formula(decimals: _usd), isNull);
    });

    test('replacing a pending operator replaces it in the formula', () {
      expect(type('6+*2').formula(decimals: _usd), '6*2');
      expect(finished(type('6+*2')), 1200);
    });

    test('an operator after a result continues the formula', () {
      final s = type('1+2=+3');
      expect(s.formula(decimals: _usd), '1+2+3');
      expect(finished(s), 600);
    });

    test('an operator after a formula-less result starts from it', () {
      expect(type('5+=*2').formula(decimals: _usd), '5*2');
    });

    test('a digit after a result starts a new amount', () {
      expect(type('1+2=5').formula(decimals: _usd), isNull);
      expect(type('1+2=5+1').formula(decimals: _usd), '5+1');
    });

    test('clear drops the formula', () {
      expect(type('1+2C').formula(decimals: _usd), isNull);
    });

    test('backspace inside the current operand keeps the formula', () {
      expect(type('1+23<').formula(decimals: _usd), '1+2');
    });
  });

  group('backspace walks back through the formula', () {
    test('past a dangling operator reopens the previous operand', () {
      final s = type('1.5+2+<');
      expect(s.isEvaluating, isTrue);
      expect(s.leftOperand, 150);
      expect(s.operator, CalcOperator.add);
      expect(s.amountMinorUnits, 200);
      expect(s.hasCurrentInput, isTrue);
      expect(s.formula(decimals: _usd), '1.5+2');
    });

    test('past the only operator restores the first operand as typed', () {
      final s = type('1.5+<');
      expect(s.hasExpression, isFalse);
      expect(s.amountMinorUnits, 150);
      expect(s.isFractionalMode, isTrue);
      expect(s.fractionalDigitsEntered, 1);
      expect(s.formula(decimals: _usd), isNull);
    });

    test('one character at a time back to empty', () {
      var s = type('12+3.4');
      final seen = <String?>[];
      for (var i = 0; i < 6; i++) {
        s = s.pop(decimals: _usd);
        seen.add(s.formula(decimals: _usd));
      }
      // 12+3. → 12+3 → 12+ → 12 → 1 → 0
      expect(seen, ['12+3', '12+3', null, null, null, null]);
      expect(s.hasVisibleInput, isFalse);
    });
  });

  group('KeypadState.fromFormula', () {
    test('recalculates the stored formula and shows the result', () {
      final s = load('3.5+10.5+11+3');
      expect(s.showingResult, isTrue);
      expect(s.amountMinorUnits, 2800);
      expect(s.formula(decimals: _usd), '3.5+10.5+11+3');
      expect(s, type('3.5+10.5+11+3='));
    });

    test('evaluates left to right like the keys', () {
      expect(load('2+3*4').amountMinorUnits, 2000);
      expect(load('10/4').amountMinorUnits, 250);
      expect(load('1-5+6').amountMinorUnits, 200);
      expect(load('1-5+2').amountMinorUnits, 0);
      expect(load('1500*3', decimals: 0).amountMinorUnits, 4500);
    });

    test('backspace edits the last operand', () {
      final s = load('3.5+10.5+11+3').pop(decimals: _usd);
      expect(s.isEvaluating, isTrue);
      expect(s.hasCurrentInput, isFalse);
      expect(s.formula(decimals: _usd), '3.5+10.5+11');
      expect(finished(s), 2500);

      final edited = type('5', start: s);
      expect(edited.formula(decimals: _usd), '3.5+10.5+11+5');
      expect(finished(edited), 3000);
    });

    test('backspace edits a fractional last operand digit by digit', () {
      final s = load('1+2.25').pop(decimals: _usd);
      expect(s.formula(decimals: _usd), '1+2.2');
      expect(finished(s), 320);
    });

    test('an operator appends to the loaded formula', () {
      final s = type('+2', start: load('3.5+10.5+11+3'));
      expect(s.formula(decimals: _usd), '3.5+10.5+11+3+2');
      expect(finished(s), 3000);
    });

    test('a digit replaces the loaded formula', () {
      final s = type('9', start: load('3.5+10.5+11+3'));
      expect(s.formula(decimals: _usd), isNull);
      expect(s.amountMinorUnits, 900);
    });
  });

  group('first operand from a stored amount', () {
    test('a hydrated amount is recorded without trailing zeros', () {
      final usd = type('+1', start: KeypadState.fromAmount(350, decimals: 2));
      expect(usd.formula(decimals: _usd), '3.5+1');

      final eth = type(
        '+1',
        decimals: 18,
        start: KeypadState.fromAmount(500000000000000000, decimals: 18),
      );
      expect(eth.formula(decimals: 18), '0.5+1');
    });

    test('a formula-less result is recorded without trailing zeros', () {
      expect(type('1.5+=*2').formula(decimals: _usd), '1.5*2');
    });
  });

  group('only the result is clamped at zero', () {
    test('a negative subtotal carries through, so the formula holds', () {
      final s = type('5-10+20=');
      expect(s.amountMinorUnits, 1500);
      expect(s.formula(decimals: _usd), '5-10+20');
      expect(load('5-10+20').amountMinorUnits, 1500);
    });

    test('negative subtotals round away from zero like positive ones', () {
      // (1 - 3.33) × 1.5 = -3.495 -> -3.50, then + 5 = 1.50.
      expect(finished(type('1-3.33*1.5+5')), 150);
      // (1 - 2) ÷ 3 = -0.333.. -> -0.33, then + 1 = 0.67.
      expect(finished(type('1-2/3+1')), 67);
    });

    test('a negative result is clamped to zero', () {
      expect(finished(type('3-5')), 0);
      expect(finished(type('5-10*2')), 0);
      expect(type('3-5=').amountMinorUnits, 0);
      // A dangling operator after a negative subtotal finishes at zero.
      expect(type('3-5+=').amountMinorUnits, 0);
      expect(load('5-10*2').amountMinorUnits, 0);
    });

    test('continuing after a clamped result resumes the formula', () {
      final s = type('3-5=+2');
      expect(s.formula(decimals: _usd), '3-5+2');
      expect(finished(s), 0);
      expect(finished(type('+2', start: load('3-5'))), 0);
    });
  });
}
