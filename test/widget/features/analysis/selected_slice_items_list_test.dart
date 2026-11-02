import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/bootstrap.dart' show noProviderRetry;
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/utils/color_palette.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/selected_slice_items_list.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/slice_transaction_row.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class _MockRepo extends Mock implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _eur = Currency(code: 'EUR', decimals: 2, symbol: '€');
const _colors = AnalysisColors.light;

Transaction _tx(int id, {Currency currency = _usd, String? memo}) =>
    Transaction(
      id: id,
      amountMinorUnits: 100 * id,
      currency: currency,
      categoryId: 1,
      accountId: 1,
      date: DateTime(2026, 5, 18),
      memo: memo,
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

ChartSlice _slice(SelectedSlice key) => ChartSlice(
  label: 'category.food',
  currencyCode: 'USD',
  totalMinorUnits: 1000,
  colorIndex: 0,
  iconKey: 'restaurant',
  selectionKey: key,
);

void _stubRows(_MockRepo repo, Stream<List<Transaction>> Function() rows) {
  when(
    () => repo.watchTransactionsForSliceInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
      categoryId: any(named: 'categoryId'),
      accountId: any(named: 'accountId'),
      currencyCode: any(named: 'currencyCode'),
    ),
  ).thenAnswer((_) => rows());
}

@Dependencies([
  ChartsSelectionController,
  SliceDrilldownController,
  analysisCategoriesById,
  analysisAccountsById,
  chartsCurrenciesByCode,
  chartsFxStatus,
])
Widget _harness({
  required _MockRepo repo,
  required ChartSlice slice,
  ValueListenable<ChartSlice>? sliceListenable,
  SelectedSlice? activeSelection,
  Map<String, Currency> currenciesByCode = const {'USD': _usd},
  ChartsFxStatus fxStatus = const ChartsFxStatus(
    defaultCurrencyCode: 'USD',
    rates: {},
  ),
  double textScale = 1,
  bool withEditRoute = false,
  ChartDimension? dimension,
}) {
  final container = ProviderContainer(
    retry: noProviderRetry,
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repo),
      analysisCategoriesByIdProvider.overrideWith(
        (ref) => Stream.value({
          1: const Category(
            id: 1,
            type: CategoryType.expense,
            l10nKey: 'category.food',
            icon: 'restaurant',
            color: 0,
          ),
        }),
      ),
      analysisAccountsByIdProvider.overrideWith(
        (ref) => Stream.value(const <int, Account>{
          1: Account(
            id: 1,
            accountTypeId: 1,
            name: 'Cash',
            currency: _usd,
            openingBalanceMinorUnits: 0,
          ),
        }),
      ),
      chartsCurrenciesByCodeProvider.overrideWith(
        (ref) => Stream.value(currenciesByCode),
      ),
      chartsFxStatusProvider.overrideWith((ref) => Stream.value(fxStatus)),
    ],
  );
  addTearDown(container.dispose);
  if (dimension != null) {
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setDimension(dimension);
  }
  if (activeSelection != null) {
    container
        .read(chartsSelectionControllerProvider.notifier)
        .toggleSlice(activeSelection);
  }
  final body = Scaffold(
    body: SingleChildScrollView(
      child: sliceListenable == null
          ? SelectedSliceItemsList(slice: slice, locale: 'en')
          : ValueListenableBuilder<ChartSlice>(
              valueListenable: sliceListenable,
              builder: (_, current, _) =>
                  SelectedSliceItemsList(slice: current, locale: 'en'),
            ),
    ),
  );
  const delegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  Widget scaled(BuildContext context, Widget? child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  );
  return UncontrolledProviderScope(
    container: container,
    child: withEditRoute
        ? MaterialApp.router(
            theme: lightTheme,
            localizationsDelegates: delegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: scaled,
            routerConfig: GoRouter(
              routes: [
                GoRoute(path: '/', builder: (_, _) => body),
                GoRoute(
                  path: '/home/edit/:id',
                  builder: (_, state) =>
                      Text('edit ${state.pathParameters['id']}'),
                ),
              ],
            ),
          )
        : MaterialApp(
            theme: lightTheme,
            localizationsDelegates: delegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: scaled,
            home: body,
          ),
  );
}

/// Materials inside the list; the outermost one is the card surface.
@Dependencies([
  ChartsSelectionController,
  SliceDrilldownController,
  analysisCategoriesById,
  analysisAccountsById,
  chartsCurrenciesByCode,
  chartsFxStatus,
])
Finder get _materials => find.descendant(
  of: find.byType(SelectedSliceItemsList),
  matching: find.byType(Material),
);

@Dependencies([
  ChartsSelectionController,
  SliceDrilldownController,
  analysisCategoriesById,
  analysisAccountsById,
  chartsCurrenciesByCode,
  chartsFxStatus,
])
Finder get _card => _materials.first;

Finder get _dot => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
      (w.decoration! as BoxDecoration).color == colorForIndex(0),
);

Text _text(WidgetTester tester, String data) =>
    tester.widget<Text>(find.text(data));

/// Ink features (ripples, highlights) on the Material that [finder] paints
/// its ink on.
List<InkFeature> _ink(WidgetTester tester, Finder finder) =>
    ((Material.of(tester.element(finder)) as dynamic).debugInkFeatures
        as List<InkFeature>?) ??
    const [];

/// Presses [finder] and expects a ripple on its own Material, whose shape
/// is the element's visual shape (D16).
Future<void> _expectRipple(
  WidgetTester tester,
  Finder finder, {
  required ShapeBorder shape,
}) async {
  final material = tester.widget<Material>(
    find.ancestor(of: finder, matching: find.byType(Material)).first,
  );
  expect(material.shape, shape);
  expect(_ink(tester, finder), isEmpty);
  final gesture = await tester.startGesture(tester.getCenter(finder));
  await tester.pump(const Duration(milliseconds: 200));
  expect(_ink(tester, finder), isNotEmpty);
  // Cancel rather than lift, so the press does not also activate it.
  await gesture.cancel();
  await tester.pump(const Duration(seconds: 1));
}

/// Focuses the element around [finder] from the keyboard side, then
/// activates it with Enter (D16).
Future<void> _focusAndActivate(WidgetTester tester, Finder finder) async {
  final node = Focus.of(tester.element(finder));
  expect(node.canRequestFocus, isTrue);
  node.requestFocus();
  await tester.pump();
  expect(node.hasPrimaryFocus, isTrue);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump();
}

@Dependencies([
  ChartsSelectionController,
  SliceDrilldownController,
  analysisCategoriesById,
  analysisAccountsById,
  chartsCurrenciesByCode,
  chartsFxStatus,
])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(const SelectedSlice.category(1));
  });

  testWidgets('returns SizedBox.shrink when no selection', (tester) async {
    final repo = _MockRepo();
    await tester.pumpWidget(
      _harness(repo: repo, slice: _slice(const SelectedSlice.category(1))),
    );
    await tester.pump();
    expect(find.text('Food'), findsNothing);
    expect(_materials, findsNothing);
  });

  group('card', () {
    testWidgets('radius 20, card fill, 1px line border, 12 gap above', (
      tester,
    ) async {
      final repo = _MockRepo();
      _stubRows(repo, () => Stream.value([_tx(1, memo: 'Lunch')]));
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(_card);
      expect(material.color, _colors.card);
      expect(material.elevation, 0);
      expect(
        material.shape,
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _colors.line),
        ),
      );

      final list = tester.getRect(find.byType(SelectedSliceItemsList));
      final card = tester.getRect(_card);
      expect(card.top - list.top, 12);
      expect(card.left, list.left);
      expect(card.right, list.right);
      // 1px border + 8 padding below the last row.
      final row = tester.getRect(find.byType(SliceTransactionRow));
      expect(card.bottom - row.bottom, 1 + 8);
      expect(row.left, card.left + 1);
      expect(row.right, card.right - 1);
    });

    testWidgets('loading spinner sits inside the card', (tester) async {
      final repo = _MockRepo();
      final rows = StreamController<List<Transaction>>();
      addTearDown(rows.close);
      _stubRows(repo, () => rows.stream);
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: _card,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
    });

    testWidgets('error message sits inside the card', (tester) async {
      final repo = _MockRepo();
      _stubRows(repo, () => Stream.error(StateError('boom')));
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.descendant(
          of: _card,
          matching: find.text('Something went wrong while searching'),
        ),
        findsOneWidget,
      );
    });
  });

  group('header', () {
    testWidgets('12x12 slice-colour dot, title 16/24 w500 fg, subtitle '
        '"N transactions · total" 13/18 fg2 tabular', (tester) async {
      final repo = _MockRepo();
      _stubRows(
        repo,
        () => Stream.value([_tx(1, memo: 'Lunch'), _tx(2, memo: 'Dinner')]),
      );
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(_dot), const Size(12, 12));

      final title = _text(tester, 'Food');
      expect(title.style!.fontSize, 16);
      expect(title.style!.height, 24 / 16);
      expect(title.style!.fontWeight, FontWeight.w500);
      expect(title.style!.color, _colors.fg);

      for (final piece in ['2 transactions · ', r'$10.00']) {
        final subtitle = _text(tester, piece);
        expect(subtitle.style!.fontSize, 13);
        expect(subtitle.style!.height, 18 / 13);
        expect(subtitle.style!.color, _colors.fg2);
        expect(
          subtitle.style!.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
      // One line, read as one string: the total follows the count.
      final count = tester.getRect(find.text('2 transactions · '));
      final total = tester.getRect(find.text(r'$10.00'));
      expect(total.left, moreOrLessEquals(count.right));
      expect(total.top, count.top);
      expect(
        total.size,
        tester.renderObject<RenderBox>(find.text(r'$10.00')).size,
      );

      // Padding 8 8 8 16 inside the 1px border + 8 card padding; gap 12.
      final card = tester.getRect(_card);
      final dot = tester.getRect(_dot);
      final close = tester.getRect(find.byTooltip('Close transactions'));
      final titleRect = tester.getRect(find.text('Food'));
      expect(dot.left - card.left, 1 + 16);
      expect(titleRect.left - dot.right, 12);
      expect(close.top - card.top, 1 + 8 + 8);
      expect(card.right - close.right, 1 + 8);
      expect(dot.center.dy, close.center.dy);
      expect(
        tester.getRect(find.text('2 transactions · ')).top - titleRect.bottom,
        2,
      );
      // Header bottom padding 8, then the first row's divider.
      final firstRow = tester.getRect(find.byType(SliceTransactionRow).first);
      expect(firstRow.top - close.bottom, 8);
    });

    testWidgets('close button: 48x48, close icon 20 fg2, clears the slice', (
      tester,
    ) async {
      final repo = _MockRepo();
      _stubRows(repo, () => Stream.value([_tx(1, memo: 'Lunch')]));
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();

      final close = find.byTooltip('Close transactions');
      expect(tester.getSize(close), const Size(48, 48));
      final icon = tester.widget<Icon>(
        find.descendant(of: close, matching: find.byIcon(Icons.close)),
      );
      expect(icon.size, 20);
      final iconColor = tester
          .widget<RichText>(
            find.descendant(of: close, matching: find.byType(RichText)),
          )
          .text
          .style!
          .color;
      expect(iconColor, _colors.fg2);

      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(
        ProviderScope.containerOf(
          tester.element(find.byType(SelectedSliceItemsList)),
        ).read(chartsSelectionControllerProvider).selectedSlice,
        isNull,
      );
      expect(_materials, findsNothing);
    });

    testWidgets('close button: ripple clipped to its 48 circle (D16)', (
      tester,
    ) async {
      final repo = _MockRepo();
      _stubRows(repo, () => Stream.value([_tx(1, memo: 'Lunch')]));
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();

      await _expectRipple(
        tester,
        find.byIcon(Icons.close),
        shape: const StadiumBorder(),
      );
    });

    testWidgets('close button takes keyboard focus; Enter clears the slice '
        '(D16)', (tester) async {
      final repo = _MockRepo();
      _stubRows(repo, () => Stream.value([_tx(1, memo: 'Lunch')]));
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SelectedSliceItemsList)),
      );
      await _focusAndActivate(tester, find.byIcon(Icons.close));
      expect(
        container.read(chartsSelectionControllerProvider).selectedSlice,
        isNull,
      );
    });

    testWidgets(
      'stale-rate notice is one more 13/18 fg2 line under the subtitle',
      (tester) async {
        final repo = _MockRepo();
        _stubRows(repo, () => Stream.value([_tx(1, currency: _eur)]));

        await tester.pumpWidget(
          _harness(
            repo: repo,
            slice: _slice(const SelectedSlice.category(1))
                .copyWith(currencyCode: 'USD', totalMinorUnits: 110),
            activeSelection: const SelectedSlice.category(1),
            currenciesByCode: const {'USD': _usd, 'EUR': _eur},
            fxStatus: ChartsFxStatus(
              defaultCurrencyCode: 'USD',
              rates: {
                'EUR→USD': ExchangeRateMetadata(
                  rateScaledE9: 1100000000,
                  fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
                ),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final stale = _text(tester, 'Using last known exchange rates');
        expect(stale.style!.fontSize, 13);
        expect(stale.style!.height, 18 / 13);
        expect(stale.style!.color, _colors.fg2);
        expect(
          tester.getRect(find.text('Using last known exchange rates')).top -
              tester.getRect(find.text('1 transaction · ')).bottom,
          2,
        );
      },
    );

    testWidgets(
      'stale-rate notice keys off the displayed converted pair, not an '
      'unrelated fresh pair',
      (tester) async {
        final repo = _MockRepo();
        _stubRows(repo, () => Stream.value([_tx(1, currency: _eur)]));

        await tester.pumpWidget(
          _harness(
            repo: repo,
            slice: _slice(const SelectedSlice.category(1))
                .copyWith(currencyCode: 'USD', totalMinorUnits: 110),
            activeSelection: const SelectedSlice.category(1),
            currenciesByCode: const {'USD': _usd, 'EUR': _eur},
            fxStatus: ChartsFxStatus(
              defaultCurrencyCode: 'USD',
              rates: {
                'EUR→USD': ExchangeRateMetadata(
                  rateScaledE9: 1100000000,
                  fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
                ),
                'JPY→USD': ExchangeRateMetadata(
                  rateScaledE9: 7000000,
                  fetchedAt: DateTime.now(),
                ),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Using last known exchange rates'), findsOneWidget);
        // The converted amount is the row amount; the booked amount moves
        // into the subtitle instead of an "Original amount" label.
        expect(find.text(r'-$1.10'), findsOneWidget);
        expect(find.text('May 18 · Cash'), findsOneWidget);
        expect(find.text(' · -€1.00'), findsOneWidget);
        expect(find.text('Original amount'), findsNothing);
      },
    );

    testWidgets('2x text scale: header text grows, close stays 48x48', (
      tester,
    ) async {
      final repo = _MockRepo();
      _stubRows(repo, () => Stream.value([_tx(1, memo: 'Lunch')]));
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.text('Food')).height, 48);
      expect(tester.getSize(find.text('1 transaction · ')).height, 36);
      expect(tester.getSize(find.text(r'$10.00')).height, 36);
      expect(
        tester.getSize(find.byTooltip('Close transactions')),
        const Size(48, 48),
      );
      expect(tester.getSize(_dot), const Size(12, 12));
    });
  });

  group('long header total (D2)', () {
    testWidgets(
      '360 phone at 2x: a long total stays on one line and scales down to '
      'fit, never cut off',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = _MockRepo();
        _stubRows(repo, () => Stream.value([_tx(1, memo: 'Lunch')]));
        await tester.pumpWidget(
          _harness(
            repo: repo,
            slice: _slice(const SelectedSlice.category(1))
                .copyWith(totalMinorUnits: 123456789012),
            activeSelection: const SelectedSlice.category(1),
            textScale: 2,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final total = find.textContaining(r'$1,234,567,890.12');
        expect(total, findsOneWidget);
        // Laid out on one 36-high line (18 x 2), not broken mid-number.
        expect(tester.renderObject<RenderBox>(total).size.height, 36);
        final rendered = tester.getRect(total);
        final title = tester.getRect(find.text('Food'));
        final close = tester.getRect(find.byTooltip('Close transactions'));
        expect(rendered.left, greaterThanOrEqualTo(title.left));
        expect(rendered.right, lessThanOrEqualTo(close.left - 12 + 0.01));
      },
    );
  });

  group('bridge button (AC 7)', () {
    const account = SelectedSlice.account(1);
    ChartSlice accountSlice() => _slice(account).copyWith(label: 'Cash');
    Finder bridge() => find.byKey(const ValueKey('sliceBridgeButton'));

    @Dependencies([
      ChartsSelectionController,
      SliceDrilldownController,
      analysisCategoriesById,
      analysisAccountsById,
      chartsCurrenciesByCode,
      chartsFxStatus,
    ])
    Future<ProviderContainer> pumpAccount(
      WidgetTester tester, {
      double textScale = 1,
    }) async {
      final repo = _MockRepo();
      _stubRows(repo, () => Stream.value([_tx(1, memo: 'Lunch')]));
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: accountSlice(),
          activeSelection: account,
          dimension: ChartDimension.account,
          textScale: textScale,
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(SelectedSliceItemsList)),
      );
    }

    testWidgets('an account drill-down shows "See categories in <Account>" '
        'below the header', (tester) async {
      await pumpAccount(tester);

      expect(find.text('See categories in Cash'), findsOneWidget);
      final label = _text(tester, 'See categories in Cash');
      expect(label.style?.fontSize, 14);
      expect(label.style?.fontWeight, FontWeight.w500);
      expect(label.style?.letterSpacing, 0);
      expect(label.style?.color, _colors.fg);
      final chevron = find.descendant(
        of: bridge(),
        matching: find.byIcon(Icons.chevron_right),
      );
      expect(tester.getSize(chevron), const Size(16, 16));

      final button = tester.getRect(bridge());
      final card = tester.getRect(_card);
      final title = tester.getRect(find.text('Cash').first);
      // Padding 0 16 8: 16 in from the card's inner edge (1 px border),
      // under the header row, 8 above the first row's divider.
      expect(button.left, card.left + 1 + 16);
      expect(button.height, 44);
      expect(button.top, greaterThan(title.bottom));
      final row = tester.getRect(find.byType(SliceTransactionRow));
      expect(row.top - button.bottom, 8);
      // Padding 0 12 0 14 inside the 1 px border, gap 6.
      final text = tester.getRect(find.text('See categories in Cash'));
      expect(text.left - button.left, 15);
      expect(button.right - tester.getRect(chevron).right, 13);
      expect(tester.getRect(chevron).left - text.right, 6);
      expect(text.center.dy, button.center.dy);
    });

    testWidgets('outlined pill: radius 22, 1 px outline, transparent', (
      tester,
    ) async {
      await pumpAccount(tester);

      final material = tester.widget<Material>(bridge());
      expect(material.color!.a, 0);
      expect(
        material.shape,
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: _colors.outline),
        ),
      );
    });

    testWidgets('tapping it filters by the account, switches to Category '
        'and clears the slice', (tester) async {
      final container = await pumpAccount(tester);

      await tester.tap(bridge());
      await tester.pump();

      final selection = container.read(chartsSelectionControllerProvider);
      expect(selection.accountFilterId, 1);
      expect(selection.dimension, ChartDimension.category);
      expect(selection.selectedSlice, isNull);
    });

    testWidgets('ripple clipped to the pill; keyboard focus and Enter '
        '(D16)', (tester) async {
      final container = await pumpAccount(tester);
      final text = find.text('See categories in Cash');

      await _expectRipple(
        tester,
        text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: _colors.outline),
        ),
      );
      await _focusAndActivate(tester, text);

      expect(
        container.read(chartsSelectionControllerProvider).accountFilterId,
        1,
      );
    });

    testWidgets('reads as a button', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpAccount(tester);

      expect(
        tester.getSemantics(find.text('See categories in Cash')),
        isSemantics(
          label: 'See categories in Cash',
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('2× text scale: the label doubles inside the 44 minimum and '
        'ellipsizes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpAccount(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      // The ambient 20 px line, doubled; the pill keeps its 44 minimum.
      expect(tester.getSize(find.text('See categories in Cash')).height, 40);
      final button = tester.getRect(bridge());
      expect(button.height, greaterThanOrEqualTo(44));
      expect(button.right, lessThanOrEqualTo(360 - 1 - 16));
      expect(
        _text(tester, 'See categories in Cash').overflow,
        TextOverflow.ellipsis,
      );
    });

    testWidgets('a category drill-down has no bridge', (tester) async {
      final repo = _MockRepo();
      _stubRows(repo, () => Stream.value([_tx(1)]));
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();

      expect(bridge(), findsNothing);
      expect(find.textContaining('See categories in'), findsNothing);
    });
  });

  group('rows', () {
    testWidgets('one SliceTransactionRow per transaction, with account', (
      tester,
    ) async {
      final repo = _MockRepo();
      _stubRows(repo, () => Stream.value([_tx(1), _tx(2)]));

      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();
      // header label (1) + memo-less rows fall back to the category (2).
      expect(find.text('Food'), findsNWidgets(3));
      expect(find.byType(SliceTransactionRow), findsNWidgets(2));
      expect(find.byType(ListTile), findsNothing);
      expect(find.text('May 18 · Cash'), findsNWidgets(2));
    });

    testWidgets('tapping a row opens /home/edit/<id>', (tester) async {
      final repo = _MockRepo();
      _stubRows(repo, () => Stream.value([_tx(3, memo: 'Lunch')]));
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
          withEditRoute: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lunch'));
      await tester.pumpAndSettle();
      expect(find.text('edit 3'), findsOneWidget);
    });

    testWidgets(
      'pending delete dims the row, keeps it visible and shows snackbar undo',
      (tester) async {
        final repo = _MockRepo();
        _stubRows(repo, () => Stream.value([_tx(1)]));
        when(() => repo.delete(any())).thenAnswer((_) async => true);

        await tester.pumpWidget(
          _harness(
            repo: repo,
            slice: _slice(const SelectedSlice.category(1)),
            activeSelection: const SelectedSlice.category(1),
          ),
        );
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Slidable), const Offset(-300, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pump();

        expect(find.text('Transaction deleted'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
        expect(find.byType(SliceTransactionRow), findsOneWidget);
        final opacity = tester.widget<Opacity>(
          find
              .ancestor(
                of: find.byType(SliceTransactionRow),
                matching: find.byType(Opacity),
              )
              .first,
        );
        expect(opacity.opacity, 0.55);
        final ignore = tester.widget<IgnorePointer>(
          find
              .ancestor(
                of: find.byType(SliceTransactionRow),
                matching: find.byType(IgnorePointer),
              )
              .first,
        );
        expect(ignore.ignoring, isTrue);

        // Let the snackbar finish sliding in before tapping its action.
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text('Undo'));
        await tester.pump();
        expect(
          tester
              .widget<Opacity>(
                find
                    .ancestor(
                      of: find.byType(SliceTransactionRow),
                      matching: find.byType(Opacity),
                    )
                    .first,
              )
              .opacity,
          1,
        );
        verifyNever(() => repo.delete(any()));

        // Drain the kUndoWindow timer so it doesn't leak past teardown.
        await tester.pump(const Duration(seconds: 5));
      },
    );
  });

  group('empty', () {
    testWidgets('1px top divider, padding 16, centred 14/20 fg2', (
      tester,
    ) async {
      final repo = _MockRepo();
      _stubRows(repo, () => Stream.value(const <Transaction>[]));

      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();

      final text = _text(tester, 'No transactions in this period');
      expect(text.style!.fontSize, 14);
      expect(text.style!.height, 20 / 14);
      expect(text.style!.color, _colors.fg2);
      expect(text.textAlign, TextAlign.center);

      final divider = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('No transactions in this period'),
              matching: find.byType(Container),
            )
            .first,
      );
      final border = (divider.decoration! as BoxDecoration).border! as Border;
      expect(border.top, BorderSide(color: _colors.line));

      final block = tester.getRect(find.byWidget(divider));
      final textRect = tester.getRect(
        find.text('No transactions in this period'),
      );
      expect(block.height, 1 + 16 + 20 + 16);
      expect(textRect.top - block.top, 1 + 16);
      expect(textRect.center.dx, block.center.dx);
    });
  });

  group('show more', () {
    testWidgets('caps rendered rows at 50 behind a Show more button', (
      tester,
    ) async {
      final repo = _MockRepo();
      _stubRows(
        repo,
        () => Stream.value([for (var i = 1; i <= 120; i++) _tx(i)]),
      );

      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SliceTransactionRow), findsNWidgets(50));
      expect(find.text('120 transactions · '), findsOneWidget);

      await tester.ensureVisible(find.text('Show 50 more'));
      await tester.tap(find.text('Show 50 more'));
      await tester.pumpAndSettle();
      expect(find.byType(SliceTransactionRow), findsNWidgets(100));
      expect(find.text('120 transactions · '), findsOneWidget);

      await tester.ensureVisible(find.text('Show 20 more'));
      await tester.tap(find.text('Show 20 more'));
      await tester.pumpAndSettle();
      expect(find.byType(SliceTransactionRow), findsNWidgets(120));
      expect(find.textContaining('more'), findsNothing);
    });

    testWidgets('button: 44 high, 14 w500 expText, divider + padding 4 8 0', (
      tester,
    ) async {
      final repo = _MockRepo();
      _stubRows(
        repo,
        () => Stream.value([for (var i = 1; i <= 51; i++) _tx(i)]),
      );

      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();

      final label = _text(tester, 'Show 1 more');
      expect(label.style!.fontSize, 14);
      expect(label.style!.fontWeight, FontWeight.w500);
      expect(label.style!.color, _colors.expText);
      // No letter spacing leaks in from TextButton's labelLarge.
      final rendered = tester.widget<RichText>(
        find.descendant(
          of: find.text('Show 1 more'),
          matching: find.byType(RichText),
        ),
      );
      expect(rendered.text.style!.letterSpacing, 0);

      final button = find.ancestor(
        of: find.text('Show 1 more'),
        matching: find.byType(TextButton),
      );
      final buttonRect = tester.getRect(button);
      expect(buttonRect.height, 44);

      final divider = tester.widget<Container>(
        find.ancestor(of: button, matching: find.byType(Container)).first,
      );
      final border = (divider.decoration! as BoxDecoration).border! as Border;
      expect(border.top, BorderSide(color: _colors.line));
      final block = tester.getRect(find.byWidget(divider));
      expect(buttonRect.top - block.top, 1 + 4);
      expect(block.bottom, buttonRect.bottom);
      expect(buttonRect.center.dx, block.center.dx);
      // Card padding 8 + 1px border below the button.
      expect(tester.getRect(_card).bottom - buttonRect.bottom, 8 + 1);
    });

    testWidgets('button: ripple clipped to its 22-radius pill, takes '
        'keyboard focus, Enter shows more (D16)', (tester) async {
      final repo = _MockRepo();
      _stubRows(
        repo,
        () => Stream.value([for (var i = 1; i <= 51; i++) _tx(i)]),
      );
      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: _slice(const SelectedSlice.category(1)),
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Show 1 more'));
      await tester.pumpAndSettle();

      await _expectRipple(
        tester,
        find.text('Show 1 more'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      );
      await _focusAndActivate(tester, find.text('Show 1 more'));
      await tester.pumpAndSettle();
      expect(find.byType(SliceTransactionRow), findsNWidgets(51));
      expect(find.text('Show 1 more'), findsNothing);
    });

    testWidgets('switching to another slice resets the cap to 50', (
      tester,
    ) async {
      final repo = _MockRepo();
      _stubRows(
        repo,
        () => Stream.value([for (var i = 1; i <= 120; i++) _tx(i)]),
      );
      final sliceNotifier = ValueNotifier(
        _slice(const SelectedSlice.category(1)),
      );
      addTearDown(sliceNotifier.dispose);

      await tester.pumpWidget(
        _harness(
          repo: repo,
          slice: sliceNotifier.value,
          sliceListenable: sliceNotifier,
          activeSelection: const SelectedSlice.category(1),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Show 50 more'));
      await tester.tap(find.text('Show 50 more'));
      await tester.pumpAndSettle();
      expect(find.byType(SliceTransactionRow), findsNWidgets(100));

      ProviderScope.containerOf(
            tester.element(find.byType(SelectedSliceItemsList)),
          )
          .read(chartsSelectionControllerProvider.notifier)
          .toggleSlice(const SelectedSlice.category(2));
      sliceNotifier.value = _slice(const SelectedSlice.category(2));
      await tester.pumpAndSettle();

      expect(find.byType(SliceTransactionRow), findsNWidgets(50));
      expect(find.text('Show 50 more'), findsOneWidget);
    });
  });
}
