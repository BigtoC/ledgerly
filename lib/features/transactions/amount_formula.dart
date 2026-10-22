// Pure codec for the keypad formula stored in `transactions.amount_formula`.
//
// The stored form is canonical ASCII so it does not depend on the locale
// that wrote it: operands use `.` as the decimal separator and drop
// trailing fractional zeros ("3.5", not "3.50"; "3", not "3.00"), so an
// amount loaded at full precision reads the same as one typed short;
// operators are `+ - * /`; there are no spaces. Example: `3.5+10.5+11+3`.
//
// A formula always has at least one operator. A plain amount is stored as
// a null formula, never as a single operand.

import 'keypad_state.dart';

/// One operand as the user typed it, in the active currency's minor units.
/// The fields mirror `KeypadState`'s current-operand fields.
typedef FormulaOperand = ({
  int amountMinorUnits,
  int fractionalDigitsEntered,
  bool isFractionalMode,
});

/// Operands and the operators between them;
/// `operators.length == operands.length - 1`.
typedef ParsedFormula = ({
  List<FormulaOperand> operands,
  List<CalcOperator> operators,
});

const _operatorChars = {
  CalcOperator.add: '+',
  CalcOperator.subtract: '-',
  CalcOperator.multiply: '*',
  CalcOperator.divide: '/',
};

/// Renders [operand] with the fractional digits the user typed, minus
/// trailing zeros. A dangling decimal point ("3.") is dropped.
String encodeFormulaOperand(FormulaOperand operand, {required int decimals}) {
  final unit = _pow10(decimals);
  final whole = operand.amountMinorUnits ~/ unit;
  final digits = operand.fractionalDigitsEntered;
  if (!operand.isFractionalMode || digits == 0 || decimals == 0) {
    return '$whole';
  }
  final fraction = (operand.amountMinorUnits % unit)
      .toString()
      .padLeft(decimals, '0')
      .substring(0, digits)
      .replaceFirst(RegExp(r'0+$'), '');
  return fraction.isEmpty ? '$whole' : '$whole.$fraction';
}

String encodeAmountFormula({
  required List<FormulaOperand> operands,
  required List<CalcOperator> operators,
  required int decimals,
}) {
  assert(operators.length == operands.length - 1);
  final buffer = StringBuffer(
    encodeFormulaOperand(operands.first, decimals: decimals),
  );
  for (var i = 0; i < operators.length; i++) {
    buffer
      ..write(_operatorChars[operators[i]])
      ..write(encodeFormulaOperand(operands[i + 1], decimals: decimals));
  }
  return buffer.toString();
}

final _operandPattern = RegExp(r'^(\d+)(?:\.(\d+))?$');

/// Parses a stored formula for a currency with [decimals]. Returns null
/// when [formula] is malformed, has no operator, has more fractional digits
/// than the currency allows, or overflows an int.
ParsedFormula? parseAmountFormula(String formula, {required int decimals}) {
  final operands = <FormulaOperand>[];
  final operators = <CalcOperator>[];
  var start = 0;
  for (var i = 0; i <= formula.length; i++) {
    final op = i == formula.length ? null : _operatorFor(formula[i]);
    if (i < formula.length && op == null) continue;
    final operand = _parseOperand(
      formula.substring(start, i),
      decimals: decimals,
    );
    if (operand == null) return null;
    operands.add(operand);
    if (op != null) operators.add(op);
    start = i + 1;
  }
  if (operators.isEmpty) return null;
  return (operands: operands, operators: operators);
}

CalcOperator? _operatorFor(String char) {
  for (final MapEntry(:key, :value) in _operatorChars.entries) {
    if (value == char) return key;
  }
  return null;
}

FormulaOperand? _parseOperand(String text, {required int decimals}) {
  final match = _operandPattern.firstMatch(text);
  if (match == null) return null;
  final fraction = match.group(2) ?? '';
  if (fraction.length > decimals) return null;
  final unit = BigInt.from(_pow10(decimals));
  final minorUnits =
      BigInt.parse(match.group(1)!) * unit +
      (fraction.isEmpty
          ? BigInt.zero
          : BigInt.parse(fraction.padRight(decimals, '0')));
  if (!minorUnits.isValidInt) return null;
  return (
    amountMinorUnits: minorUnits.toInt(),
    fractionalDigitsEntered: fraction.length,
    isFractionalMode: fraction.isNotEmpty,
  );
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}
