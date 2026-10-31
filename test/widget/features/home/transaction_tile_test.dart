// TransactionTile row content and amount styling — Home.
//
// Income amounts render in the same neutral `onSurface` colour as
// expenses; the `+`/`-` sign alone distinguishes them. The title is the
// memo, falling back to the category name, with no subtitle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/features/home/home_providers.dart';
import 'package:ledgerly/features/home/widgets/transaction_tile.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

void main() {
  const hkd = Currency(code: 'HKD', decimals: 2, symbol: r'HK$');

  Transaction transaction({String? memo}) => Transaction(
    id: 1,
    amountMinorUnits: 69,
    currency: hkd,
    categoryId: 1,
    accountId: 1,
    memo: memo,
    date: DateTime(2026, 10, 30),
    createdAt: DateTime(2026, 10, 30),
    updatedAt: DateTime(2026, 10, 30),
  );

  Widget buildTile(CategoryType type, {String? memo}) {
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
            transaction: transaction(memo: memo),
            category: Category(
              id: 1,
              icon: 'savings',
              color: 0,
              type: type,
              customName: 'Snacks',
            ),
            locale: 'en_US',
            defaultCurrency: 'HKD',
            onTap: () {},
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

  testWidgets('TT02: the amount sits as far from the right edge as the '
      'category avatar sits from the left', (tester) async {
    await tester.pumpWidget(buildTile(CategoryType.expense));
    await tester.pumpAndSettle();

    final row = tester.getRect(find.byType(InkWell));
    final avatar = tester.getRect(find.byType(CircleAvatar));
    final amount = tester.getRect(find.textContaining('-'));
    expect(avatar.left - row.left, 16);
    expect(row.right - amount.right, avatar.left - row.left);
  });

  testWidgets('TT03: a memo becomes the title and hides the category name', (
    tester,
  ) async {
    await tester.pumpWidget(buildTile(CategoryType.expense, memo: 'Lunch'));
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Snacks'), findsNothing);
  });

  testWidgets('TT04: without a memo the category name is the title', (
    tester,
  ) async {
    await tester.pumpWidget(buildTile(CategoryType.expense, memo: ''));
    await tester.pumpAndSettle();

    expect(find.text('Snacks'), findsOneWidget);
  });

  testWidgets('TT05: the row has no overflow menu', (tester) async {
    await tester.pumpWidget(buildTile(CategoryType.expense));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byWidgetPredicate((w) => w is PopupMenuButton), findsNothing);
  });

  testWidgets('TT06: a whitespace-only memo falls back to the category name', (
    tester,
  ) async {
    await tester.pumpWidget(buildTile(CategoryType.expense, memo: ' \n '));
    await tester.pumpAndSettle();

    expect(find.text('Snacks'), findsOneWidget);
  });
}
