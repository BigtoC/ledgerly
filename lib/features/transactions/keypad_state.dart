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
/// - [amountMinorUnits] is the amount in the active currency's minor units
///   (cents for USD, yen for JPY, wei for ETH). Always non-negative; the
///   form has no negation key.
/// - [fractionalDigitsEntered] is how many digits the user has typed
///   *after* the decimal separator. 0 either means "no decimal pressed
///   yet" (when [isFractionalMode] is false) or "decimal pressed but no
///   fractional digits typed yet" (when [isFractionalMode] is true).
/// - [isFractionalMode] flips to true once `pushDecimal` accepts a press;
///   it stays true until `pop` walks back past the decimal or `clear` is
///   called.
/// - [leftOperand] holds the left-hand side of an in-progress expression.
/// - [operator] holds the pending arithmetic operator.
/// - [isEvaluating] is true while the user is entering the right operand.
/// - [showingResult] is true immediately after `=` is pressed.
/// - [rightOperand] holds the right-hand side of an in-progress expression.
/// - [hasCurrentInput] is true when the user has typed at least one digit
///   into the current operand slot.
/// - [formulaOperands] / [formulaOperators] record the expression as typed
///   so it can be stored and reloaded (see `amount_formula.dart`). While
///   evaluating they hold the operands before the current one, each
///   followed by its operator; while showing a result they hold the whole
///   expression. Both are empty otherwise.
class KeypadState {
  const KeypadState({
    required this.amountMinorUnits,
    required this.fractionalDigitsEntered,
    required this.isFractionalMode,
    this.leftOperand,
    this.operator,
    this.isEvaluating = false,
    this.showingResult = false,
    this.rightOperand,
    this.hasCurrentInput = false,
    this.formulaOperands = const [],
    this.formulaOperators = const [],
  });

  /// Empty state — used as the keypad's starting point and by `clear`.
  const KeypadState.initial()
    : amountMinorUnits = 0,
      fractionalDigitsEntered = 0,
      isFractionalMode = false,
      leftOperand = null,
      operator = null,
      isEvaluating = false,
      showingResult = false,
      rightOperand = null,
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
        amountMinorUnits % _pow10(decimals) == 0) {
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
  }) {
    final operands = formula.operands;
    final operators = formula.operators;
    assert(operators.isNotEmpty && operators.length == operands.length - 1);
    final left = _fold(
      operands.sublist(0, operands.length - 1),
      operators.sublist(0, operators.length - 1),
      decimals: decimals,
    );
    final right = operands.last.amountMinorUnits;
    return KeypadState(
      amountMinorUnits: _evaluate(
        leftOperand: left,
        rightOperand: right,
        operator: operators.last,
        decimals: decimals,
      ),
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: left,
      operator: operators.last,
      showingResult: true,
      rightOperand: right,
      formulaOperands: List.unmodifiable(operands),
      formulaOperators: List.unmodifiable(operators),
    );
  }

  final int amountMinorUnits;
  final int fractionalDigitsEntered;
  final bool isFractionalMode;

  /// The left-hand side of an in-progress expression (in minor units), or
  /// null when no expression has been started.
  final int? leftOperand;

  /// The pending arithmetic operator, or null when none has been pressed.
  final CalcOperator? operator;

  /// True while the user is entering the right operand of an expression.
  final bool isEvaluating;

  /// True immediately after `=` is pressed (result is on display).
  final bool showingResult;

  /// The right-hand side of an in-progress expression (in minor units), or
  /// null when the user has not yet started entering it.
  final int? rightOperand;

  /// True when the user has typed at least one digit into the current
  /// operand slot (used to distinguish "0 entered" from "nothing entered").
  final bool hasCurrentInput;

  final List<FormulaOperand> formulaOperands;
  final List<CalcOperator> formulaOperators;

  // ---------------------------------------------------------------------------
  // Derived getters
  // ---------------------------------------------------------------------------

  /// True when any part of a calculator expression is in progress or
  /// complete (left operand set, operator pressed, evaluating, or result
  /// showing).
  bool get hasExpression =>
      leftOperand != null ||
      operator != null ||
      isEvaluating ||
      showingResult ||
      rightOperand != null;

  /// True when there is either a calculator expression or user-typed input
  /// to display.
  bool get hasVisibleInput => hasExpression || hasCurrentInput;

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
    final List<FormulaOperand> operands;
    final List<CalcOperator> operators;
    if (isEvaluating && hasCurrentInput) {
      operands = [...formulaOperands, _currentOperand];
      operators = formulaOperators;
    } else if (isEvaluating && formulaOperators.isNotEmpty) {
      operands = formulaOperands;
      operators = formulaOperators.sublist(0, formulaOperators.length - 1);
    } else if (showingResult) {
      operands = formulaOperands;
      operators = formulaOperators;
    } else {
      return null;
    }
    if (operators.isEmpty || operands.length != operators.length + 1) {
      return null;
    }
    return encodeAmountFormula(
      operands: operands,
      operators: operators,
      decimals: decimals,
    );
  }

  /// Makes the last of [operands] the operand being typed again, with the
  /// rest of the expression ([operators] has one fewer entry) committed
  /// before it.
  static KeypadState _reopen(
    List<FormulaOperand> operands,
    List<CalcOperator> operators, {
    required int decimals,
  }) {
    final current = operands.last;
    final committed = operands.sublist(0, operands.length - 1);
    if (committed.isEmpty) {
      return KeypadState(
        amountMinorUnits: current.amountMinorUnits,
        fractionalDigitsEntered: current.fractionalDigitsEntered,
        isFractionalMode: current.isFractionalMode,
        hasCurrentInput: true,
      );
    }
    return KeypadState(
      amountMinorUnits: current.amountMinorUnits,
      fractionalDigitsEntered: current.fractionalDigitsEntered,
      isFractionalMode: current.isFractionalMode,
      leftOperand: _fold(
        committed,
        operators.sublist(0, operators.length - 1),
        decimals: decimals,
      ),
      operator: operators.last,
      isEvaluating: true,
      hasCurrentInput: true,
      formulaOperands: committed,
      formulaOperators: operators,
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
        amountMinorUnits: digit * _pow10(decimals),
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
      final addend = digit * _pow10(exponent);
      return _withCurrentOperand(
        amountMinorUnits: amountMinorUnits + addend,
        fractionalDigitsEntered: fractionalDigitsEntered + 1,
        isFractionalMode: true,
        hasCurrentInput: true,
      );
    }
    final shifted = amountMinorUnits * 10 + digit * _pow10(decimals);
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
      return const KeypadState(
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
  /// Expression-aware backspace rules:
  /// - When [isEvaluating] is true but no right-operand digit has been
  ///   entered ([hasCurrentInput] is false), cancels the expression and
  ///   restores [leftOperand] as the plain current value.
  /// - When [isEvaluating] is true and a right-operand digit has been
  ///   entered, removes the last digit while preserving the expression
  ///   (leftOperand + operator). [hasCurrentInput] is set to false if
  ///   the right operand returns to 0.
  /// - When a formula is recorded, backspace on a result or on a dangling
  ///   operator reopens the previous operand for editing instead.
  KeypadState pop({required int decimals}) {
    if (showingResult &&
        formulaOperators.isNotEmpty &&
        formulaOperands.length == formulaOperators.length + 1) {
      return _reopen(
        formulaOperands,
        formulaOperators,
        decimals: decimals,
      ).pop(decimals: decimals);
    }

    if (isEvaluating &&
        !hasCurrentInput &&
        formulaOperands.isNotEmpty &&
        formulaOperands.length == formulaOperators.length) {
      return _reopen(
        formulaOperands,
        formulaOperators.sublist(0, formulaOperators.length - 1),
        decimals: decimals,
      );
    }

    if (showingResult) {
      // Convert the displayed result to a plain editable state, then
      // backspace it. `fromAmount` keeps a fractional result in fractional
      // mode, so 3.50 walks back to 3.5 rather than losing its fraction.
      return KeypadState.fromAmount(
        amountMinorUnits,
        decimals: decimals,
      ).pop(decimals: decimals);
    }

    // If evaluating with no right operand started, cancel the expression.
    // `fromAmount` keeps a fractional subtotal (e.g. 3.50 from 1.5 + 2 +)
    // visible as typed instead of truncating the display to "3".
    if (isEvaluating && !hasCurrentInput) {
      return KeypadState.fromAmount(leftOperand ?? 0, decimals: decimals);
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
      final divisor = _pow10(decimals - fractionalDigitsEntered + 1);
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

    final unit = _pow10(decimals);
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

  /// Returns a copy that updates the current operand fields while preserving
  /// any active expression (leftOperand + operator + isEvaluating), and
  /// always clears showingResult and rightOperand.
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
      leftOperand: isEvaluating ? leftOperand : null,
      operator: isEvaluating ? operator : null,
      isEvaluating: isEvaluating,
      showingResult: false,
      rightOperand: null,
      hasCurrentInput: hasCurrentInput,
      formulaOperands: isEvaluating ? formulaOperands : const [],
      formulaOperators: isEvaluating ? formulaOperators : const [],
    );
  }

  /// Apply a [CalcOperator].
  ///
  /// Behaviour:
  /// - Untouched keypad (no input, no expression): no-op.
  /// - First operator press (no expression yet): saves current amount as the
  ///   left operand, stores the operator, resets the display to 0, and enters
  ///   evaluating mode.
  /// - Already evaluating, no right input yet: replaces the pending operator
  ///   (unless it is the same operator — then a no-op).
  /// - Already evaluating with right input: evaluates left OP right and
  ///   chains — the result becomes the left operand of the next pending
  ///   operation, so `1 + 2 + 4` evaluates strictly left to right to 7.
  /// - After a result is showing: use the result as the new left operand and
  ///   enter evaluating mode with the new operator.
  KeypadState pushOperator(CalcOperator op, {required int decimals}) {
    if (!hasVisibleInput) return this;

    if (isEvaluating && operator != null && leftOperand != null) {
      if (!hasCurrentInput) {
        if (op == operator) return this;
        return KeypadState(
          amountMinorUnits: 0,
          fractionalDigitsEntered: 0,
          isFractionalMode: false,
          leftOperand: leftOperand,
          operator: op,
          isEvaluating: true,
          showingResult: false,
          rightOperand: null,
          hasCurrentInput: false,
          formulaOperands: formulaOperands,
          formulaOperators: formulaOperators.isEmpty
              ? const []
              : [
                  ...formulaOperators.sublist(0, formulaOperators.length - 1),
                  op,
                ],
        );
      }

      return KeypadState(
        amountMinorUnits: 0,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        leftOperand: _evaluate(
          leftOperand: leftOperand!,
          rightOperand: amountMinorUnits,
          operator: operator!,
          decimals: decimals,
        ),
        operator: op,
        isEvaluating: true,
        showingResult: false,
        rightOperand: null,
        hasCurrentInput: false,
        formulaOperands: [...formulaOperands, _currentOperand],
        formulaOperators: [...formulaOperators, op],
      );
    }

    // After a result, the formula behind it (if any) continues; a result
    // without one becomes the first operand.
    final continuesFormula = showingResult && formulaOperators.isNotEmpty;
    final firstOperand = showingResult
        ? KeypadState.fromAmount(amountMinorUnits, decimals: decimals)
        : this;
    return KeypadState(
      amountMinorUnits: 0,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: amountMinorUnits,
      operator: op,
      isEvaluating: true,
      showingResult: false,
      rightOperand: null,
      hasCurrentInput: false,
      formulaOperands: continuesFormula
          ? formulaOperands
          : [firstOperand._currentOperand],
      formulaOperators: continuesFormula ? [...formulaOperators, op] : [op],
    );
  }

  /// The `=` key. Finishes a pending expression and shows its result:
  ///
  /// - Evaluating with right input: evaluates left OP right and shows the
  ///   result with the full expression kept for the history line.
  /// - Evaluating with no right input yet (`1 +`): drops the dangling
  ///   operator and shows the left operand as the result.
  /// - No pending expression: no-op.
  ///
  /// Typing an operator afterwards keeps calculating from the result;
  /// typing a digit starts a fresh amount.
  KeypadState equals({required int decimals}) {
    if (!isEvaluating || leftOperand == null || operator == null) return this;

    if (!hasCurrentInput) {
      final operators = formulaOperators.isEmpty
          ? const <CalcOperator>[]
          : formulaOperators.sublist(0, formulaOperators.length - 1);
      return KeypadState(
        amountMinorUnits: leftOperand!,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        showingResult: true,
        formulaOperands: operators.isEmpty ? const [] : formulaOperands,
        formulaOperators: operators,
      );
    }

    return KeypadState(
      amountMinorUnits: _evaluate(
        leftOperand: leftOperand!,
        rightOperand: amountMinorUnits,
        operator: operator!,
        decimals: decimals,
      ),
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: leftOperand,
      operator: operator,
      isEvaluating: false,
      showingResult: true,
      rightOperand: amountMinorUnits,
      hasCurrentInput: false,
      formulaOperands: [...formulaOperands, _currentOperand],
      formulaOperators: formulaOperators,
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
        other.leftOperand == leftOperand &&
        other.operator == operator &&
        other.isEvaluating == isEvaluating &&
        other.showingResult == showingResult &&
        other.rightOperand == rightOperand &&
        other.hasCurrentInput == hasCurrentInput &&
        _listEquals(other.formulaOperands, formulaOperands) &&
        _listEquals(other.formulaOperators, formulaOperators);
  }

  @override
  int get hashCode => Object.hash(
    amountMinorUnits,
    fractionalDigitsEntered,
    isFractionalMode,
    leftOperand,
    operator,
    isEvaluating,
    showingResult,
    rightOperand,
    hasCurrentInput,
    Object.hashAll(formulaOperands),
    Object.hashAll(formulaOperators),
  );

  @override
  String toString() =>
      'KeypadState(amountMinorUnits: $amountMinorUnits, '
      'fractionalDigitsEntered: $fractionalDigitsEntered, '
      'isFractionalMode: $isFractionalMode, '
      'leftOperand: $leftOperand, '
      'operator: $operator, '
      'isEvaluating: $isEvaluating, '
      'showingResult: $showingResult, '
      'rightOperand: $rightOperand, '
      'hasCurrentInput: $hasCurrentInput, '
      'formulaOperands: $formulaOperands, '
      'formulaOperators: $formulaOperators)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Evaluates [operands] joined by [operators] strictly left to right, the
/// same way chained operator presses do.
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

int _pow10(int exponent) {
  assert(exponent >= 0);
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

/// Evaluate [leftOperand] [operator] [rightOperand] in integer minor-unit
/// arithmetic. Multiplication and division use [BigInt] to avoid overflow and
/// apply half-up rounding at the [decimals] boundary. Subtraction underflow is
/// clamped to zero (expenses can never be negative).
int _evaluate({
  required int leftOperand,
  required int rightOperand,
  required CalcOperator operator,
  required int decimals,
}) {
  final unit = BigInt.from(_pow10(decimals));
  return switch (operator) {
    CalcOperator.add => leftOperand + rightOperand,
    CalcOperator.subtract => (leftOperand - rightOperand).clamp(0, leftOperand),
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

/// Integer division with half-up rounding: ⌊(numerator + denominator/2) /
/// denominator⌋. Both arguments must be non-negative.
///
/// Clamps to [double.maxFinite] cast as int if the result overflows Dart's
/// native int range (relevant for high-decimal currencies such as ETH).
int _roundHalfUp(BigInt numerator, BigInt denominator) {
  final adjusted = numerator + (denominator ~/ BigInt.from(2));
  final result = adjusted ~/ denominator;
  // BigInt.isValidInt is true iff result fits in a Dart native int (63-bit
  // on 64-bit platforms, 32-bit on 32-bit platforms).
  return result.isValidInt
      ? result.toInt()
      : result.isNegative
      ? 0
      : double.maxFinite.toInt();
}
