// Conversion-specific widget tests for SummaryStrip — Phase 2.
//
// The general layout tests (groups, placeholder, jump-to-today) live in
// `summary_strip_test.dart`. This file focuses on conversion correctness:
// unified totals, fallback when rates are missing, a11y semantics
// (screen reader reads "approximately" prefix), and same-currency
// passthrough (no ≈ prefix).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/home/widgets/summary_strip.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

void main() {
  Widget buildStrip({
    required Map<String, ({int expense, int income})> todayTotals,
    required Map<String, int> monthNet,
    required String defaultCurrency,
    Map<String, int>? rates,
  }) {
    return ProviderScope(
      overrides: [
        exchangeRatesProvider.overrideWith(
          (_) => Stream.value(rates ?? const <String, int>{}),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SummaryStrip(
            todayTotalsByCurrency: todayTotals,
            monthNetByCurrency: monthNet,
            currenciesByCode: const {
              'USD': Currency(code: 'USD', decimals: 2, symbol: r'$'),
              'EUR': Currency(code: 'EUR', decimals: 2, symbol: '€'),
              'JPY': Currency(code: 'JPY', decimals: 0, symbol: '¥'),
            },
            locale: 'en_US',
            defaultCurrency: defaultCurrency,
          ),
        ),
      ),
    );
  }

  group('SummaryStrip conversion', () {
    testWidgets('shows unified total when rate available', (tester) async {
      await tester.pumpWidget(
        buildStrip(
          todayTotals: const {'EUR': (expense: 500, income: 0)},
          monthNet: const {'EUR': -2000},
          defaultCurrency: 'USD',
          rates: {'EUR→USD': (1.08 * 1000000000).round()},
        ),
      );
      await tester.pumpAndSettle();
      // Unified group renders with USD symbol AND the ≈ prefix.
      expect(find.textContaining('≈'), findsWidgets);
      expect(find.textContaining(r'$'), findsWidgets);
    });

    testWidgets('falls back to per-currency when rate missing', (tester) async {
      await tester.pumpWidget(
        buildStrip(
          todayTotals: const {'EUR': (expense: 500, income: 0)},
          monthNet: const {'EUR': -2000},
          defaultCurrency: 'USD',
          rates: const {},
        ),
      );
      await tester.pumpAndSettle();
      // EUR group shows directly; no ≈ prefix (no conversion happened).
      expect(find.textContaining('€'), findsWidgets);
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('mixed: unified group + fallback group with separator', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildStrip(
          todayTotals: const {
            'EUR': (expense: 500, income: 0),
            'JPY': (expense: 1000, income: 0),
          },
          monthNet: const {'EUR': -2000, 'JPY': -1000},
          defaultCurrency: 'USD',
          rates: {'EUR→USD': (1.08 * 1000000000).round()},
        ),
      );
      await tester.pumpAndSettle();
      // EUR was convertible → unified USD group exists.
      expect(find.textContaining(r'$'), findsWidgets);
      // JPY had no rate → fallback group renders.
      expect(find.textContaining('¥'), findsWidgets);
      // Separator label present.
      expect(find.text('Unconverted'), findsOneWidget);
    });

    testWidgets('same-currency totals pass through unchanged (no ≈)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildStrip(
          todayTotals: const {'USD': (expense: 1000, income: 500)},
          monthNet: const {'USD': -500},
          defaultCurrency: 'USD',
        ),
      );
      await tester.pumpAndSettle();
      // No ≈ prefix when all amounts are already in the default currency.
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('approximate values carry a11y "approximately" label', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildStrip(
          todayTotals: const {'EUR': (expense: 500, income: 0)},
          monthNet: const {'EUR': -2000},
          defaultCurrency: 'USD',
          rates: {'EUR→USD': (1.08 * 1000000000).round()},
        ),
      );
      await tester.pumpAndSettle();
      // At least one Semantics node should carry the "approximately" label.
      // The label format is "approximately <amount>" — the literal en US
      // copy is set via `AppLocalizations.approximatelyPrefix`.
      expect(find.bySemanticsLabel(RegExp(r'^approximately ')), findsWidgets);
    });
  });
}
