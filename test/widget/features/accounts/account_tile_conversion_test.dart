// Conversion-specific widget tests for AccountTile — Phase 2.
//
// Verifies that the converted-total line appears below the per-currency
// balance lines when (and only when) the account holds multiple
// currencies AND every non-default-currency code has a cached rate.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/accounts/accounts_providers.dart';
import 'package:ledgerly/features/accounts/accounts_state.dart';
import 'package:ledgerly/features/accounts/widgets/account_tile.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

void main() {
  Widget buildTile({
    required Map<String, int> balancesByCurrency,
    Map<String, int>? rates,
    String defaultCurrency = 'USD',
  }) {
    const account = Account(
      id: 1,
      name: 'Multi-Currency',
      accountTypeId: 1,
      currency: Currency(code: 'USD', decimals: 2, symbol: r'$'),
    );

    return ProviderScope(
      overrides: [
        exchangeRatesProvider.overrideWith(
          (_) => Stream.value(rates ?? const <String, int>{}),
        ),
        defaultCurrencyProvider.overrideWith(
          (_) => Stream.value(defaultCurrency),
        ),
        initialDefaultCurrencyProvider.overrideWithValue(defaultCurrency),
        currenciesByCodeProvider.overrideWith(
          (_) => Stream.value({
            'USD': const Currency(code: 'USD', decimals: 2, symbol: r'$'),
            'EUR': const Currency(code: 'EUR', decimals: 2, symbol: '€'),
            'JPY': const Currency(code: 'JPY', decimals: 0, symbol: '¥'),
          }),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AccountTile(
            view: AccountWithBalance(
              account: account,
              balancesByCurrency: balancesByCurrency,
              affordance: AccountRowAffordance.archive,
            ),
            isDefault: false,
            locale: 'en_US',
            accountTypeLabel: 'Cash',
            onTap: () {},
            onSetDefault: () {},
            onArchive: () {},
            onDelete: () {},
            onArchiveBlocked: () {},
          ),
        ),
      ),
    );
  }

  group('AccountTile conversion', () {
    testWidgets('shows converted total for multi-currency with rates', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTile(
          balancesByCurrency: const {'USD': 34000, 'EUR': 125000},
          rates: {'EUR→USD': (1.08 * 1000000000).round()},
        ),
      );
      await tester.pumpAndSettle();
      // Converted total line shows the ≈ prefix and the localized "total"
      // suffix.
      expect(find.textContaining('≈'), findsOneWidget);
      expect(find.textContaining('total'), findsOneWidget);
    });

    testWidgets('hides converted total for single-currency account', (
      tester,
    ) async {
      await tester.pumpWidget(buildTile(balancesByCurrency: const {'USD': 34000}));
      await tester.pumpAndSettle();
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('hides converted total when any rate missing', (tester) async {
      await tester.pumpWidget(
        buildTile(
          balancesByCurrency: const {'USD': 34000, 'EUR': 125000},
          rates: const {},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('≈'), findsNothing);
    });
  });
}
