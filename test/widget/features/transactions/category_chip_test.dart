// CategoryChip widget tests.
//
// Covers:
//   - A selected category shows its type next to its name, so an expense
//     and an income category with the same name can be told apart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/features/transactions/widgets/category_chip.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Widget _host(Category category) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: CategoryChip(category: category, onTap: () {}),
  ),
);

void main() {
  testWidgets('CC01: an expense category shows "name · Expense"', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Category(
          id: 1,
          icon: 'category',
          color: 0,
          type: CategoryType.expense,
          l10nKey: 'category.investment',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Investment · Expense'), findsOneWidget);
  });

  testWidgets('CC02: an income category shows "name · Income"', (tester) async {
    await tester.pumpWidget(
      _host(
        const Category(
          id: 2,
          icon: 'category',
          color: 0,
          type: CategoryType.income,
          l10nKey: 'category.income.investment',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Investment · Income'), findsOneWidget);
  });
}
