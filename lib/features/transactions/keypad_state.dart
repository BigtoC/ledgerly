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
      hasCurrentInput = false;

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
  /// Expression-aware backspace rules:
  /// - When [isEvaluating] is true but no right-operand digit has been
  ///   entered ([hasCurrentInput] is false), cancels the expression and
  ///   restores [leftOperand] as the plain current value.
  /// - When [isEvaluating] is true and a right-operand digit has been
  ///   entered, removes the last digit while preserving the expression
  ///   (leftOperand + operator). [hasCurrentInput] is set to false if
  ///   the right operand returns to 0.
  KeypadState pop({required int decimals}) {
    if (showingResult) {
      // Convert the displayed result to a plain editable state, then backspace it.
      final plain = KeypadState(
        amountMinorUnits: amountMinorUnits,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        hasCurrentInput: amountMinorUnits != 0,
      );
      return plain.pop(decimals: decimals);
    }

    // If evaluating with no right operand started, cancel the expression.
    if (isEvaluating && !hasCurrentInput) {
      return KeypadState(
        amountMinorUnits: leftOperand ?? 0,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        hasCurrentInput: (leftOperand ?? 0) != 0,
      );
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
  /// - Already evaluating with right input: evaluates left OP right, stores
  ///   result and enters the next pending operation (or shows the result if
  ///   the same operator was tapped again).
  /// - After a result is showing: use the result as the new left operand and
  ///   enter evaluating mode with the new operator.
  KeypadState pushOperator(CalcOperator op, {required int decimals}) {
    if (!hasCurrentInput && !showingResult && !hasExpression) {
      return this;
    }

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
        );
      }

      final right = amountMinorUnits;
      final result = _evaluate(
        leftOperand: leftOperand!,
        rightOperand: right,
        operator: operator!,
        decimals: decimals,
      );

      if (op == operator) {
        return KeypadState(
          amountMinorUnits: result,
          fractionalDigitsEntered: 0,
          isFractionalMode: false,
          leftOperand: leftOperand,
          operator: operator,
          isEvaluating: false,
          showingResult: true,
          rightOperand: right,
          hasCurrentInput: false,
        );
      }

      return KeypadState(
        amountMinorUnits: 0,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        leftOperand: result,
        operator: op,
        isEvaluating: true,
        showingResult: false,
        rightOperand: null,
        hasCurrentInput: false,
      );
    }

    if (showingResult) {
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
      );
    }

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
        other.hasCurrentInput == hasCurrentInput;
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
      'hasCurrentInput: $hasCurrentInput)';
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
