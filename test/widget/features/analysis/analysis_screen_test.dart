import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_section.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_state.dart';
import 'package:ledgerly/ui/features/analysis/views/analysis_screen.dart';
import 'package:ledgerly/ui/features/analysis/views/analysis_search_field.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_net_total_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/slice_drilldown_controller.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_controller.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:ledgerly/ui/features/analysis/search/views/category_search_tile.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

Category _cat() => const Category(
  id: 1,
  type: CategoryType.expense,
  l10nKey: 'cat.coffee',
  customName: 'Coffee',
  icon: 'coffee',
  color: 1,
  sortOrder: 1,
  isArchived: false,
);

Transaction _tx() => Transaction(
  id: 1,
  amountMinorUnits: 1000,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  date: DateTime.utc(2026, 5, 1),
  memo: 'coffee',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

@Dependencies([
  ChartsSelectionController,
  ChartsController,
  chartsCurrenciesByCode,
  initialDefaultCurrency,
  SliceDrilldownController,
  chartsFxStatus,
  chartsNetTotal,
])
Widget _harness({
  required TransactionRepository tx,
  required CategoryRepository cat,
  required AccountRepository acct,
  ThemeData? theme,
  double textScale = 1,
}) {
  return ProviderScope(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(tx),
      categoryRepositoryProvider.overrideWithValue(cat),
      accountRepositoryProvider.overrideWithValue(acct),
    ],
    child: MaterialApp(
      theme: theme ?? lightTheme,
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
      home: const AnalysisScreen(),
    ),
  );
}

/// Opens the collapsed app-bar search and lets the width animation finish.
Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Search memos'));
  await tester.pump();
  await tester.pump(AnalysisMotion.searchExpandDuration);
}

Color? _iconColor(WidgetTester tester, IconData icon) => tester
    .widget<RichText>(
      find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
    )
    .text
    .style
    ?.color;

BoxDecoration _searchBoxDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(AnalysisSearchField),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

@Dependencies([
  AnalysisController,
  ChartsSelectionController,
  ChartsController,
  chartsCurrenciesByCode,
  initialDefaultCurrency,
  SliceDrilldownController,
  analysisCategoriesById,
  analysisAccountsById,
  chartsFxStatus,
  chartsNetTotal,
])
GoRouter _detailRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/analysis',
        builder: (_, _) => const AnalysisScreen(),
        routes: [
          GoRoute(
            path: 'search/:categoryId',
            builder: (_, _) => const Scaffold(body: Text('detail')),
          ),
        ],
      ),
    ],
  );
}

@Dependencies([
  AnalysisController,
  ChartsSelectionController,
  ChartsController,
  chartsCurrenciesByCode,
  initialDefaultCurrency,
  SliceDrilldownController,
  analysisCategoriesById,
  analysisAccountsById,
  chartsFxStatus,
  chartsNetTotal,
])
Widget _routerHarness({
  required TransactionRepository tx,
  required CategoryRepository cat,
  required AccountRepository acct,
  required String initialLocation,
}) {
  return ProviderScope(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(tx),
      categoryRepositoryProvider.overrideWithValue(cat),
      accountRepositoryProvider.overrideWithValue(acct),
    ],
    child: MaterialApp.router(
      theme: lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _detailRouter(initialLocation),
    ),
  );
}

@Dependencies([
  ChartsSelectionController,
  ChartsController,
  chartsCurrenciesByCode,
  initialDefaultCurrency,
  SliceDrilldownController,
  chartsFxStatus,
  AnalysisController,
  analysisCategoriesById,
  analysisAccountsById,
  chartsNetTotal,
])
void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  late _MockTransactionRepository tx;
  late _MockCategoryRepository cat;
  late _MockAccountRepository acct;

  setUp(() {
    tx = _MockTransactionRepository();
    cat = _MockCategoryRepository();
    acct = _MockAccountRepository();
    when(() => cat.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value(const <Category>[]));
    when(() => acct.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value(const <Account>[]));
  });

  group('app bar', () {
    testWidgets('page and app bar sit on the bg token, light and dark', (
      tester,
    ) async {
      for (final (theme, colors) in [
        (lightTheme, AnalysisColors.light),
        (darkTheme, AnalysisColors.dark),
      ]) {
        await tester.pumpWidget(
          _harness(tx: tx, cat: cat, acct: acct, theme: theme),
        );
        await tester.pump();
        // Let MaterialApp's theme animation settle.
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          colors.bg,
        );
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, colors.bg);
        expect(appBar.scrolledUnderElevation, 0);
        expect(appBar.surfaceTintColor, const Color(0x00000000));
        expect(appBar.toolbarHeight, 64);
        expect(appBar.automaticallyImplyLeading, isFalse);
        expect(appBar.titleSpacing, 0);
        expect(appBar.bottom, isNull);
      }
    });

    testWidgets('title 24/32 w500 fg and a collapsed search button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
      await tester.pump();

      final title = tester.widget<Text>(find.text('Analysis'));
      expect(title.style?.fontSize, 24);
      expect(title.style!.height! * 24, closeTo(32, 0.001));
      expect(title.style?.fontWeight, FontWeight.w500);
      expect(title.style?.color, AnalysisColors.light.fg);
      expect(find.byType(SearchBar), findsNothing);
      expect(find.byType(TextField), findsNothing);

      // Title row: padding 0 8 0 20.
      expect(tester.getTopLeft(find.text('Analysis')).dx, 20);
      final box = find.byType(AnalysisSearchField);
      expect(tester.getSize(box), const Size(48, 48));
      expect(tester.getTopRight(box).dx, 800 - 8);
      expect(tester.getCenter(box).dy, 32);

      expect(
        tester.getSemantics(find.byIcon(Icons.search)),
        isSemantics(
          label: 'Search memos',
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
        ),
      );
      final button = find.ancestor(
        of: find.byIcon(Icons.search),
        matching: find.byType(IconButton),
      );
      expect(tester.getSize(button), const Size(46, 46));
      expect(tester.getSize(find.byIcon(Icons.search)), const Size(24, 24));
      expect(_iconColor(tester, Icons.search), AnalysisColors.light.fg);

      final collapsed = _searchBoxDecoration(tester);
      expect(collapsed.color, const Color(0x00000000));
      expect(collapsed.border, Border.all(color: const Color(0x00000000)));
      expect(collapsed.borderRadius, BorderRadius.circular(24));
      handle.dispose();
    });

    testWidgets('tapping search grows the field leftwards and focuses it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
      await tester.pump();
      final titleRight = tester.getTopRight(find.text('Analysis')).dx;

      await tester.tap(find.byTooltip('Search memos'));
      await tester.pump();
      // Mid-animation the right edge stays put while the width grows.
      await tester.pump(const Duration(milliseconds: 100));
      final box = find.byType(AnalysisSearchField);
      expect(tester.getTopRight(box).dx, 800 - 8);
      expect(tester.getSize(box).width, greaterThan(48));
      expect(tester.takeException(), isNull);

      await tester.pump(AnalysisMotion.searchExpandDuration);
      expect(tester.getTopRight(box).dx, 800 - 8);
      expect(tester.getTopLeft(box).dx, titleRight + 12);
      expect(tester.getSize(box).height, 48);

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      expect(editable.style.fontSize, 15);
      expect(editable.style.color, AnalysisColors.light.fg);
      // The design sets no letter spacing; Material's 0.5 must not leak in.
      expect(editable.style.letterSpacing, 0);

      final expanded = _searchBoxDecoration(tester);
      expect(expanded.color, AnalysisColors.light.card);
      expect(expanded.border, Border.all(color: AnalysisColors.light.line));

      final hint = find.text('Search memos');
      expect(hint, findsOneWidget);
      final hintStyle = tester.widget<Text>(hint).style!;
      expect(hintStyle.fontSize, 15);
      expect(hintStyle.height! * 15, closeTo(20, 0.001));
      expect(hintStyle.color, AnalysisColors.light.fg2);
      expect(tester.widget<Text>(hint).overflow, TextOverflow.ellipsis);
      expect(
        find.bySemanticsLabel('Search memos to find transactions'),
        findsOneWidget,
      );

      // Leading icon 20 fg2, 14 in from the box's inner edge (1px border).
      expect(tester.getSize(find.byIcon(Icons.search)), const Size(20, 20));
      expect(_iconColor(tester, Icons.search), AnalysisColors.light.fg2);
      expect(
        tester.getTopLeft(find.byIcon(Icons.search)).dx,
        titleRight + 12 + 1 + 14,
      );

      final close = find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(IconButton),
      );
      expect(find.byTooltip('Close search'), findsOneWidget);
      expect(tester.getSize(close), const Size(44, 44));
      expect(tester.getSize(find.byIcon(Icons.close)), const Size(20, 20));
      expect(_iconColor(tester, Icons.close), AnalysisColors.light.fg2);
      expect(tester.getTopRight(close).dx, 800 - 8 - 1);

      // Typing hides the hint.
      await tester.enterText(find.byType(TextField), 'co');
      await tester.pump();
      expect(find.text('Search memos'), findsNothing);
      handle.dispose();
    });

    testWidgets('close collapses the field, clears the query and unfocuses', (
      tester,
    ) async {
      when(() => tx.watchByMemo(any()))
          .thenAnswer((_) => Stream.value([_tx()]));
      when(() => cat.watchAll(includeArchived: true))
          .thenAnswer((_) => Stream.value([_cat()]));

      await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
      await tester.pump();
      await _openSearch(tester);

      await tester.enterText(find.byType(TextField), 'coffee');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.byType(CategorySearchTile), findsOneWidget);
      expect(find.byType(ChartsSection), findsNothing);
      final focus = tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode;

      await tester.tap(find.byTooltip('Close search'));
      await tester.pump();
      await tester.pump(AnalysisMotion.searchExpandDuration);

      expect(find.byType(TextField), findsNothing);
      expect(focus.hasFocus, isFalse);
      expect(find.byTooltip('Search memos'), findsOneWidget);
      expect(tester.getSize(find.byType(AnalysisSearchField)).width, 48);
      expect(find.byType(CategorySearchTile), findsNothing);
      expect(find.byType(ChartsSection), findsOneWidget);
      final state = ProviderScope.containerOf(
        tester.element(find.byType(AnalysisScreen)),
      ).read(analysisControllerProvider);
      expect(state.value, isA<AnalysisIdle>());

      // Reopening starts from an empty field.
      await _openSearch(tester);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
    });

    testWidgets('IME composition does not dispatch a search', (tester) async {
      when(() => tx.watchByMemo(any())).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
      await tester.pump();
      await _openSearch(tester);

      await tester.showKeyboard(find.byType(TextField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ka',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 2),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      verifyNever(() => tx.watchByMemo(any()));

      // Committing the composition dispatches the committed text.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'か',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      verify(() => tx.watchByMemo('か')).called(1);
    });

    // At 2× the test font's wide title leaves a phone-width field no input,
    // so that case runs on the 800-wide default surface.
    for (final (textScale, width) in [(1.0, 390.0), (2.0, 800.0)]) {
      testWidgets('a tap anywhere in the input band brings the keyboard back '
          '(text scale $textScale)', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          _harness(tx: tx, cat: cat, acct: acct, textScale: textScale),
        );
        await tester.pump();
        await _openSearch(tester);
        await tester.showKeyboard(find.byType(TextField));
        final focus = tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode;
        expect(focus.hasFocus, isTrue);
        expect(tester.takeException(), isNull);

        final box = tester.getRect(find.byType(AnalysisSearchField));
        final input = tester.getRect(find.byType(EditableText));
        // The text line stays centred in the 48 box, as in the design.
        expect(input.center.dy, box.center.dy);
        // Android Back hides the keyboard but leaves the field focused.
        for (final dy in [box.top + 4, box.bottom - 4]) {
          tester.testTextInput.hide();
          expect(tester.testTextInput.isVisible, isFalse);
          await tester.tapAt(Offset(input.center.dx, dy));
          // Past the double-tap window, so taps stay single taps.
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.testTextInput.isVisible, isTrue, reason: 'dy $dy');
          expect(focus.hasFocus, isTrue);
        }
      });
    }

    testWidgets('2× text scale: the 64 row clamps its text at 1.5×', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _harness(tx: tx, cat: cat, acct: acct, textScale: 2),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(AppBar)).height, 64);
      // 24/32 at 1.5× → one 48 line.
      expect(tester.getSize(find.text('Analysis')).height, 48);

      await _openSearch(tester);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AnalysisSearchField)).height, 48);
      // 15/20 hint at 1.5× → 30.
      expect(tester.getSize(find.text('Search memos')).height, 30);
      expect(tester.getTopRight(find.byType(AnalysisSearchField)).dx, 390 - 8);
    });

    testWidgets('open field follows a narrower window at once, no overflow', (
      tester,
    ) async {
      // Rotation or a window resize while search is open.
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
      await tester.pump();
      await _openSearch(tester);
      final titleRight = tester.getTopRight(find.text('Analysis')).dx;
      expect(
        tester.getTopLeft(find.byType(AnalysisSearchField)).dx,
        titleRight + 12,
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pump();

      expect(tester.takeException(), isNull);
      final box = find.byType(AnalysisSearchField);
      expect(tester.getTopLeft(box).dx, titleRight + 12);
      expect(tester.getTopRight(box).dx, 390 - 8);
    });

    testWidgets('the 1.5× clamp keeps AppBar\'s safe-area padding removed', (
      tester,
    ) async {
      tester.view.padding = FakeViewPadding(
        top: 24 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
      await tester.pump();

      final title = tester.element(find.text('Analysis'));
      expect(MediaQuery.paddingOf(title).top, 0);
    });
  });

  testWidgets('shows no-results copy when query has no matches', (
    tester,
  ) async {
    when(() => tx.watchByMemo(any())).thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
    await tester.pump();
    await _openSearch(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('No transactions found'), findsOneWidget);
  });

  testWidgets('stale loading results are not tappable', (tester) async {
    final coffeeCtrl = StreamController<List<Transaction>>.broadcast();
    final teaCtrl = StreamController<List<Transaction>>.broadcast();
    addTearDown(coffeeCtrl.close);
    addTearDown(teaCtrl.close);
    when(() => tx.watchByMemo('coffee')).thenAnswer((_) => coffeeCtrl.stream);
    when(() => tx.watchByMemo('tea')).thenAnswer((_) => teaCtrl.stream);

    when(() => cat.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([_cat()]));

    await tester.pumpWidget(
      _routerHarness(
        tx: tx,
        cat: cat,
        acct: acct,
        initialLocation: '/analysis',
      ),
    );
    await tester.pump();
    await _openSearch(tester);

    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump(const Duration(milliseconds: 350));
    coffeeCtrl.add([_tx()]);
    await tester.pump();

    expect(find.byType(CategorySearchTile), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tea');
    await tester.pump();

    await tester.tap(find.byType(CategorySearchTile), warnIfMissed: false);
    await tester.pump();

    expect(find.text('detail'), findsNothing);
  });

  testWidgets('router harness can still navigate on settled results', (
    tester,
  ) async {
    when(() => tx.watchByMemo(any())).thenAnswer((_) => Stream.value([_tx()]));
    when(() => cat.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([_cat()]));

    await tester.pumpWidget(
      _routerHarness(
        tx: tx,
        cat: cat,
        acct: acct,
        initialLocation: '/analysis',
      ),
    );
    await tester.pump();
    await _openSearch(tester);

    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.tap(find.byType(CategorySearchTile));
    await tester.pumpAndSettle();

    expect(find.text('detail'), findsOneWidget);
  });
}
