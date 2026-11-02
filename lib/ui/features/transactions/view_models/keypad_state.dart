// Pure helper for the calculator-keypad state machine (Wave 2 §8).
//
// `KeypadState` is currency-aware integer arithmetic with no Flutter,
// Riverpod, or Drift bindings — every method takes the active currency's
// `decimals` so the same value type can drive USD (decimals=2), JPY
// (decimals=0), and ETH (decimals=18) keypads. Tests live in
// `test/unit/utils/keypad_decimal_math_test.dart`.
//
// The amount is stored canonically in minor units (`amountMinorUnits`).
// The display layer recovers a "1.05" string by dividing by 10^decimals
// and zero-padding the fractional part to `fractionalDigitsEntered`
// characters.

import 'amount_formula.dart';

/// The four arithmetic operators supported by the calculator keypad.
enum CalcOperator { add, subtract, multiply, divide }

/// Immutable state for the calculator keypad.
///
/// - [amountMinorUnits] is the operand being typed, or the result while
///   [showingResult], in the active currency's minor units (cents for USD,
///   yen for JPY, wei for ETH). Always non-negative; the form has no
///   negation key.
/// - [fractionalDigitsEntered] is how many digits the user has typed
///   *after* the decimal separator. 0 either means "no decimal pressed
///   yet" (when [isFractionalMode] is false) or "decimal pressed but no
///   fractional digits typed yet" (when [isFractionalMode] is true).
/// - [isFractionalMode] flips to true once `pushDecimal` accepts a press;
///   it stays true until `pop` walks back past the decimal or `clear` is
///   called.
/// - [isEvaluating] is true while the user is entering the operand after
///   an operator.
/// - [showingResult] is true immediately after `=` is pressed.
/// - [hasCurrentInput] is true when the user has typed at least one digit
///   into the current operand slot.
/// - [formulaOperands] / [formulaOperators] are the only record of the
///   expression, as typed, so it can be stored and reloaded (see
///   `amount_formula.dart`). While evaluating they hold the operands before
///   the current one, each followed by its operator. While showing a result
///   they hold the whole expression, or are both empty when the result has
///   no formula (`1 + =`). Both are empty otherwise. The running total,
///   pending operator and last operand are all derived from them.
class KeypadState {
  KeypadState({
    required this.amountMinorUnits,
    required this.fractionalDigitsEntered,
    required this.isFractionalMode,
    this.isEvaluating = false,
    this.showingResult = false,
    this.hasCurrentInput = false,
    this.formulaOperands = const [],
    this.formulaOperators = const [],
  }) : assert(
         isEvaluating
             ? !showingResult &&
                   formulaOperators.isNotEmpty &&
                   formulaOperands.length == formulaOperators.length
             : showingResult && formulaOperators.isNotEmpty
             ? formulaOperands.length == formulaOperators.length + 1
             : formulaOperands.isEmpty && formulaOperators.isEmpty,
         'formula lists do not match the keypad mode',
       );

  /// Empty state — used as the keypad's starting point and by `clear`.
  const KeypadState.initial()
    : amountMinorUnits = 0,
      fractionalDigitsEntered = 0,
      isFractionalMode = false,
      isEvaluating = false,
      showingResult = false,
      hasCurrentInput = false,
      formulaOperands = const [],
      formulaOperators = const [];

  /// Reconstructs a keypad from a stored amount so backspace on a
  /// hydrated edit/duplicate value walks back through the visible digits
  /// rather than dropping the whole amount in one press. Sets
  /// `hasCurrentInput: true` for non-zero amounts so edit/duplicate flows
  /// can immediately start operator expressions from the existing value.
  factory KeypadState.fromAmount(
    int amountMinorUnits, {
    required int decimals,
  }) {
    // If the amount has no fractional part, treat it as integer-mode
    // entry. Otherwise enter fractional mode and assume the user has
    // typed all `decimals` digits — backspace will walk them back.
    if (amountMinorUnits == 0 ||
        decimals <= 0 ||
        amountMinorUnits % pow10(decimals) == 0) {
      return KeypadState(
        amountMinorUnits: amountMinorUnits,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        hasCurrentInput: amountMinorUnits != 0,
      );
    }
    return KeypadState(
      amountMinorUnits: amountMinorUnits,
      fractionalDigitsEntered: decimals,
      isFractionalMode: true,
      hasCurrentInput: true,
    );
  }

  /// Rebuilds the keypad from a stored formula as if the user had typed it
  /// and pressed `=`: the result is recalculated left to right with the
  /// same arithmetic as the keys, and backspace walks back into it.
  factory KeypadState.fromFormula(
    ParsedFormula formula, {
    required int decimals,
  }) => KeypadState(
    amountMinorUnits: _nonNegative(
      _fold(formula.operands, formula.operators, decimals: decimals),
    ),
    fractionalDigitsEntered: 0,
    isFractionalMode: false,
    showingResult: true,
    formulaOperands: List.unmodifiable(formula.operands),
    formulaOperators: List.unmodifiable(formula.operators),
  );

  final int amountMinorUnits;
  final int fractionalDigitsEntered;
  final bool isFractionalMode;

  /// True while the user is entering the operand after an operator.
  final bool isEvaluating;

  /// True immediately after `=` is pressed (result is on display).
  final bool showingResult;

  /// True when the user has typed at least one digit into the current
  /// operand slot (used to distinguish "0 entered" from "nothing entered").
  final bool hasCurrentInput;

  final List<FormulaOperand> formulaOperands;
  final List<CalcOperator> formulaOperators;

  // ---------------------------------------------------------------------------
  // Derived getters
  // ---------------------------------------------------------------------------

  /// True when a calculator expression is in progress or its result is
  /// showing.
  bool get hasExpression => isEvaluating || showingResult;

  /// True when there is either a calculator expression or user-typed input
  /// to display.
  bool get hasVisibleInput => hasExpression || hasCurrentInput;

  /// The pending operator while evaluating, or the last operator of the
  /// formula behind a result. Null otherwise.
  CalcOperator? get operator =>
      formulaOperators.isEmpty ? null : formulaOperators.last;

  /// The last operand of the formula behind a result, in minor units. Null
  /// otherwise.
  int? get rightOperand => showingResult && formulaOperators.isNotEmpty
      ? formulaOperands.last.amountMinorUnits
      : null;

  /// The running total that [operator] applies to: everything before the
  /// operand being typed while evaluating, or before the last operand of a
  /// result's formula. Null when there is no expression, or when a result
  /// has no formula behind it (`1 + =`). It may be negative;
  /// only the finished result is clamped.
  int? leftOperand({required int decimals}) {
    if (isEvaluating) {
      return _fold(
        formulaOperands,
        _withoutLast(formulaOperators),
        decimals: decimals,
      );
    }
    if (showingResult && formulaOperators.isNotEmpty) {
      return _fold(
        _withoutLast(formulaOperands),
        _withoutLast(formulaOperators),
        decimals: decimals,
      );
    }
    return null;
  }

  /// The current operand as typed.
  FormulaOperand get _currentOperand => (
    amountMinorUnits: amountMinorUnits,
    fractionalDigitsEntered: fractionalDigitsEntered,
    isFractionalMode: isFractionalMode,
  );

  /// The expression that produces the amount `=` would show, in the stored
  /// formula format (e.g. `3.5+10.5+11+3`). A dangling operator is left
  /// out. Null when there is no operator to record.
  String? formula({required int decimals}) {
    final finished = _finishedFormula;
    if (finished == null) return null;
    return encodeAmountFormula(
      operands: finished.operands,
      operators: finished.operators,
      decimals: decimals,
    );
  }

  /// The whole expression as `=` would finish it, or null when it has no
  /// operator.
  ParsedFormula? get _finishedFormula {
    final List<FormulaOperand> operands;
    final List<CalcOperator> operators;
    if (isEvaluating && hasCurrentInput) {
      operands = [...formulaOperands, _currentOperand];
      operators = formulaOperators;
    } else if (isEvaluating) {
      operands = formulaOperands;
      operators = _withoutLast(formulaOperators);
    } else {
      operands = formulaOperands;
      operators = formulaOperators;
    }
    if (operators.isEmpty) return null;
    return (operands: operands, operators: operators);
  }

  /// Makes the last of [operands] the operand being typed again, with the
  /// rest of the expression ([operators] has one fewer entry) committed
  /// before it.
  static KeypadState _reopen(
    List<FormulaOperand> operands,
    List<CalcOperator> operators,
  ) {
    final current = operands.last;
    final committed = _withoutLast(operands);
    return KeypadState(
      amountMinorUnits: current.amountMinorUnits,
      fractionalDigitsEntered: current.fractionalDigitsEntered,
      isFractionalMode: current.isFractionalMode,
      isEvaluating: committed.isNotEmpty,
      hasCurrentInput: true,
      formulaOperands: committed,
      formulaOperators: committed.isEmpty ? const [] : operators,
    );
  }

  // ---------------------------------------------------------------------------
  // Mutators
  // ---------------------------------------------------------------------------

  /// Append a digit (0..9). Behavior depends on [isFractionalMode]:
  ///
  /// - Integer mode: shifts the value left by one decimal-place and adds
  ///   `digit * 10^decimals` so the canonical minor-unit invariant holds.
  /// - Fractional mode: clamps once `fractionalDigitsEntered == decimals`
  ///   (Wave 2 risk #1 — silently drops further digits per the keypad
  ///   contract).
  ///
  /// When [showingResult] is true, typing a new digit clears the old
  /// expression and starts a fresh operand.
  KeypadState push(int digit, {required int decimals}) {
    assert(digit >= 0 && digit <= 9, 'digit out of range: $digit');

    if (showingResult) {
      // Typing after a result clears the expression and starts fresh.
      return KeypadState(
        amountMinorUnits: digit * pow10(decimals),
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        hasCurrentInput: true,
      );
    }

    if (isFractionalMode) {
      if (fractionalDigitsEntered >= decimals) {
        return this;
      }
      final exponent = decimals - fractionalDigitsEntered - 1;
      final addend = digit * pow10(exponent);
      return _withCurrentOperand(
        amountMinorUnits: amountMinorUnits + addend,
        fractionalDigitsEntered: fractionalDigitsEntered + 1,
        isFractionalMode: true,
        hasCurrentInput: true,
      );
    }
    final shifted = amountMinorUnits * 10 + digit * pow10(decimals);
    return _withCurrentOperand(
      amountMinorUnits: shifted,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      hasCurrentInput: true,
    );
  }

  /// Enter fractional mode. No-op when the active currency has zero
  /// decimals (the keypad widget greys the key out, but the helper must
  /// also reject so a mistaken caller cannot toggle the flag).
  /// Idempotent — pressing `.` while already in fractional mode does
  /// nothing.
  ///
  /// When [showingResult] is true, pressing `.` clears the old expression
  /// and starts a fresh fractional operand.
  KeypadState pushDecimal({required int decimals}) {
    if (decimals == 0) return this;
    if (isFractionalMode) return this;
    if (showingResult) {
      // Decimal after a result clears the expression and starts fresh.
      return KeypadState(
        amountMinorUnits: 0,
        fractionalDigitsEntered: 0,
        isFractionalMode: true,
        hasCurrentInput: true,
      );
    }
    return _withCurrentOperand(
      amountMinorUnits: amountMinorUnits,
      fractionalDigitsEntered: 0,
      isFractionalMode: true,
      hasCurrentInput: true,
    );
  }

  /// Backspace. In fractional mode, drops the last fractional digit; if
  /// no fractional digits remain, exits fractional mode. In integer mode,
  /// drops the last integer digit (e.g. "12" → "1" → "0"). No-op on the
  /// empty initial state.
  ///
  /// Expression-aware backspace walks back through the formula:
  /// - On a result with a formula, reopens the last operand and drops its
  ///   last digit. A result without one becomes a plain amount instead.
  /// - While evaluating with no digit typed after the operator, removes the
  ///   operator and reopens the previous operand for editing.
  /// - While evaluating with a digit typed, edits that operand and keeps the
  ///   expression. [hasCurrentInput] turns false once it is back to 0.
  KeypadState pop({required int decimals}) {
    if (showingResult) {
      if (formulaOperators.isNotEmpty) {
        return _reopen(
          formulaOperands,
          formulaOperators,
        ).pop(decimals: decimals);
      }
      // `fromAmount` keeps a fractional result in fractional mode, so 3.50
      // walks back to 3.5 rather than losing its fraction.
      return KeypadState.fromAmount(
        amountMinorUnits,
        decimals: decimals,
      ).pop(decimals: decimals);
    }

    if (isEvaluating && !hasCurrentInput) {
      return _reopen(formulaOperands, _withoutLast(formulaOperators));
    }

    if (isFractionalMode) {
      if (fractionalDigitsEntered == 0) {
        // Exit fractional mode; preserve expression if active.
        return _withCurrentOperand(
          amountMinorUnits: amountMinorUnits,
          fractionalDigitsEntered: 0,
          isFractionalMode: false,
          hasCurrentInput: amountMinorUnits != 0,
        );
      }
      // Round amountMinorUnits down to the divisor that strips the last
      // fractional digit. For decimals=2 with one digit entered, divisor
      // is 10^(2-1+1) = 100 → 150 → 100 (drops the "5" of "1.5").
      final divisor = pow10(decimals - fractionalDigitsEntered + 1);
      final reduced = (amountMinorUnits ~/ divisor) * divisor;
      return _withCurrentOperand(
        amountMinorUnits: reduced,
        fractionalDigitsEntered: fractionalDigitsEntered - 1,
        isFractionalMode: true,
        hasCurrentInput: true, // still in fractional mode = user touched this
      );
    }

    if (amountMinorUnits == 0) {
      if (!isEvaluating) return this; // plain empty state — no-op
      // In expression with amount already 0 (e.g. explicit zero was pushed
      // then backspaced): stay at 0 with hasCurrentInput = false.
      return _withCurrentOperand(
        amountMinorUnits: 0,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        hasCurrentInput: false,
      );
    }

    final unit = pow10(decimals);
    final integerPart = amountMinorUnits ~/ unit;
    final reducedInteger = integerPart ~/ 10;
    final newAmount = reducedInteger * unit;
    return _withCurrentOperand(
      amountMinorUnits: newAmount,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      hasCurrentInput: newAmount != 0,
    );
  }

  /// Returns a copy that updates the current operand fields while keeping
  /// any expression in progress, and always leaves the result state.
  KeypadState _withCurrentOperand({
    required int amountMinorUnits,
    required int fractionalDigitsEntered,
    required bool isFractionalMode,
    required bool hasCurrentInput,
  }) {
    return KeypadState(
      amountMinorUnits: amountMinorUnits,
      fractionalDigitsEntered: fractionalDigitsEntered,
      isFractionalMode: isFractionalMode,
      isEvaluating: isEvaluating,
      hasCurrentInput: hasCurrentInput,
      formulaOperands: isEvaluating ? formulaOperands : const [],
      formulaOperators: isEvaluating ? formulaOperators : const [],
    );
  }

  /// Apply a [CalcOperator].
  ///
  /// Behaviour:
  /// - Untouched keypad (no input, no expression): no-op.
  /// - First operator press (no expression yet): commits the current amount
  ///   as the first operand, records the operator, resets the display to 0,
  ///   and enters evaluating mode.
  /// - Already evaluating, no operand typed yet: replaces the pending
  ///   operator (unless it is the same operator — then a no-op).
  /// - Already evaluating with an operand typed: commits it and chains, so
  ///   `1 + 2 + 4` evaluates strictly left to right to 7.
  /// - After a result: continues the formula behind it, or starts a new one
  ///   from the result when it has none.
  KeypadState pushOperator(CalcOperator op, {required int decimals}) {
    if (!hasVisibleInput) return this;

    final List<FormulaOperand> operands;
    final List<CalcOperator> operators;
    if (isEvaluating && !hasCurrentInput) {
      if (op == formulaOperators.last) return this;
      operands = formulaOperands;
      operators = [..._withoutLast(formulaOperators), op];
    } else if (isEvaluating) {
      operands = [...formulaOperands, _currentOperand];
      operators = [...formulaOperators, op];
    } else if (showingResult && formulaOperators.isNotEmpty) {
      // Continuing the formula resumes its unclamped running total, so the
      // keys and the replayed formula agree even when the shown result was
      // clamped at zero.
      operands = formulaOperands;
      operators = [...formulaOperators, op];
    } else {
      final first = showingResult
          ? KeypadState.fromAmount(amountMinorUnits, decimals: decimals)
          : this;
      operands = [first._currentOperand];
      operators = [op];
    }
    return KeypadState(
      amountMinorUnits: 0,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      isEvaluating: true,
      formulaOperands: operands,
      formulaOperators: operators,
    );
  }

  /// The `=` key. Finishes a pending expression and shows its result:
  ///
  /// - Evaluating with an operand typed: shows the result of the whole
  ///   formula, kept for the history line.
  /// - Evaluating with no operand typed yet (`1 +`): drops the dangling
  ///   operator and shows the result of what is left. A single operand
  ///   leaves no formula.
  /// - No pending expression: no-op.
  ///
  /// The result is clamped to zero; the running total behind it is not.
  /// Typing an operator afterwards keeps calculating from the formula;
  /// typing a digit starts a fresh amount.
  KeypadState equals({required int decimals}) {
    if (!isEvaluating) return this;

    final operands = hasCurrentInput
        ? [...formulaOperands, _currentOperand]
        : formulaOperands;
    final operators = hasCurrentInput
        ? formulaOperators
        : _withoutLast(formulaOperators);
    final hasFormula = operators.isNotEmpty;
    return KeypadState(
      amountMinorUnits: _nonNegative(
        _fold(operands, operators, decimals: decimals),
      ),
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      showingResult: true,
      formulaOperands: hasFormula ? operands : const [],
      formulaOperators: operators,
    );
  }

  /// Reset to the initial empty state.
  KeypadState clear() => const KeypadState.initial();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KeypadState &&
        other.amountMinorUnits == amountMinorUnits &&
        other.fractionalDigitsEntered == fractionalDigitsEntered &&
        other.isFractionalMode == isFractionalMode &&
        other.isEvaluating == isEvaluating &&
        other.showingResult == showingResult &&
        other.hasCurrentInput == hasCurrentInput &&
        _listEquals(other.formulaOperands, formulaOperands) &&
        _listEquals(other.formulaOperators, formulaOperators);
  }

  @override
  int get hashCode => Object.hash(
    amountMinorUnits,
    fractionalDigitsEntered,
    isFractionalMode,
    isEvaluating,
    showingResult,
    hasCurrentInput,
    Object.hashAll(formulaOperands),
    Object.hashAll(formulaOperators),
  );

  @override
  String toString() =>
      'KeypadState(amountMinorUnits: $amountMinorUnits, '
      'fractionalDigitsEntered: $fractionalDigitsEntered, '
      'isFractionalMode: $isFractionalMode, '
      'isEvaluating: $isEvaluating, '
      'showingResult: $showingResult, '
      'hasCurrentInput: $hasCurrentInput, '
      'formulaOperands: $formulaOperands, '
      'formulaOperators: $formulaOperators)';
}

/// 10 to the power [exponent], for scaling between whole currency units
/// and minor units.
int pow10(int exponent) {
  assert(exponent >= 0);
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

List<T> _withoutLast<T>(List<T> list) =>
    list.isEmpty ? list : list.sublist(0, list.length - 1);

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Evaluates [operands] joined by [operators] strictly left to right, the
/// same way chained operator presses do. [operators] has one fewer entry.
int _fold(
  List<FormulaOperand> operands,
  List<CalcOperator> operators, {
  required int decimals,
}) {
  var result = operands.first.amountMinorUnits;
  for (var i = 0; i < operators.length; i++) {
    result = _evaluate(
      leftOperand: result,
      rightOperand: operands[i + 1].amountMinorUnits,
      operator: operators[i],
      decimals: decimals,
    );
  }
  return result;
}

/// Evaluate [leftOperand] [operator] [rightOperand] in integer minor-unit
/// arithmetic. Multiplication and division use [BigInt] to avoid overflow and
/// round half away from zero at the [decimals] boundary. A subtotal may go
/// negative (`5 - 10 + 20` is 15); only the finished result is clamped to
/// zero, by [_nonNegative], because amounts can never be negative.
int _evaluate({
  required int leftOperand,
  required int rightOperand,
  required CalcOperator operator,
  required int decimals,
}) {
  final unit = BigInt.from(pow10(decimals));
  return switch (operator) {
    CalcOperator.add => leftOperand + rightOperand,
    CalcOperator.subtract => leftOperand - rightOperand,
    CalcOperator.multiply => _roundHalfUp(
      BigInt.from(leftOperand) * BigInt.from(rightOperand),
      unit,
    ),
    CalcOperator.divide =>
      rightOperand == 0
          ? 0
          : _roundHalfUp(
              BigInt.from(leftOperand) * unit,
              BigInt.from(rightOperand),
            ),
  };
}

/// Integer division rounding half away from zero:
/// sign × ⌊(|numerator| + denominator/2) / denominator⌋. [denominator] must
/// be positive; [numerator] may be negative (a negative subtotal).
///
/// Clamps to ±[double.maxFinite] cast as int if the result overflows Dart's
/// native int range (relevant for high-decimal currencies such as ETH).
int _roundHalfUp(BigInt numerator, BigInt denominator) {
  final adjusted = numerator.abs() + (denominator ~/ BigInt.from(2));
  final magnitude = adjusted ~/ denominator;
  final result = numerator.isNegative ? -magnitude : magnitude;
  // BigInt.isValidInt is true iff result fits in a Dart native int (63-bit
  // on 64-bit platforms, 32-bit on 32-bit platforms).
  return result.isValidInt
      ? result.toInt()
      : result.isNegative
      ? -double.maxFinite.toInt()
      : double.maxFinite.toInt();
}

/// A finished calculation is an amount, which can never be negative.
int _nonNegative(int value) => value < 0 ? 0 : value;
