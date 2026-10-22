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

KeypadState _typed(String keys) {
  var s = const KeypadState.initial();
  for (final key in keys.split('')) {
    s = switch (key) {
      '.' => s.pushDecimal(decimals: 2),
      '+' => s.pushOperator(CalcOperator.add, decimals: 2),
      '-' => s.pushOperator(CalcOperator.subtract, decimals: 2),
      '*' => s.pushOperator(CalcOperator.multiply, decimals: 2),
      '/' => s.pushOperator(CalcOperator.divide, decimals: 2),
      '=' => s.equals(decimals: 2),
      _ => s.push(int.parse(key), decimals: 2),
    };
  }
  return s;
}

void main() {
  testWidgets(
    'ADF01: while typing, the history line shows the formula so far',
    (tester) async {
      await tester.pumpWidget(
        _wrap(AmountDisplay(keypad: _typed('3.5+10.5+11+3'), currency: _usd)),
      );

      expect(find.text('3.5 + 10.5 + 11 +'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    },
  );

  testWidgets('ADF02: a loaded formula shows with its recalculated result', (
    tester,
  ) async {
    final keypad = KeypadState.fromFormula(
      parseAmountFormula('3.5+10.5+11+3', decimals: 2)!,
      decimals: 2,
    );
    await tester.pumpWidget(
      _wrap(AmountDisplay(keypad: keypad, currency: _usd)),
    );

    expect(find.text('3.5 + 10.5 + 11 + 3 ='), findsOneWidget);
    expect(find.text('28.00'), findsOneWidget);
  });

  testWidgets('ADF03: = after a dangling operator shows the finished formula', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(AmountDisplay(keypad: _typed('1+2+='), currency: _usd)),
    );

    expect(find.text('1 + 2 ='), findsOneWidget);
    expect(find.text('3.00'), findsOneWidget);
  });

  testWidgets('ADF04: operators use display symbols', (tester) async {
    await tester.pumpWidget(
      _wrap(AmountDisplay(keypad: _typed('8-2*3='), currency: _usd)),
    );

    expect(find.text('(8 − 2) × 3 ='), findsOneWidget);
    expect(find.text('18.00'), findsOneWidget);
  });

  testWidgets('ADF05: a long formula keeps its end in view at 2x text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final keypad = KeypadState.fromFormula(
      parseAmountFormula('12.99+4.5+23.75+8+15.2+6.49+3', decimals: 2)!,
      decimals: 2,
    );
    await tester.pumpWidget(
      _wrap(
        AmountDisplay(keypad: keypad, currency: _usd, onEquals: () {}),
        textScale: 2.0,
      ),
    );

    const history = '12.99 + 4.5 + 23.75 + 8 + 15.2 + 6.49 + 3 =';
    final paragraph = tester.renderObject<RenderParagraph>(find.text(history));
    // Not ellipsized: the whole formula is laid out ...
    expect(paragraph.didExceedMaxLines, isFalse);
    // ... and its end (the part backspace edits) is on screen.
    final display = tester.getRect(find.byType(AmountDisplay));
    expect(tester.getRect(find.text(history)).right, lessThan(display.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ADF06: a short expression stays left-aligned with the amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        AmountDisplay(keypad: _typed('1+'), currency: _usd, onEquals: () {}),
      ),
    );

    final history = tester.getRect(find.text('1 +'));
    final amount = tester.getRect(find.text('0'));
    expect(history.left, moreOrLessEquals(amount.left, epsilon: 1));
  });

  group('ADF07: brackets show the left-to-right order', () {
    for (final (keys, history, result) in [
      ('1+2=*2=', '(1 + 2) × 2 =', '6.00'),
      ('1+2*2+3*4=', '((1 + 2) × 2 + 3) × 4 =', '36.00'),
      ('2*3+4=', '2 × 3 + 4 =', '10.00'),
      ('9-3/2=', '(9 − 3) ÷ 2 =', '3.00'),
      ('2*3*4=', '2 × 3 × 4 =', '24.00'),
    ]) {
      testWidgets('$keys renders $history', (tester) async {
        await tester.pumpWidget(
          _wrap(AmountDisplay(keypad: _typed(keys), currency: _usd)),
        );

        expect(find.text(history), findsOneWidget);
        expect(find.text(result), findsOneWidget);
      });
    }

    testWidgets('a pending operator is bracketed too', (tester) async {
      await tester.pumpWidget(
        _wrap(AmountDisplay(keypad: _typed('1+2*'), currency: _usd)),
      );

      expect(find.text('(1 + 2) ×'), findsOneWidget);
    });
  });
}
