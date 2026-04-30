// CalculatorKeypad widget tests — Wave 2 §4.3.
//
// Covers:
//   - Decimal point disabled when `decimals = 0` (JPY).
//   - Decimal point enabled when `decimals > 0` (USD).
//   - Digit overflow after max decimals reached: extra digits drop on
//     the floor (clamping is the helper's job, but the widget must keep
//     calling `onDigit` so we can verify the clamp's downstream effect
//     when the screen plumbs both into the controller).
//   - Operator keys (÷ × − +) emit the correct CalcOperator enum values.
//   - Long-pressing ⌫ triggers onClear.
//   - Old 00 / C keys are gone.
//   - Text scale clamping at 1.5×.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/features/transactions/keypad_state.dart';
import 'package:ledgerly/features/transactions/widgets/calculator_keypad.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Widget _wrap(Widget child, {double? textScale}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: textScale == null
      ? null
      : (context, inner) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: inner!,
        ),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('WK01: decimal point is enabled on USD (decimals = 2)', (
    tester,
  ) async {
    var decimalTaps = 0;
    await tester.pumpWidget(
      _wrap(
        CalculatorKeypad(
          decimals: 2,
          onDigit: (_) {},
          onDecimal: () => decimalTaps++,
          onBackspace: () {},
          onClear: () {},
          onOperator: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('.'));
    expect(decimalTaps, 1);
  });

  testWidgets('WK02: decimal point is disabled on JPY (decimals = 0)', (
    tester,
  ) async {
    var decimalTaps = 0;
    await tester.pumpWidget(
      _wrap(
        CalculatorKeypad(
          decimals: 0,
          onDigit: (_) {},
          onDecimal: () => decimalTaps++,
          onBackspace: () {},
          onClear: () {},
          onOperator: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('.'));
    expect(decimalTaps, 0); // tap was a no-op (key disabled)
  });

  testWidgets('WK03: decimal key is a no-op when decimals == 0', (
    tester,
  ) async {
    var decimalTaps = 0;
    await tester.pumpWidget(
      _wrap(
        CalculatorKeypad(
          decimals: 0,
          onDigit: (_) {},
          onDecimal: () => decimalTaps++,
          onBackspace: () {},
          onClear: () {},
          onOperator: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('.'));
    expect(decimalTaps, 0);
  });

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
            onOperator: (_) {},
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

  testWidgets(
    'WK10: operator keys render and forward the expected enum values',
    (tester) async {
      final tapped = <CalcOperator>[];

      await tester.pumpWidget(
        _wrap(
          CalculatorKeypad(
            decimals: 2,
            onDigit: (_) {},
            onDecimal: () {},
            onBackspace: () {},
            onClear: () {},
            onOperator: tapped.add,
          ),
        ),
      );

      expect(find.text('÷'), findsOneWidget);
      expect(find.text('×'), findsOneWidget);
      expect(find.text('−'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);

      await tester.tap(find.text('+'));
      await tester.tap(find.text('−'));
      await tester.tap(find.text('×'));
      await tester.tap(find.text('÷'));

      expect(tapped, const [
        CalcOperator.add,
        CalcOperator.subtract,
        CalcOperator.multiply,
        CalcOperator.divide,
      ]);
    },
  );

  testWidgets('WK11: old 00 and C keys are gone', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CalculatorKeypad(
          decimals: 2,
          onDigit: (_) {},
          onDecimal: () {},
          onBackspace: () {},
          onClear: () {},
          onOperator: (_) {},
        ),
      ),
    );

    expect(find.text('00'), findsNothing);
    expect(find.text('C'), findsNothing);
  });

  testWidgets('WK12: long-pressing backspace triggers clear', (tester) async {
    var clearCount = 0;

    await tester.pumpWidget(
      _wrap(
        CalculatorKeypad(
          decimals: 2,
          onDigit: (_) {},
          onDecimal: () {},
          onBackspace: () {},
          onClear: () => clearCount++,
          onOperator: (_) {},
        ),
      ),
    );

    await tester.longPress(find.byTooltip('Backspace'));
    expect(clearCount, 1);
  });

  testWidgets('WK13: operator keys expose localized semantics labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CalculatorKeypad(
          decimals: 2,
          onDigit: (_) {},
          onDecimal: () {},
          onBackspace: () {},
          onClear: () {},
          onOperator: (_) {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('Add'), findsOneWidget);
    expect(find.bySemanticsLabel('Subtract'), findsOneWidget);
    expect(find.bySemanticsLabel('Multiply'), findsOneWidget);
    expect(find.bySemanticsLabel('Divide'), findsOneWidget);
  });

  testWidgets('WK14: operator labels clamp at 1.5x text scale', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CalculatorKeypad(
          decimals: 2,
          onDigit: (_) {},
          onDecimal: () {},
          onBackspace: () {},
          onClear: () {},
          onOperator: (_) {},
        ),
        textScale: 2.0,
      ),
    );

    final plusText = tester.widget<Text>(find.text('+'));
    expect(plusText.textScaler!.scale(10), lessThanOrEqualTo(15.0));
    expect(find.text('+'), findsOneWidget);
    expect(find.text('÷'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
