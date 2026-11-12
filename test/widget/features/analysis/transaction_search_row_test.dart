import 'package:material_ui/material_ui.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/core/l10n/app_localizations_delegates.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/features/analysis/search/views/transaction_search_row.dart';

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
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SlidableAutoCloseBehavior(child: child)),
);

void main() {
  testWidgets('swipe end pane is dismissible', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TransactionSearchRow(
          transaction: _tx(),
          category: _cat,
          account: _acc,
          locale: 'en',
          onTap: () {},
          onDelete: () {},
        ),
      ),
    );
    final slidable = tester.widget<Slidable>(find.byType(Slidable));
    expect(slidable.endActionPane?.dismissible, isNotNull);
  });
}
