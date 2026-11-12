import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/core/l10n/app_localizations_delegates.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/slice_transaction_row.dart';

import '../../../support/text_scale.dart';

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
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: textScaleBuilder(textScale),
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

RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(text);

/// A 360-wide phone at 1 dp per pixel (plan D2 tests on a phone width).
void _usePhoneWidth(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// [row] at its width in the app: ChartsSection pads 16 a side and the
/// transactions card's 1 px border takes 1 more, so on a 360 phone the
/// row is 326 wide.
Widget _inCard(Widget row) =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 17), child: row);

/// Ink features (ripples, highlights) on the Material that [finder] paints
/// its ink on.
List<InkFeature> _ink(WidgetTester tester, Finder finder) =>
    ((Material.of(tester.element(finder)) as dynamic).debugInkFeatures
        as List<InkFeature>?) ??
    const [];

const _longMemo = 'A very long memo that cannot fit on one line at all';

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

        // One line: "date · account", then " · <booked>" right after it.
        final meta = tester.getRect(find.text('May 18 · Cash'));
        final booked = tester.getRect(find.text(' · -€12.50'));
        expect(booked.left, moreOrLessEquals(meta.right));
        expect(booked.top, meta.top);
        expect(
          booked.size,
          tester.renderObject<RenderBox>(find.text(' · -€12.50')).size,
        );
        final style = _text(tester, ' · -€12.50').style!;
        expect(style.fontSize, 13);
        expect(style.height, 18 / 13);
        expect(style.color, _colors.fg2);
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

  group('long amounts (D2)', () {
    testWidgets('1x: the memo ellipsizes first and the amount stays 1:1', (
      tester,
    ) async {
      _usePhoneWidth(tester);
      await tester.pumpWidget(
        _wrap(
          _inCard(
            _row(
              transaction: _tx(memo: _longMemo, amountMinorUnits: 123456789012),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_paragraph(tester, find.text(_longMemo)).didExceedMaxLines, true);
      final amount = find.text(r'-$1,234,567,890.12');
      final natural = tester.renderObject<RenderBox>(amount).size;
      expect(tester.getSize(amount), natural);
      expect(
        tester.getRect(amount).left -
            tester.getRect(find.text(_longMemo)).right,
        greaterThanOrEqualTo(12),
      );
    });

    testWidgets(
      '360 phone at 2x: a long amount scales down to fit, never cut off',
      (tester) async {
        _usePhoneWidth(tester);
        await tester.pumpWidget(
          _wrap(
            _inCard(
              _row(
                transaction: _tx(
                  memo: _longMemo,
                  amountMinorUnits: 123456789012,
                ),
              ),
            ),
            textScale: 2,
          ),
        );

        expect(tester.takeException(), isNull);
        final amount = find.text(r'-$1,234,567,890.12');
        expect(amount, findsOneWidget);
        expect(_paragraph(tester, amount).didExceedMaxLines, isFalse);
        final row = tester.getRect(find.byType(SliceTransactionRow));
        final rendered = tester.getRect(amount);
        expect(rendered.left, greaterThanOrEqualTo(row.left + 16));
        expect(rendered.right, lessThanOrEqualTo(row.right - 16 + 0.01));
        // Shrunk as a whole, not clipped: smaller than its laid-out size.
        final natural = tester.renderObject<RenderBox>(amount).size;
        expect(rendered.width, lessThan(natural.width));
        expect(
          rendered.width / rendered.height,
          moreOrLessEquals(natural.width / natural.height),
        );
      },
    );

    testWidgets(
      '360 phone at 2x: a long booked amount in the subtitle is never cut '
      'off; "date · account" ellipsizes first',
      (tester) async {
        _usePhoneWidth(tester);
        await tester.pumpWidget(
          _wrap(
            _inCard(
              _row(
                transaction: _tx(
                  memo: 'Lunch',
                  currency: _eur,
                  amountMinorUnits: 123456789012,
                ),
                account: _cash.copyWith(name: 'Everyday spending account'),
                convertedAmount: r'-$1.00',
              ),
            ),
            textScale: 2,
          ),
        );

        expect(tester.takeException(), isNull);
        final booked = find.textContaining('-€1,234,567,890.12');
        expect(booked, findsOneWidget);
        expect(_paragraph(tester, booked).didExceedMaxLines, isFalse);
        final meta = find.textContaining('May 18 · Everyday');
        expect(meta, findsOneWidget);
        expect(_paragraph(tester, meta).didExceedMaxLines, isTrue);
        final row = tester.getRect(find.byType(SliceTransactionRow));
        final title = tester.getRect(find.text('Lunch'));
        final amount = tester.getRect(find.text(r'-$1.00'));
        final rendered = tester.getRect(booked);
        expect(rendered.left, greaterThanOrEqualTo(title.left));
        expect(rendered.right, lessThanOrEqualTo(amount.left - 12 + 0.01));
        expect(rendered.right, lessThanOrEqualTo(row.right - 16));
      },
    );
  });

  group('interaction', () {
    testWidgets('tap calls onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(_row(onTap: () => tapped++)));
      await tester.tap(find.text('Lunch'));
      expect(tapped, 1);
    });

    testWidgets(
      'reports itself as an enabled, focusable button with a tap action '
      '(D16: semantics unchanged from the ListTile row)',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_wrap(_row()));

        expect(
          tester.getSemantics(find.text('Lunch')),
          isSemantics(
            isButton: true,
            hasTapAction: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: true,
            // ListTile reports an always-false selected state.
            hasSelectedState: true,
            isSelected: false,
          ),
        );
        handle.dispose();
      },
    );

    testWidgets('press shows an ink ripple clipped to the row (D16)', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_row()));

      final row = tester.getRect(find.byType(SliceTransactionRow));
      final inkWell = find.ancestor(
        of: find.text('Lunch'),
        matching: find.byType(InkWell),
      );
      expect(inkWell, findsOneWidget);
      // The row is square-cornered: the ink fills it below the divider.
      expect(tester.getRect(inkWell), Rect.fromLTRB(0, 1, 360, row.height));
      final widget = tester.widget<InkWell>(inkWell);
      expect(widget.borderRadius, isNull);
      expect(widget.customBorder, isNull);
      expect(widget.containedInkWell, isTrue);

      expect(_ink(tester, find.text('Lunch')), isEmpty);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Lunch')),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(_ink(tester, find.text('Lunch')), isNotEmpty);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('takes keyboard focus; Enter calls onTap (D16)', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(_row(onTap: () => tapped++)));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        Focus.of(tester.element(find.text('Lunch'))).hasPrimaryFocus,
        true,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
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

  // The test font's glyphs are 1em wide, about twice Roboto's, so a scale
  // measured with it says nothing about a phone. Measure with the font
  // phones use. Fonts stay loaded for the rest of the file, so keep this
  // group last.
  group('readable amounts (D2, Roboto)', () {
    setUpAll(() async {
      final root = Platform.environment['FLUTTER_ROOT']!;
      for (final face in ['Regular', 'Medium']) {
        final bytes = File(
          '$root/bin/cache/artifacts/material_fonts/Roboto-$face.ttf',
        ).readAsBytesSync();
        await (FontLoader(
          'Roboto',
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    });

    /// How much [text] is scaled down from its laid-out width.
    double scaleOf(WidgetTester tester, Finder text) =>
        tester.getRect(text).width /
        tester.renderObject<RenderBox>(text).size.width;

    for (final converted in [
      r'-NT$3,125,000,000.00',
      '-IDR 12,345,678,901,234.00',
    ]) {
      testWidgets(
        '360 phone at 1x: a long converted amount ($converted) stays 1:1 '
        'while "date · account" ellipsizes first',
        (tester) async {
          _usePhoneWidth(tester);
          await tester.pumpWidget(
            _wrap(
              _inCard(
                _row(
                  transaction: _tx(memo: 'Lunch', amountMinorUnits: 1234),
                  convertedAmount: converted,
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          final convertedText = find.text(converted);
          final bookedText = find.text(r' · -$12.34');
          final metaText = find.text('May 18 · Cash');
          expect(scaleOf(tester, convertedText), moreOrLessEquals(1));
          expect(scaleOf(tester, bookedText), moreOrLessEquals(1));
          expect(_paragraph(tester, metaText).didExceedMaxLines, isTrue);
          final row = tester.getRect(find.byType(SliceTransactionRow));
          final convertedRect = tester.getRect(convertedText);
          expect(convertedRect.right, moreOrLessEquals(row.right - 16));
          expect(
            tester.getRect(bookedText).right,
            lessThanOrEqualTo(convertedRect.left - 12 + 0.01),
          );
        },
      );
    }

    testWidgets(
      '360 phone at 2x: with both amounts long, the converted amount and the '
      'booked amount in the subtitle both stay legible',
      (tester) async {
        _usePhoneWidth(tester);
        await tester.pumpWidget(
          _wrap(
            _inCard(
              _row(
                transaction: _tx(
                  memo: 'Lunch',
                  currency: _eur,
                  amountMinorUnits: 123456789012,
                ),
                convertedAmount: r'-$1,234,567,890.12',
              ),
            ),
            textScale: 2,
          ),
        );

        expect(tester.takeException(), isNull);
        final row = tester.getRect(find.byType(SliceTransactionRow));
        final convertedText = find.text(r'-$1,234,567,890.12');
        final bookedText = find.textContaining('-€1,234,567,890.12');
        final converted = tester.getRect(convertedText);
        final booked = tester.getRect(bookedText);
        expect(booked.left, greaterThanOrEqualTo(row.left + 16));
        expect(booked.right, lessThanOrEqualTo(converted.left - 12 + 0.01));
        expect(converted.right, lessThanOrEqualTo(row.right - 16 + 0.01));
        expect(row.width, 326);
        // Neither amount is scaled to nothing to make room for the other:
        // on the real row they render at about 0.53 and 0.58. A longer
        // amount, or a currency code in place of a symbol, can go lower.
        expect(scaleOf(tester, convertedText), greaterThanOrEqualTo(0.5));
        expect(scaleOf(tester, bookedText), greaterThanOrEqualTo(0.5));
        expect(_paragraph(tester, convertedText).didExceedMaxLines, isFalse);
        expect(_paragraph(tester, bookedText).didExceedMaxLines, isFalse);
      },
    );
  });
}
