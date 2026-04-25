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
import 'package:ledgerly/features/transactions/keypad_state.dart';

void main() {
  group('KeypadState — initial state', () {
    test('K01: defaults are zero / integer mode', () {
      const s = KeypadState.initial();
      expect(s.amountMinorUnits, 0);
      expect(s.fractionalDigitsEntered, 0);
      expect(s.isFractionalMode, isFalse);
    });
  });

  group('KeypadState.push — integer mode', () {
    test('K02: push(1) on USD shifts to 100 minor units', () {
      final s = const KeypadState.initial().push(1, decimals: 2);
      expect(s.amountMinorUnits, 100);
      expect(s.isFractionalMode, isFalse);
    });

    test('K03: push(1).push(2) on USD accumulates to 1200', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .push(2, decimals: 2);
      expect(s.amountMinorUnits, 1200);
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
    test('K20: 1 . 5 on USD → 150 minor units, 1 fractional digit', () {
      final s = const KeypadState.initial()
          .push(1, decimals: 2)
          .pushDecimal(decimals: 2)
          .push(5, decimals: 2);
      expect(s.amountMinorUnits, 150);
      expect(s.fractionalDigitsEntered, 1);
      expect(s.isFractionalMode, isTrue);
    });

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
}
