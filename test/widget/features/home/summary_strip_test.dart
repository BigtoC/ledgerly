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
    expect(find.text('USD'), findsOneWidget);
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
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('JPY'), findsOneWidget);
    // JPY decimals = 0 → no fractional digits. Today-expense chip
    // renders the unsigned amount; month-net chip renders the signed
    // amount with a leading `-`.
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
}
