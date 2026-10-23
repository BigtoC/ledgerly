import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/transactions/amount_formula.dart';
import 'package:ledgerly/features/transactions/keypad_state.dart';

void main() {
  group('encodeFormulaOperand', () {
    test('integer operand has no decimal separator', () {
      expect(
        encodeFormulaOperand((
          amountMinorUnits: 1100,
          fractionalDigitsEntered: 0,
          isFractionalMode: false,
        ), decimals: 2),
        '11',
      );
    });

    test('fractional operand keeps only the digits the user typed', () {
      expect(
        encodeFormulaOperand((
          amountMinorUnits: 350,
          fractionalDigitsEntered: 1,
          isFractionalMode: true,
        ), decimals: 2),
        '3.5',
      );
      expect(
        encodeFormulaOperand((
          amountMinorUnits: 305,
          fractionalDigitsEntered: 2,
          isFractionalMode: true,
        ), decimals: 2),
        '3.05',
      );
    });

    test('trailing fractional zeros are dropped', () {
      expect(
        encodeFormulaOperand((
          amountMinorUnits: 350,
          fractionalDigitsEntered: 2,
          isFractionalMode: true,
        ), decimals: 2),
        '3.5',
      );
      expect(
        encodeFormulaOperand((
          amountMinorUnits: 300,
          fractionalDigitsEntered: 2,
          isFractionalMode: true,
        ), decimals: 2),
        '3',
      );
      expect(
        encodeFormulaOperand((
          amountMinorUnits: 500000000000000000,
          fractionalDigitsEntered: 18,
          isFractionalMode: true,
        ), decimals: 18),
        '0.5',
      );
    });

    test('a dangling decimal point is dropped', () {
      expect(
        encodeFormulaOperand((
          amountMinorUnits: 300,
          fractionalDigitsEntered: 0,
          isFractionalMode: true,
        ), decimals: 2),
        '3',
      );
    });

    test('zero-decimal currency', () {
      expect(
        encodeFormulaOperand((
          amountMinorUnits: 1500,
          fractionalDigitsEntered: 0,
          isFractionalMode: false,
        ), decimals: 0),
        '1500',
      );
    });
  });

  group('encodeAmountFormula', () {
    test('joins operands with ASCII operators', () {
      expect(
        encodeAmountFormula(
          operands: [
            (
              amountMinorUnits: 350,
              fractionalDigitsEntered: 1,
              isFractionalMode: true,
            ),
            (
              amountMinorUnits: 1050,
              fractionalDigitsEntered: 1,
              isFractionalMode: true,
            ),
            (
              amountMinorUnits: 1100,
              fractionalDigitsEntered: 0,
              isFractionalMode: false,
            ),
            (
              amountMinorUnits: 300,
              fractionalDigitsEntered: 0,
              isFractionalMode: false,
            ),
          ],
          operators: const [
            CalcOperator.add,
            CalcOperator.add,
            CalcOperator.add,
          ],
          decimals: 2,
        ),
        '3.5+10.5+11+3',
      );
    });

    test('encodes every operator', () {
      const one = (
        amountMinorUnits: 100,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
      );
      expect(
        encodeAmountFormula(
          operands: const [one, one, one, one, one],
          operators: const [
            CalcOperator.add,
            CalcOperator.subtract,
            CalcOperator.multiply,
            CalcOperator.divide,
          ],
          decimals: 2,
        ),
        '(1+1-1)*1/1',
      );
    });
  });

  group('parseAmountFormula', () {
    test('round-trips the user example', () {
      final parsed = parseAmountFormula('3.5+10.5+11+3', decimals: 2)!;
      expect(parsed.operators, const [
        CalcOperator.add,
        CalcOperator.add,
        CalcOperator.add,
      ]);
      expect(parsed.operands, const [
        (
          amountMinorUnits: 350,
          fractionalDigitsEntered: 1,
          isFractionalMode: true,
        ),
        (
          amountMinorUnits: 1050,
          fractionalDigitsEntered: 1,
          isFractionalMode: true,
        ),
        (
          amountMinorUnits: 1100,
          fractionalDigitsEntered: 0,
          isFractionalMode: false,
        ),
        (
          amountMinorUnits: 300,
          fractionalDigitsEntered: 0,
          isFractionalMode: false,
        ),
      ]);
      expect(
        encodeAmountFormula(
          operands: parsed.operands,
          operators: parsed.operators,
          decimals: 2,
        ),
        '3.5+10.5+11+3',
      );
    });

    test('parses every operator', () {
      final parsed = parseAmountFormula('(8-2)*3/4', decimals: 0)!;
      expect(parsed.operators, const [
        CalcOperator.subtract,
        CalcOperator.multiply,
        CalcOperator.divide,
      ]);
      expect(parsed.operands.map((o) => o.amountMinorUnits), [8, 2, 3, 4]);
    });

    test('returns null for malformed or out-of-range input', () {
      for (final bad in [
        '',
        '12',
        '1+',
        '+1',
        '1++2',
        '1 + 2',
        '1,5+2',
        '1.+2',
        '.5+2',
        'abc',
        '1.234+1',
        '99999999999999999999+1',
      ]) {
        expect(parseAmountFormula(bad, decimals: 2), isNull, reason: bad);
      }
    });

    test('rejects a decimal point for zero-decimal currencies', () {
      expect(parseAmountFormula('1.5+2', decimals: 0), isNull);
    });
  });

  group('left-to-right brackets', () {
    const one = (
      amountMinorUnits: 100,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
    );
    String encode(List<CalcOperator> operators) => encodeAmountFormula(
      operands: List.filled(operators.length + 1, one),
      operators: operators,
      decimals: 2,
    );
    const add = CalcOperator.add;
    const sub = CalcOperator.subtract;
    const mul = CalcOperator.multiply;
    const div = CalcOperator.divide;

    test('bracket the sum before a product', () {
      expect(encode(const [add, mul]), '(1+1)*1');
      expect(encode(const [add, mul, add, div]), '((1+1)*1+1)/1');
      expect(encode(const [sub, div]), '(1-1)/1');
    });

    test('no brackets where usual precedence already agrees', () {
      expect(encode(const [mul, add]), '1*1+1');
      expect(encode(const [mul, div, mul]), '1*1/1*1');
      expect(encode(const [add, sub, add]), '1+1-1+1');
    });

    test('bracketed formulas parse back', () {
      for (final formula in ['(1+2)*2', '((1+2)*2+3)*4', '(9-3)/2+1']) {
        final parsed = parseAmountFormula(formula, decimals: 2)!;
        expect(
          encodeAmountFormula(
            operands: parsed.operands,
            operators: parsed.operators,
            decimals: 2,
          ),
          formula,
        );
      }
    });

    test('anything but the canonical form is rejected', () {
      for (final bad in [
        '1+2*2', // would read as 5 under usual precedence
        '1+(2*2)',
        '((1+2))*2',
        '(1+2*2',
        '1*2)',
        '()1+2',
        '3.50+1', // canonical form drops trailing zeros
        '03+1',
      ]) {
        expect(parseAmountFormula(bad, decimals: 2), isNull, reason: bad);
      }
    });
  });
}
