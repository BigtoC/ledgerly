// SummaryStrip widget tests — Wave 3 §4.3.
//
// Covers: single-currency case, multi-currency case (two currency
// groups), all-zero / empty case (placeholders).
//
// Phase 2: SummaryStrip is a ConsumerWidget that reads
// `exchangeRatesProvider`. Tests use a `ProviderScope` to inject a
// rates-stream override. Where rates are absent the strip falls back to
// per-currency render (mirrors the old behavior). Where a rate is
// supplied for a non-default currency, the strip renders a unified
// converted total in the default currency.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/home/widgets/summary_strip.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');
const _eur = Currency(code: 'EUR', decimals: 2, symbol: '€');

Widget _wrap(Widget child, {Map<String, int>? rates}) => ProviderScope(
  overrides: [
    exchangeRatesProvider.overrideWith(
      (_) => Stream.value(rates ?? const <String, int>{}),
    ),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('SS01: single currency — USD chip group rendered', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SummaryStrip(
          todayTotalsByCurrency: const {'USD': (expense: 1500, income: 500)},
          monthNetByCurrency: const {'USD': -1000},
          currenciesByCode: const {'USD': _usd},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('USD'), findsNothing);
    expect(find.textContaining(r'$15.00'), findsOneWidget);
    expect(find.textContaining(r'$5.00'), findsOneWidget);
    expect(find.textContaining(r'-$10.00'), findsOneWidget);
    // Default-currency-only case: no ≈ prefix.
    expect(find.textContaining('≈'), findsNothing);
  });

  testWidgets(
    'SS02a: multi-currency with rates available — unified USD group',
    (tester) async {
      // USD: today expense 100 = $1.00, monthNet -100 = -$1.00
      // JPY: today expense 500 = ¥500 → at 0.01 USD/JPY = 500 JPY minor units
      // (JPY has 0 decimals) converted to USD (2 decimals):
      //   500 * 0.01 = 5 USD → scale-shift +2 → 500 USD minor units = $5.00.
      // monthNet -500 JPY → -$5.00.
      // Unified totals: expense = $1.00 + $5.00 = $6.00; monthNet = -$6.00.
      await tester.pumpWidget(
        _wrap(
          SummaryStrip(
            todayTotalsByCurrency: const {
              'USD': (expense: 100, income: 0),
              'JPY': (expense: 500, income: 0),
            },
            monthNetByCurrency: const {'USD': -100, 'JPY': -500},
            currenciesByCode: const {'USD': _usd, 'JPY': _jpy},
            locale: 'en_US',
            defaultCurrency: 'USD',
          ),
          rates: {'JPY→USD': (0.01 * 1000000000).round()},
        ),
      );
      await tester.pumpAndSettle();
      // Unified group with the ≈ prefix.
      expect(find.textContaining('≈'), findsWidgets);
      expect(find.text(r'≈ $6.00'), findsOneWidget);
      expect(find.text(r'≈ -$6.00'), findsOneWidget);
      // No JPY fallback group because the JPY→USD rate is available.
      expect(find.text('¥500'), findsNothing);
    },
  );

  testWidgets('SS02b: multi-currency with rates missing — fallback groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SummaryStrip(
          todayTotalsByCurrency: const {
            'USD': (expense: 100, income: 0),
            'JPY': (expense: 500, income: 0),
          },
          monthNetByCurrency: const {'USD': -100, 'JPY': -500},
          currenciesByCode: const {'USD': _usd, 'JPY': _jpy},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Default USD group renders (canShowUnified true: USD is convertible).
    expect(find.text(r'$1.00'), findsOneWidget);
    expect(find.text(r'-$1.00'), findsOneWidget);
    // JPY shows in the fallback group below the "Unconverted" separator.
    expect(find.text('¥500'), findsOneWidget);
    expect(find.text(r'-¥500'), findsOneWidget);
    // Separator header is present.
    expect(find.text('Unconverted'), findsOneWidget);
  });

  testWidgets('SS03: empty maps — placeholder dashes for each label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SummaryStrip(
          todayTotalsByCurrency: const {},
          monthNetByCurrency: const {},
          currenciesByCode: const {},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
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
            defaultCurrency: 'USD',
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
    'SS05: jump-to-today button disabled when showJumpToToday is false',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          SummaryStrip(
            todayTotalsByCurrency: const {'USD': (expense: 100, income: 0)},
            monthNetByCurrency: const {'USD': -100},
            currenciesByCode: const {'USD': _usd},
            locale: 'en_US',
            defaultCurrency: 'USD',
            showJumpToToday: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jump to today'), findsOneWidget);
      final button = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Jump to today'),
          matching: find.byType(TextButton),
        ),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('SS06: multi-currency with default present + others missing — '
      'unified default + fallback for others', (tester) async {
    // USD is the default — convertible (identity).
    // AUD/CAD have no rates — fallback to per-currency groups.
    await tester.pumpWidget(
      _wrap(
        SummaryStrip(
          todayTotalsByCurrency: const {'USD': (expense: 100, income: 0)},
          monthNetByCurrency: const {'AUD': -100, 'CAD': -200, 'USD': -300},
          currenciesByCode: const {'USD': _usd, 'JPY': _jpy, 'EUR': _eur},
          locale: 'en_US',
          defaultCurrency: 'USD',
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Default USD group totals: expense $1.00, monthNet -$3.00.
    expect(find.textContaining(r'-$3.00'), findsOneWidget);
    // Two fallback groups: AUD and CAD.
    expect(find.text('Unconverted'), findsOneWidget);
  });
}
