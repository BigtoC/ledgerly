// SummaryStrip widget tests — Wave 3 §4.3.
//
// Covers: single-currency case, multi-currency case (two currency
// groups), all-zero / empty case (placeholders).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/home/widgets/summary_strip.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');
const _eur = Currency(code: 'EUR', decimals: 2, symbol: '€');

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('SS01: single currency — USD chip group rendered', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {'USD': (expense: 1500, income: 500)},
          monthNetByCurrency: {'USD': -1000},
          currenciesByCode: {'USD': _usd},
          locale: 'en_US',
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The bare currency-code header is gone (the symbol on each amount
    // already conveys the currency). Today-expense / today-income /
    // month-net values still render via `MoneyFormatter`.
    expect(find.text('USD'), findsNothing);
    expect(find.textContaining(r'$15.00'), findsOneWidget);
    expect(find.textContaining(r'$5.00'), findsOneWidget);
    expect(find.textContaining(r'-$10.00'), findsOneWidget);
  });

  testWidgets('SS02: multi-currency — both currency groups rendered', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {
            'USD': (expense: 100, income: 0),
            'JPY': (expense: 500, income: 0),
          },
          monthNetByCurrency: {'USD': -100, 'JPY': -500},
          currenciesByCode: {'USD': _usd, 'JPY': _jpy},
          locale: 'en_US',
        ),
      ),
    );
    await tester.pumpAndSettle();
    // No standalone currency-code headers; both groups still render
    // their amounts with currency-specific formatting (USD has two
    // fractional digits, JPY has zero).
    expect(find.text('USD'), findsNothing);
    expect(find.text('JPY'), findsNothing);
    // USD: expense=100 → $1.00, monthNet=-100 → -$1.00.
    // Exact-match assertions to avoid `textContaining` matching both.
    expect(find.text(r'$1.00'), findsOneWidget);
    expect(find.text(r'-$1.00'), findsOneWidget);
    expect(find.text('¥500'), findsOneWidget);
    expect(find.text(r'-¥500'), findsOneWidget);
  });

  testWidgets('SS03: empty maps — placeholder dashes for each label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryStrip(
          todayTotalsByCurrency: {},
          monthNetByCurrency: {},
          currenciesByCode: {},
          locale: 'en_US',
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Three placeholder dashes — one per label row.
    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets(
    'SS04: jump-to-today button renders when showJumpToToday is true',
    (tester) async {
      var jumped = false;
      await tester.pumpWidget(
        _wrap(
          SummaryStrip(
            todayTotalsByCurrency: const {'USD': (expense: 100, income: 0)},
            monthNetByCurrency: const {'USD': -100},
            currenciesByCode: const {'USD': _usd},
            locale: 'en_US',
            showJumpToToday: true,
            onJumpToToday: () => jumped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jump to today'), findsOneWidget);
      await tester.tap(find.text('Jump to today'));
      await tester.pumpAndSettle();
      expect(jumped, isTrue);
    },
  );

  testWidgets(
    'SS05: jump-to-today button hidden when showJumpToToday is false',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SummaryStrip(
            todayTotalsByCurrency: {'USD': (expense: 100, income: 0)},
            monthNetByCurrency: {'USD': -100},
            currenciesByCode: {'USD': _usd},
            locale: 'en_US',
            showJumpToToday: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jump to today'), findsNothing);
    },
  );

  testWidgets(
    'SS06: capped groups prioritize selected-day currencies',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SummaryStrip(
            todayTotalsByCurrency: {
              'USD': (expense: 100, income: 0),
            },
            monthNetByCurrency: {
              'AUD': -100,
              'CAD': -200,
              'USD': -300,
            },
            currenciesByCode: {'USD': _usd, 'JPY': _jpy, 'EUR': _eur},
            locale: 'en_US',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Multiple currencies'), findsOneWidget);
      expect(find.textContaining(r'-$3.00'), findsOneWidget);
    },
  );
}
