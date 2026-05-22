import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/features/analysis/search/widgets/transaction_search_row.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Transaction _tx() => Transaction(
  id: 1,
  amountMinorUnits: 1000,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  date: DateTime(2026, 5, 18),
  createdAt: DateTime(2026, 5, 18),
  updatedAt: DateTime(2026, 5, 18),
);

const _cat = Category(
  id: 1,
  type: CategoryType.expense,
  l10nKey: 'category.food',
  icon: 'restaurant',
  color: 0,
);

const _acc = Account(
  id: 1,
  accountTypeId: 1,
  name: 'Cash',
  currency: _usd,
  openingBalanceMinorUnits: 0,
);

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SlidableAutoCloseBehavior(child: child)),
);

void main() {
  testWidgets('actionOnly mode: dismissible pane NOT present', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      _wrap(
        TransactionSearchRow(
          transaction: _tx(),
          category: _cat,
          account: _acc,
          locale: 'en',
          deleteMode: TransactionSearchRowDeleteMode.actionOnly,
          onDelete: () => deleted = true,
        ),
      ),
    );
    final slidable = tester.widget<Slidable>(find.byType(Slidable));
    expect(slidable.endActionPane?.dismissible, isNull);
    // Fling left should NOT auto-delete in actionOnly mode.
    await tester.drag(find.byType(Slidable), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(deleted, isFalse);
  });

  testWidgets(
    'default (dismissible) mode keeps existing dismissible behavior',
    (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        _wrap(
          TransactionSearchRow(
            transaction: _tx(),
            category: _cat,
            account: _acc,
            locale: 'en',
            onDelete: () => deleted = true,
          ),
        ),
      );
      final slidable = tester.widget<Slidable>(find.byType(Slidable));
      expect(slidable.endActionPane?.dismissible, isNotNull);
    },
  );

  testWidgets(
    'convertedAmount renders as primary, original as labeled secondary',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          TransactionSearchRow(
            transaction: _tx(),
            category: _cat,
            account: _acc,
            locale: 'en',
            convertedAmount: r'$12.34',
            originalAmountLabel: 'Original amount',
          ),
        ),
      );
      expect(find.text(r'$12.34'), findsOneWidget);
      expect(find.text('Original amount'), findsOneWidget);
    },
  );
}
