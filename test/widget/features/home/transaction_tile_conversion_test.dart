// Conversion-specific widget tests for TransactionTile — Phase 2.
//
// Verifies that the secondary converted-amount line appears when (and
// only when) the transaction's currency differs from the user's default
// AND a rate is available. Also covers a11y (Semantics carries the
// "approximately" label so the ≈ glyph is read aloud correctly).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/features/home/home_providers.dart';
import 'package:ledgerly/features/home/widgets/transaction_tile.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

void main() {
  final testTransaction = Transaction(
    id: 1,
    amountMinorUnits: 540,
    currency: const Currency(code: 'EUR', decimals: 2, symbol: '€'),
    categoryId: 1,
    accountId: 1,
    date: DateTime(2026, 5, 14),
    createdAt: DateTime(2026, 5, 14),
    updatedAt: DateTime(2026, 5, 14),
  );

  const testCategory = Category(
    id: 1,
    icon: 'restaurant',
    color: 0,
    type: CategoryType.expense,
    l10nKey: 'category.food',
  );

  const testAccount = Account(
    id: 1,
    name: 'Cash',
    accountTypeId: 1,
    currency: Currency(code: 'EUR', decimals: 2, symbol: '€'),
  );

  Widget buildTile({
    required String defaultCurrency,
    Map<String, int>? rates,
  }) {
    return ProviderScope(
      overrides: [
        exchangeRatesProvider.overrideWith(
          (_) => Stream.value(rates ?? const <String, int>{}),
        ),
        homeCurrenciesByCodeProvider.overrideWith(
          (_) => Stream.value({
            'USD': const Currency(code: 'USD', decimals: 2, symbol: r'$'),
            'EUR': const Currency(code: 'EUR', decimals: 2, symbol: '€'),
          }),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TransactionTile(
            transaction: testTransaction,
            category: testCategory,
            account: testAccount,
            locale: 'en_US',
            defaultCurrency: defaultCurrency,
            onTap: () {},
            onDuplicate: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
  }

  group('TransactionTile conversion', () {
    testWidgets('shows converted line when rate available', (tester) async {
      await tester.pumpWidget(
        buildTile(
          defaultCurrency: 'USD',
          rates: {'EUR→USD': (1.08 * 1000000000).round()},
        ),
      );
      await tester.pumpAndSettle();

      // Primary amount in EUR.
      expect(find.textContaining('€'), findsOneWidget);
      // Secondary ≈ line in USD.
      expect(find.textContaining('≈'), findsOneWidget);
    });

    testWidgets('hides converted line when same currency', (tester) async {
      await tester.pumpWidget(buildTile(defaultCurrency: 'EUR'));
      await tester.pumpAndSettle();
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('hides converted line when rate missing', (tester) async {
      await tester.pumpWidget(
        buildTile(defaultCurrency: 'USD', rates: const {}),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('converted line carries a11y "approximately" label', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTile(
          defaultCurrency: 'USD',
          rates: {'EUR→USD': (1.08 * 1000000000).round()},
        ),
      );
      await tester.pumpAndSettle();

      // Verify the Semantics wrapper carries the localized approximately
      // prefix by inspecting the widget tree directly. Avoids a flake
      // where `bySemanticsLabel` does not traverse `excludeSemantics:
      // true` children consistently across Flutter versions.
      final semantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.label?.startsWith('approximately') ?? false)
          .toList();
      expect(semantics, isNotEmpty);
    });
  });
}
