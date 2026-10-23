// Pure codec for the keypad formula stored in `transactions.amount_formula`.
//
// The stored form is canonical ASCII so it does not depend on the locale
// that wrote it: operands use `.` as the decimal separator and drop
// trailing fractional zeros ("3.5", not "3.50"; "3", not "3.00"), so an
// amount loaded at full precision reads the same as one typed short;
// operators are `+ - * /`; there are no spaces. Example: `3.5+10.5+11+3`.
//
// The keypad evaluates strictly left to right, so wherever × or ÷ follows
// + or −, the expression so far is bracketed: the keys `1 + 2 × 2` are
// stored as `(1+2)*2`, which any reader applying usual precedence also
// evaluates to 6. The same rendering drives the history line on screen.
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

/// Renders [operands] joined by [operators] left to right, bracketing the
/// expression so far wherever × or ÷ follows + or −. When [operators] is
/// as long as [operands], the text ends with that pending operator.
/// [operand] and [operator] render the parts and [separator] goes around
/// each operator, so storage and the history line share one rendering.
String renderFormula({
  required List<FormulaOperand> operands,
  required List<CalcOperator> operators,
  required String Function(FormulaOperand) operand,
  required String Function(CalcOperator) operator,
  String separator = '',
}) {
  assert(
    operators.length == operands.length ||
        operators.length == operands.length - 1,
  );
  var text = operand(operands.first);
  var hasUnbracketedAddition = false;
  for (var i = 0; i < operators.length; i++) {
    final op = operators[i];
    final isMultiplicative =
        op == CalcOperator.multiply || op == CalcOperator.divide;
    if (isMultiplicative && hasUnbracketedAddition) {
      text = '($text)';
      hasUnbracketedAddition = false;
    } else if (!isMultiplicative) {
      hasUnbracketedAddition = true;
    }
    text += '$separator${operator(op)}';
    if (i + 1 < operands.length) {
      text += '$separator${operand(operands[i + 1])}';
    }
  }
  return text;
}

/// The stored form of a complete formula
/// (`operators.length == operands.length - 1`).
String encodeAmountFormula({
  required List<FormulaOperand> operands,
  required List<CalcOperator> operators,
  required int decimals,
}) {
  assert(operators.length == operands.length - 1);
  return renderFormula(
    operands: operands,
    operators: operators,
    operand: (o) => encodeFormulaOperand(o, decimals: decimals),
    operator: (op) => _operatorChars[op]!,
  );
}

final _operandPattern = RegExp(r'^(\d+)(?:\.(\d+))?$');

/// Parses a stored formula for a currency with [decimals]. Returns null
/// when [formula] is malformed, has no operator, has more fractional digits
/// than the currency allows, overflows an int, or is not exactly what
/// [encodeAmountFormula] writes. The last check rejects brackets in any
/// other place (`1+(2*2)`) and unbracketed mixed operators (`1+2*2`), whose
/// meaning would differ from left-to-right evaluation.
ParsedFormula? parseAmountFormula(String formula, {required int decimals}) {
  // Brackets only ever restate left-to-right order, so parse without them
  // and let the canonical check below verify where they were.
  final flat = formula.replaceAll(RegExp(r'[()]'), '');
  final operands = <FormulaOperand>[];
  final operators = <CalcOperator>[];
  var start = 0;
  for (var i = 0; i <= flat.length; i++) {
    final op = i == flat.length ? null : _operatorFor(flat[i]);
    if (i < flat.length && op == null) continue;
    final operand = _parseOperand(flat.substring(start, i), decimals: decimals);
    if (operand == null) return null;
    operands.add(operand);
    if (op != null) operators.add(op);
    start = i + 1;
  }
  if (operators.isEmpty) return null;
  final canonical = encodeAmountFormula(
    operands: operands,
    operators: operators,
    decimals: decimals,
  );
  if (canonical != formula) return null;
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
