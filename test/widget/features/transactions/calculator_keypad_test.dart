// CalculatorKeypad widget tests — Wave 2 §4.3.
//
// Covers:
//   - Decimal point disabled when `decimals = 0` (JPY).
//   - Decimal point enabled when `decimals > 0` (USD).
//   - Digit overflow after max decimals reached: extra digits drop on
//     the floor (clamping is the helper's job, but the widget must keep
//     calling `onDigit` so we can verify the clamp's downstream effect
//     when the screen plumbs both into the controller).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/features/transactions/keypad_state.dart';
import 'package:ledgerly/features/transactions/widgets/calculator_keypad.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'WK01: decimal point is enabled on USD (decimals = 2)',
    (tester) async {
      var decimalTaps = 0;
      await tester.pumpWidget(
        _wrap(
          CalculatorKeypad(
            decimals: 2,
            onDigit: (_) {},
            onDecimal: () => decimalTaps++,
            onBackspace: () {},
            onClear: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('.'));
      expect(decimalTaps, 1);
    },
  );

  testWidgets(
    'WK02: decimal point is disabled on JPY (decimals = 0)',
    (tester) async {
      var decimalTaps = 0;
      await tester.pumpWidget(
        _wrap(
          CalculatorKeypad(
            decimals: 0,
            onDigit: (_) {},
            onDecimal: () => decimalTaps++,
            onBackspace: () {},
            onClear: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('.'));
      expect(decimalTaps, 0); // tap was a no-op (key disabled)
    },
  );

  testWidgets(
    'WK03: 00 key fires onDigit(0) twice',
    (tester) async {
      final pressed = <int>[];
      await tester.pumpWidget(
        _wrap(
          CalculatorKeypad(
            decimals: 2,
            onDigit: pressed.add,
            onDecimal: () {},
            onBackspace: () {},
            onClear: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('00'));
      expect(pressed, [0, 0]);
    },
  );

  testWidgets(
    'WK04: digit overflow after max decimals — KeypadState clamps the 4th frac digit',
    (tester) async {
      // Drives the helper directly through the keypad's onDigit callback
      // to verify the round-trip stays clamped at currency.decimals.
      var keypad = const KeypadState.initial();
      const decimals = 2;
      await tester.pumpWidget(
        _wrap(
          CalculatorKeypad(
            decimals: decimals,
            onDigit: (d) {
              keypad = keypad.push(d, decimals: decimals);
            },
            onDecimal: () {
              keypad = keypad.pushDecimal(decimals: decimals);
            },
            onBackspace: () {},
            onClear: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Type "1.234" — the 4 must be dropped (decimals=2).
      await tester.tap(find.text('1'));
      await tester.tap(find.text('.'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      expect(keypad.amountMinorUnits, 123);
      expect(keypad.fractionalDigitsEntered, 2);
    },
  );
}
