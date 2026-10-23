import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/transactions/amount_formula.dart';
import 'package:ledgerly/features/transactions/keypad_state.dart';
import 'package:ledgerly/features/transactions/widgets/amount_display.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Widget _wrap(Widget child, {double? textScale}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: textScale == null
      ? null
      : (context, inner) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: inner!,
        ),
  home: Scaffold(body: child),
);

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');

/// A whole-number operand as the keypad records it.
FormulaOperand _whole(int minorUnits) => (
  amountMinorUnits: minorUnits,
  fractionalDigitsEntered: 0,
  isFractionalMode: false,
);

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
      formulaOperands: [_whole(1200)],
      formulaOperators: [CalcOperator.add],
      isEvaluating: true,
      hasCurrentInput: true,
    );

    await tester.pumpWidget(
      _wrap(AmountDisplay(keypad: keypad, currency: _usd)),
    );

    expect(find.textContaining('12 +'), findsOneWidget);
  });

  testWidgets(
    'AD03: showingResult keeps expression history on the first line',
    (tester) async {
      final keypad = KeypadState(
        amountMinorUnits: 1700,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        formulaOperands: [_whole(1200), _whole(500)],
        formulaOperators: [CalcOperator.add],
        showingResult: true,
        hasCurrentInput: false,
      );

      await tester.pumpWidget(
        _wrap(AmountDisplay(keypad: keypad, currency: _usd)),
      );

      expect(find.textContaining('12 + 5 ='), findsOneWidget);
    },
  );

  testWidgets(
    'AD04: showingResult renders the main result at fixed precision',
    (tester) async {
      final keypad = KeypadState(
        amountMinorUnits: 1700,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        formulaOperands: [_whole(1200), _whole(500)],
        formulaOperators: [CalcOperator.add],
        showingResult: true,
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
      formulaOperands: [_whole(12), _whole(2)],
      formulaOperators: [CalcOperator.divide],
      showingResult: true,
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
        formulaOperands: [_whole(1200), _whole(500)],
        formulaOperators: [CalcOperator.add],
        showingResult: true,
        hasCurrentInput: false,
      );

      await tester.pumpWidget(
        _wrap(AmountDisplay(keypad: keypad, currency: _usd), textScale: 2.0),
      );

      expect(find.textContaining('12 + 5 ='), findsOneWidget);
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
        formulaOperands: [_whole(100)],
        formulaOperators: [CalcOperator.add],
        isEvaluating: true,
        hasCurrentInput: false,
      );

      await tester.pumpWidget(
        _wrap(
          AmountDisplay(
            keypad: keypad,
            currency: _usd,
            currencyTouched: true, // would show placeholder without the hasVisibleInput guard
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
      expect(find.textContaining('1 +'), findsOneWidget);
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

  group('equals button', () {
    final evaluating = KeypadState(
      amountMinorUnits: 500,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      formulaOperands: [_whole(1200)],
      formulaOperators: [CalcOperator.add],
      isEvaluating: true,
      hasCurrentInput: true,
    );
    final result = KeypadState(
      amountMinorUnits: 1700,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      formulaOperands: [_whole(1200), _whole(500)],
      formulaOperators: [CalcOperator.add],
      showingResult: true,
    );

    IconButton equalsButton(WidgetTester tester) => tester.widget<IconButton>(
      find.ancestor(of: find.text('='), matching: find.byType(IconButton)),
    );

    testWidgets('AD10: hidden while no expression is in progress', (
      tester,
    ) async {
      final typed = const KeypadState.initial().push(5, decimals: 2);
      await tester.pumpWidget(
        _wrap(AmountDisplay(keypad: typed, currency: _usd, onEquals: () {})),
      );

      expect(find.byTooltip('Equals'), findsNothing);
    });

    testWidgets('AD11: enabled while an expression is pending', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          AmountDisplay(
            keypad: evaluating,
            currency: _usd,
            onEquals: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Equals'));
      expect(taps, 1);
      // PRD a11y: keypad keys keep a 48x48dp minimum tap target.
      final size = tester.getSize(
        find.ancestor(of: find.text('='), matching: find.byType(IconButton)),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('AD12: stays visible but disabled on the result', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AmountDisplay(keypad: result, currency: _usd, onEquals: () {})),
      );

      expect(find.byTooltip('Equals'), findsOneWidget);
      expect(equalsButton(tester).onPressed, isNull);
      // The glyph follows the button's disabled foreground, not full contrast.
      final glyph = tester.renderObject<RenderParagraph>(find.text('='));
      expect(glyph.text.style?.color?.a, lessThan(1.0));
    });

    testWidgets('AD13: absent when no onEquals callback is supplied', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AmountDisplay(keypad: evaluating, currency: _usd)),
      );

      expect(find.byTooltip('Equals'), findsNothing);
    });

    testWidgets('AD14: 2x text scale with the button does not overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          AmountDisplay(keypad: evaluating, currency: _usd, onEquals: () {}),
          textScale: 2.0,
        ),
      );

      expect(find.byTooltip('Equals'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
