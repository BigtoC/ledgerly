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
class KeypadState {
  const KeypadState({
    required this.amountMinorUnits,
    required this.fractionalDigitsEntered,
    required this.isFractionalMode,
  });

  /// Empty state — used as the keypad's starting point and by `clear`.
  const KeypadState.initial()
    : amountMinorUnits = 0,
      fractionalDigitsEntered = 0,
      isFractionalMode = false;

  final int amountMinorUnits;
  final int fractionalDigitsEntered;
  final bool isFractionalMode;

  /// Append a digit (0..9). Behavior depends on [isFractionalMode]:
  ///
  /// - Integer mode: shifts the value left by one decimal-place and adds
  ///   `digit * 10^decimals` so the canonical minor-unit invariant holds.
  /// - Fractional mode: clamps once `fractionalDigitsEntered == decimals`
  ///   (Wave 2 risk #1 — silently drops further digits per the keypad
  ///   contract).
  KeypadState push(int digit, {required int decimals}) {
    assert(digit >= 0 && digit <= 9, 'digit out of range: $digit');
    if (isFractionalMode) {
      if (fractionalDigitsEntered >= decimals) {
        return this;
      }
      final exponent = decimals - fractionalDigitsEntered - 1;
      final addend = digit * _pow10(exponent);
      return KeypadState(
        amountMinorUnits: amountMinorUnits + addend,
        fractionalDigitsEntered: fractionalDigitsEntered + 1,
        isFractionalMode: true,
      );
    }
    final shifted = amountMinorUnits * 10 + digit * _pow10(decimals);
    return KeypadState(
      amountMinorUnits: shifted,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
    );
  }

  /// Enter fractional mode. No-op when the active currency has zero
  /// decimals (the keypad widget greys the key out, but the helper must
  /// also reject so a mistaken caller cannot toggle the flag).
  /// Idempotent — pressing `.` while already in fractional mode does
  /// nothing.
  KeypadState pushDecimal({required int decimals}) {
    if (decimals == 0) return this;
    if (isFractionalMode) return this;
    return KeypadState(
      amountMinorUnits: amountMinorUnits,
      fractionalDigitsEntered: 0,
      isFractionalMode: true,
    );
  }

  /// Backspace. In fractional mode, drops the last fractional digit; if
  /// no fractional digits remain, exits fractional mode. In integer mode,
  /// drops the last integer digit (e.g. "12" → "1" → "0"). No-op on the
  /// empty initial state.
  KeypadState pop({required int decimals}) {
    if (isFractionalMode) {
      if (fractionalDigitsEntered == 0) {
        return KeypadState(
          amountMinorUnits: amountMinorUnits,
          fractionalDigitsEntered: 0,
          isFractionalMode: false,
        );
      }
      // Round amountMinorUnits down to the divisor that strips the last
      // fractional digit. For decimals=2 with one digit entered, divisor
      // is 10^(2-1+1) = 100 → 150 → 100 (drops the "5" of "1.5").
      final divisor = _pow10(decimals - fractionalDigitsEntered + 1);
      final reduced = (amountMinorUnits ~/ divisor) * divisor;
      return KeypadState(
        amountMinorUnits: reduced,
        fractionalDigitsEntered: fractionalDigitsEntered - 1,
        isFractionalMode: true,
      );
    }
    if (amountMinorUnits == 0) return this;
    final unit = _pow10(decimals);
    final integerPart = amountMinorUnits ~/ unit;
    final reducedInteger = integerPart ~/ 10;
    return KeypadState(
      amountMinorUnits: reducedInteger * unit,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
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
        other.isFractionalMode == isFractionalMode;
  }

  @override
  int get hashCode => Object.hash(
    amountMinorUnits,
    fractionalDigitsEntered,
    isFractionalMode,
  );

  @override
  String toString() =>
      'KeypadState(amountMinorUnits: $amountMinorUnits, '
      'fractionalDigitsEntered: $fractionalDigitsEntered, '
      'isFractionalMode: $isFractionalMode)';
}

int _pow10(int exponent) {
  assert(exponent >= 0);
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}
