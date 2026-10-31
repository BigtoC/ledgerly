// TransactionTile amount styling — Home.
//
// Income amounts render in the same neutral `onSurface` colour as
// expenses; the `+`/`-` sign alone distinguishes them.

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
  const hkd = Currency(code: 'HKD', decimals: 2, symbol: r'HK$');

  final transaction = Transaction(
    id: 1,
    amountMinorUnits: 69,
    currency: hkd,
    categoryId: 1,
    accountId: 1,
    date: DateTime(2026, 10, 30),
    createdAt: DateTime(2026, 10, 30),
    updatedAt: DateTime(2026, 10, 30),
  );

  const account = Account(id: 1, name: 'Cash', accountTypeId: 1, currency: hkd);

  Widget buildTile(CategoryType type) {
    return ProviderScope(
      overrides: [
        exchangeRatesProvider.overrideWith(
          (_) => Stream.value(const <String, int>{}),
        ),
        homeCurrenciesByCodeProvider.overrideWith(
          (_) => Stream.value(const {'HKD': hkd}),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TransactionTile(
            transaction: transaction,
            category: Category(
              id: 1,
              icon: 'savings',
              color: 0,
              type: type,
              l10nKey: 'category.income.other',
            ),
            account: account,
            locale: 'en_US',
            defaultCurrency: 'HKD',
            onTap: () {},
            onDuplicate: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('TT01: income amount uses onSurface, not the primary accent', (
    tester,
  ) async {
    await tester.pumpWidget(buildTile(CategoryType.income));
    await tester.pumpAndSettle();

    final amount = tester.widget<Text>(find.textContaining('+'));
    final colorScheme = Theme.of(tester.element(find.byType(Scaffold)))
        .colorScheme;
    expect(amount.style?.color, colorScheme.onSurface);
  });

  testWidgets('TT02: the more-actions icon sits as far from the right edge '
      'as the category avatar sits from the left', (tester) async {
    await tester.pumpWidget(buildTile(CategoryType.expense));
    await tester.pumpAndSettle();

    final row = tester.getRect(find.byType(ListTile));
    final avatar = tester.getRect(find.byType(CircleAvatar));
    final more = tester.getRect(find.byIcon(Icons.more_vert));
    expect(avatar.left - row.left, 16);
    expect(row.right - more.right, avatar.left - row.left);
    // The menu keeps a full 48dp touch target.
    final button = tester.getSize(
      find.ancestor(
        of: find.byIcon(Icons.more_vert),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.width, greaterThanOrEqualTo(48));
  });
}
