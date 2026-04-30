import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/transactions/keypad_state.dart';
import 'package:ledgerly/features/transactions/widgets/amount_display.dart';
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

final _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
final _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');

void main() {
  testWidgets('AD01: no expression state renders no expression line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const AmountDisplay(keypad: KeypadState.initial(), currency: null)),
    );

    expect(find.textContaining('='), findsNothing);
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('AD02: evaluating state shows the left operand and operator', (
    tester,
  ) async {
    final keypad = KeypadState(
      amountMinorUnits: 500,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: 1200,
      operator: CalcOperator.add,
      isEvaluating: true,
      hasCurrentInput: true,
    );

    await tester.pumpWidget(
      _wrap(AmountDisplay(keypad: keypad, currency: _usd)),
    );

    expect(find.textContaining('12.00 +'), findsOneWidget);
  });

  testWidgets(
    'AD03: showingResult keeps expression history on the first line',
    (tester) async {
      final keypad = KeypadState(
        amountMinorUnits: 1700,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        leftOperand: 1200,
        operator: CalcOperator.add,
        showingResult: true,
        rightOperand: 500,
        hasCurrentInput: false,
      );

      await tester.pumpWidget(
        _wrap(AmountDisplay(keypad: keypad, currency: _usd)),
      );

      expect(find.textContaining('12.00 + 5.00 ='), findsOneWidget);
    },
  );

  testWidgets(
    'AD04: showingResult renders the main result at fixed precision',
    (tester) async {
      final keypad = KeypadState(
        amountMinorUnits: 1700,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        leftOperand: 1200,
        operator: CalcOperator.add,
        showingResult: true,
        rightOperand: 500,
        hasCurrentInput: false,
      );

      await tester.pumpWidget(
        _wrap(AmountDisplay(keypad: keypad, currency: _usd)),
      );

      expect(find.text('17.00'), findsOneWidget);
    },
  );

  testWidgets('AD05: zero-decimal currencies keep zero-decimal formatting', (
    tester,
  ) async {
    final keypad = KeypadState(
      amountMinorUnits: 6,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: 12,
      operator: CalcOperator.divide,
      showingResult: true,
      rightOperand: 2,
      hasCurrentInput: false,
    );

    await tester.pumpWidget(
      _wrap(AmountDisplay(keypad: keypad, currency: _jpy)),
    );

    expect(find.textContaining('12 ÷ 2 ='), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets(
    'AD06: expression history and result remain visible at 2x text scale',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 300));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final keypad = KeypadState(
        amountMinorUnits: 1700,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        leftOperand: 1200,
        operator: CalcOperator.add,
        showingResult: true,
        rightOperand: 500,
        hasCurrentInput: false,
      );

      await tester.pumpWidget(
        _wrap(AmountDisplay(keypad: keypad, currency: _usd), textScale: 2.0),
      );

      expect(find.textContaining('12.00 + 5.00 ='), findsOneWidget);
      expect(find.text('17.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AD07: placeholder is suppressed when keypad has visible input even if amount is zero',
    (tester) async {
      // isEvaluating=true means hasVisibleInput=true — placeholder must not show.
      final keypad = KeypadState(
        amountMinorUnits: 0,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        leftOperand: 100,
        operator: CalcOperator.add,
        isEvaluating: true,
        hasCurrentInput: false,
      );

      await tester.pumpWidget(
        _wrap(
          AmountDisplay(
            keypad: keypad,
            currency: _usd,
            currencyTouched:
                true, // would show placeholder without the hasVisibleInput guard
          ),
        ),
      );

      // Placeholder pattern must NOT appear (currency-specific placeholder text).
      // The code below uses the l10n format which typically starts with "Enter"
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.startsWith('Enter') == true ||
                  widget.data?.contains('amount') == true),
        ),
        findsNothing,
      );
      // Expression line must appear
      expect(find.textContaining('1.00 +'), findsOneWidget);
    },
  );

  testWidgets(
    'AD07b: decimal-start input suppresses the placeholder after a manual currency pick',
    (tester) async {
      final keypad = KeypadState(
        amountMinorUnits: 0,
        fractionalDigitsEntered: 0,
        isFractionalMode: true,
        hasCurrentInput: true,
      );

      await tester.pumpWidget(
        _wrap(
          AmountDisplay(keypad: keypad, currency: _usd, currencyTouched: true),
        ),
      );

      expect(find.text('0.'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.startsWith('Enter') == true ||
                  widget.data?.contains('amount') == true),
        ),
        findsNothing,
      );
    },
  );
}
