import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/slice_transaction_row.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _eur = Currency(code: 'EUR', decimals: 2, symbol: '€');
const _colors = AnalysisColors.light;

Transaction _tx({
  String? memo,
  Currency currency = _usd,
  int amountMinorUnits = 1250,
}) => Transaction(
  id: 7,
  amountMinorUnits: amountMinorUnits,
  currency: currency,
  categoryId: 1,
  accountId: 1,
  date: DateTime(2026, 5, 18),
  memo: memo,
  createdAt: DateTime(2026, 5, 18),
  updatedAt: DateTime(2026, 5, 18),
);

const _food = Category(
  id: 1,
  type: CategoryType.expense,
  l10nKey: 'category.food',
  icon: 'restaurant',
  color: 0,
);

const _salary = Category(
  id: 2,
  type: CategoryType.income,
  l10nKey: 'category.income.salary',
  icon: 'payments',
  color: 1,
);

const _cash = Account(
  id: 1,
  accountTypeId: 1,
  name: 'Cash',
  currency: _usd,
  openingBalanceMinorUnits: 0,
);

Widget _wrap(Widget child, {double textScale = 1}) => MaterialApp(
  theme: lightTheme,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: SlidableAutoCloseBehavior(child: SizedBox(width: 360, child: child)),
  ),
);

SliceTransactionRow _row({
  Transaction? transaction,
  Category? category = _food,
  Account? account = _cash,
  String? convertedAmount,
  VoidCallback? onTap,
  VoidCallback? onDelete,
}) => SliceTransactionRow(
  transaction: transaction ?? _tx(memo: 'Lunch'),
  category: category,
  account: account,
  locale: 'en',
  convertedAmount: convertedAmount,
  onTap: onTap ?? () {},
  onDelete: onDelete ?? () {},
);

Text _text(WidgetTester tester, String data) =>
    tester.widget<Text>(find.text(data));

void main() {
  group('title', () {
    testWidgets('shows the memo, 15/20 fg, one line with ellipsis', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_row()));

      final title = _text(tester, 'Lunch');
      expect(title.style!.fontSize, 15);
      expect(title.style!.height, 20 / 15);
      expect(title.style!.color, _colors.fg);
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      // The category name is no longer the title when a memo exists.
      expect(find.text('Food'), findsNothing);
    });

    testWidgets('falls back to the category name when the memo is null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_row(transaction: _tx())));
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('falls back to the category name when the memo is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_row(transaction: _tx(memo: ''))));
      expect(find.text('Food'), findsOneWidget);
    });
  });

  group('subtitle', () {
    testWidgets('is "MMM d · account", 13/18 fg2, one line with ellipsis', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_row()));

      final subtitle = _text(tester, 'May 18 · Cash');
      expect(subtitle.style!.fontSize, 13);
      expect(subtitle.style!.height, 18 / 13);
      expect(subtitle.style!.color, _colors.fg2);
      expect(subtitle.maxLines, 1);
      expect(subtitle.overflow, TextOverflow.ellipsis);
    });

    testWidgets(
      'appends the signed original amount on foreign rows, which show the '
      'converted amount',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _row(
              transaction: _tx(memo: 'Lunch', currency: _eur),
              convertedAmount: r'-$13.75',
            ),
          ),
        );

        expect(find.text('May 18 · Cash · -€12.50'), findsOneWidget);
        expect(find.text(r'-$13.75'), findsOneWidget);
        expect(find.text('-€12.50'), findsNothing);
        expect(find.text('Original amount'), findsNothing);
      },
    );
  });

  group('amount', () {
    testWidgets('expense: signed with "-", 15/20 w500 tabular expText', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_row()));

      final amount = _text(tester, r'-$12.50');
      expect(amount.style!.fontSize, 15);
      expect(amount.style!.height, 20 / 15);
      expect(amount.style!.fontWeight, FontWeight.w500);
      expect(amount.style!.color, _colors.expText);
      expect(
        amount.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(amount.maxLines, 1);
      expect(amount.softWrap, isFalse);
    });

    testWidgets('income: signed with "+", incText', (tester) async {
      await tester.pumpWidget(_wrap(_row(category: _salary)));

      final amount = _text(tester, r'+$12.50');
      expect(amount.style!.color, _colors.incText);
    });
  });

  group('layout', () {
    testWidgets('1px line top divider, padding 12 16, gap 12', (tester) async {
      await tester.pumpWidget(_wrap(_row()));

      final row = tester.getRect(find.byType(SliceTransactionRow));
      // 1 (divider) + 12 + 20 (title) + 2 + 18 (subtitle) + 12.
      expect(row.height, 65);

      final divider = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(Slidable),
              matching: find.byType(Container),
            )
            .first,
      );
      final border = (divider.decoration! as BoxDecoration).border! as Border;
      expect(border.top, BorderSide(color: _colors.line));
      expect(border.bottom, BorderSide.none);

      final title = tester.getRect(find.text('Lunch'));
      final subtitle = tester.getRect(find.text('May 18 · Cash'));
      final amount = tester.getRect(find.text(r'-$12.50'));
      expect(title.left - row.left, 16);
      expect(title.top - row.top, 1 + 12);
      expect(subtitle.top - title.bottom, 2);
      expect(row.right - amount.right, 16);
      expect(amount.center.dy, moreOrLessEquals(row.center.dy + 0.5));
      expect(amount.left - title.right, greaterThanOrEqualTo(12));
    });

    testWidgets('2x text scale: the row grows and the title stays one line', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _row(
            transaction: _tx(
              memo: 'A very long memo that cannot fit on one line at all',
            ),
          ),
          textScale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
      // 1 + 12 + 40 + 2 + 36 + 12.
      expect(tester.getSize(find.byType(SliceTransactionRow)).height, 103);
      expect(
        tester
            .getSize(
              find.text('A very long memo that cannot fit on one line at all'),
            )
            .height,
        40,
      );
      expect(tester.getSize(find.text(r'-$12.50')).height, 40);
    });
  });

  group('interaction', () {
    testWidgets('tap calls onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(_row(onTap: () => tapped++)));
      await tester.tap(find.text('Lunch'));
      expect(tapped, 1);
    });

    testWidgets('delete is action-only: a fling does not delete', (
      tester,
    ) async {
      var deleted = 0;
      await tester.pumpWidget(_wrap(_row(onDelete: () => deleted++)));

      final slidable = tester.widget<Slidable>(find.byType(Slidable));
      expect(slidable.endActionPane?.dismissible, isNull);
      await tester.drag(find.byType(Slidable), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(deleted, 0);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, 1);
    });
  });
}
