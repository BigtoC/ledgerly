// showAccountFilterSheet — the account sheet. Visual values from
// docs/design/analysis-redesign/Main.dc.html (lines 263-291, sheetItems).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/bootstrap.dart' show noProviderRetry;
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/utils/color_palette.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/account_slice.dart';
import 'package:ledgerly/domain/models/account_type.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/account_filter_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/account_filter_sheet.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

/// Cash type: wallet icon, palette 3. Card type: trending_up, palette 5.
const _cashType = AccountType(id: 1, icon: 'wallet', color: 3);
const _cardType = AccountType(id: 2, icon: 'trending_up', color: 5);

const _accounts = [
  // No own icon or colour: shows the Cash type's (D4).
  Account(id: 1, name: 'Cash', accountTypeId: 1, currency: _usd),
  Account(
    id: 2,
    name: 'Visa',
    accountTypeId: 2,
    currency: _usd,
    icon: 'savings',
    color: 0,
  ),
  Account(id: 3, name: 'Savings', accountTypeId: 2, currency: _usd),
  Account(
    id: 4,
    name: 'Old card',
    accountTypeId: 2,
    currency: _usd,
    isArchived: true,
  ),
];

@Dependencies([ChartsSelectionController])
ProviderContainer _container({
  List<Account> accounts = _accounts,
  List<AccountSlice> slices = const [
    AccountSlice(accountId: 1, currencyCode: 'USD', totalMinorUnits: 1000),
    AccountSlice(accountId: 2, currencyCode: 'USD', totalMinorUnits: 2500),
  ],
  Stream<List<AccountSlice>>? slicesStream,
  DateBounds? dateBounds,
  void Function(_MockTxRepo repo)? onRepo,
}) {
  final repo = _MockTxRepo();
  onRepo?.call(repo);
  when(repo.watchDateBounds).thenAnswer((_) => Stream.value(dateBounds));
  when(
    () => repo.watchByAccountInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
    ),
  ).thenAnswer((_) => slicesStream ?? Stream.value(slices));
  final container = ProviderContainer(
    // Production does not retry failed providers either.
    retry: noProviderRetry,
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repo),
      chartsCurrenciesByCodeProvider.overrideWith(
        (ref) => Stream.value({'USD': _usd}),
      ),
      chartsFxStatusProvider.overrideWith(
        (ref) => Stream.value(
          const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
        ),
      ),
      analysisAccountsByIdProvider.overrideWith(
        (ref) => Stream.value({for (final a in accounts) a.id: a}),
      ),
      analysisAccountTypesByIdProvider.overrideWith(
        (ref) => Stream.value({1: _cashType, 2: _cardType}),
      ),
    ],
  );
  addTearDown(container.dispose);
  // Month, so the subtitle's period label is easy to spell out.
  container
      .read(chartsSelectionControllerProvider.notifier)
      .setPeriod(PeriodType.month);
  return container;
}

@Dependencies([chartsAccountFilterOptions, ChartsSelectionController])
Future<void> _open(
  WidgetTester tester,
  ProviderContainer container, {
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: theme ?? lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAccountFilterSheet(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // Let the providers load before the sheet opens.
  await tester.pump();
  await tester.pump();
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

Finder _row(String name) => find.ancestor(
  of: find.text(name),
  matching: find.byKey(const ValueKey('accountFilterRow')),
);

Color? _iconColor(WidgetTester tester, Finder icon) => tester
    .widget<RichText>(
      find.descendant(of: icon, matching: find.byType(RichText)),
    )
    .text
    .style
    ?.color;

@Dependencies([chartsAccountFilterOptions, ChartsSelectionController])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
  });

  testWidgets('a phone width opens a bottom sheet with the design chrome', (
    tester,
  ) async {
    final container = _container();
    await _open(tester, container);
    const colors = AnalysisColors.light;

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    // The sheet draws its own card surface so it can carry the design's
    // shadow, 0 -2px 16px rgba(0,0,0,.12); the Material underneath stays
    // transparent and flat.
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, const Color(0x00000000));
    expect(sheet.elevation, 0);
    final surface =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('accountFilterSheetSurface')),
                )
                .decoration
            as BoxDecoration;
    expect(surface.color, colors.card);
    expect(
      surface.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(28)),
    );
    expect(surface.boxShadow, const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.12),
        offset: Offset(0, -2),
        blurRadius: 16,
      ),
    ]);
    final barrier = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .last;
    expect(barrier.color, Colors.black.withValues(alpha: 0.32));

    // Drag handle 32×4, radius 2, outline; padding 16 0 8.
    final handle = find.byKey(const ValueKey('accountFilterHandle'));
    expect(tester.getSize(handle), const Size(32, 4));
    final handleBox =
        tester.widget<Container>(handle).decoration! as BoxDecoration;
    expect(handleBox.color, colors.outline);
    expect(handleBox.borderRadius, BorderRadius.circular(2));
    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('accountFilterSheetSurface')),
    );
    expect(tester.getTopLeft(handle).dy - sheetRect.top, 16);
    expect(tester.getCenter(handle).dx, sheetRect.center.dx);

    // Header: padding 8 24 12, gap 2.
    final title = find.text('Filter by account');
    final titleStyle = tester.widget<Text>(title).style!;
    expect(titleStyle.fontSize, 20);
    expect(titleStyle.height! * 20, closeTo(28, 0.001));
    expect(titleStyle.fontWeight, FontWeight.w500);
    expect(titleStyle.color, colors.fg);
    expect(tester.getTopLeft(title).dy - tester.getBottomLeft(handle).dy, 16);
    expect(tester.getTopLeft(title).dx - sheetRect.left, 24);
    final period = DateTime.now();
    final subtitle = find.textContaining('Filters the whole page · ');
    expect(subtitle, findsOneWidget);
    expect(
      tester.widget<Text>(subtitle).data,
      'Filters the whole page · '
      '${_monthLabel(period)}',
    );
    final subStyle = tester.widget<Text>(subtitle).style!;
    expect(subStyle.fontSize, 14);
    expect(subStyle.height! * 14, closeTo(20, 0.001));
    expect(subStyle.color, colors.fg2);
    expect(tester.getTopLeft(subtitle).dy - tester.getBottomLeft(title).dy, 2);

    // Rows: list padding 0 12; the first row 12 below the header.
    final all = _row('All accounts');
    expect(tester.getTopLeft(all).dx - sheetRect.left, 12);
    expect(sheetRect.right - tester.getTopRight(all).dx, 12);
    expect(tester.getTopLeft(all).dy - tester.getBottomLeft(subtitle).dy, 12);
    // Bottom padding 24 below the last row.
    expect(sheetRect.bottom - tester.getBottomLeft(_row('Savings')).dy, 24);
  });

  testWidgets('rows: All accounts, then active accounts by amount, zero '
      'last; archived left out', (tester) async {
    final container = _container();
    await _open(tester, container);

    final rows = find.byKey(const ValueKey('accountFilterRow'));
    expect(rows, findsNWidgets(4));
    final tops = [
      for (final name in ['All accounts', 'Visa', 'Cash', 'Savings'])
        tester.getTopLeft(_row(name)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.text('Old card'), findsNothing);
    // Gap 2 between rows.
    expect(tops[2] - tester.getBottomLeft(_row('Visa')).dy, 2);

    expect(find.text(r'$35.00 · 100.0%'), findsOneWidget);
    expect(find.text(r'$25.00 · 71.4%'), findsOneWidget);
    expect(find.text(r'$10.00 · 28.6%'), findsOneWidget);
    expect(find.text(r'$0.00 · 0.0%'), findsOneWidget);
  });

  testWidgets('row layout: min 64, padding 8 12, radius 16, gap 16, '
      'name 16/22, subtitle 13/18 tabular', (tester) async {
    final container = _container();
    await _open(tester, container);
    const colors = AnalysisColors.light;

    final visa = _row('Visa');
    final rect = tester.getRect(visa);
    expect(rect.height, 64);
    final circle = find.descendant(
      of: visa,
      matching: find.byKey(const ValueKey('accountFilterIcon')),
    );
    expect(tester.getSize(circle), const Size(40, 40));
    expect(tester.getTopLeft(circle).dx - rect.left, 12);
    expect(tester.getCenter(circle).dy, rect.center.dy);
    final name = find.text('Visa');
    expect(tester.getTopLeft(name).dx - tester.getTopRight(circle).dx, 16);
    final nameStyle = tester.widget<Text>(name).style!;
    expect(nameStyle.fontSize, 16);
    expect(nameStyle.height! * 16, closeTo(22, 0.001));
    expect(nameStyle.fontWeight, FontWeight.w400);
    expect(nameStyle.color, colors.fg);
    expect(tester.widget<Text>(name).overflow, TextOverflow.ellipsis);
    final sub = find.text(r'$25.00 · 71.4%');
    final subStyle = tester.widget<Text>(sub).style!;
    expect(subStyle.fontSize, 13);
    expect(subStyle.height! * 13, closeTo(18, 0.001));
    expect(subStyle.color, colors.fg2);
    expect(subStyle.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(tester.getTopLeft(sub).dy - tester.getBottomLeft(name).dy, 2);

    final ink = tester.widget<InkWell>(
      find.descendant(of: visa, matching: find.byType(InkWell)),
    );
    expect(ink.borderRadius, BorderRadius.circular(16));
  });

  testWidgets('All accounts: track circle with layers icon in fg2', (
    tester,
  ) async {
    final container = _container();
    await _open(tester, container);
    const colors = AnalysisColors.light;

    final all = _row('All accounts');
    final circle = find.descendant(
      of: all,
      matching: find.byKey(const ValueKey('accountFilterIcon')),
    );
    final box = tester.widget<Container>(circle).decoration! as BoxDecoration;
    expect(box.color, colors.track);
    expect(box.shape, BoxShape.circle);
    final icon = find.descendant(
      of: all,
      matching: find.byIcon(Icons.layers_outlined),
    );
    expect(tester.getSize(icon), const Size(20, 20));
    expect(_iconColor(tester, icon), colors.fg2);
  });

  testWidgets('account circles use the account colour and icon, falling '
      'back to the type\'s (D4), ink by luminance', (tester) async {
    final container = _container();
    await _open(tester, container);

    for (final (name, colorIndex, icon) in [
      ('Cash', 3, Icons.wallet),
      ('Visa', 0, Icons.savings),
      ('Savings', 5, Icons.trending_up),
    ]) {
      final row = _row(name);
      final circle = find.descendant(
        of: row,
        matching: find.byKey(const ValueKey('accountFilterIcon')),
      );
      final fill = colorForIndex(colorIndex);
      expect(
        (tester.widget<Container>(circle).decoration! as BoxDecoration).color,
        fill,
        reason: name,
      );
      final glyph = find.descendant(of: circle, matching: find.byIcon(icon));
      expect(glyph, findsOneWidget, reason: name);
      expect(tester.getSize(glyph), const Size(20, 20));
      expect(
        _iconColor(tester, glyph),
        fill.computeLuminance() > 0.35
            ? const Color(0xFF1B1B1B)
            : const Color(0xFFFFFFFF),
        reason: name,
      );
    }
  });

  testWidgets('one radio group: the current filter is selected, sel fill '
      'and w700', (tester) async {
    final container = _container();
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setAccountFilter(1);
    await _open(tester, container);
    const colors = AnalysisColors.light;

    expect(find.byType(RadioGroup<int>), findsOneWidget);
    final radios = tester.widgetList<Radio<int>>(find.byType(Radio<int>));
    expect(radios, hasLength(4));
    expect(radios.every((r) => r.activeColor == colors.expText), isTrue);
    final group = tester.widget<RadioGroup<int>>(find.byType(RadioGroup<int>));
    expect(group.groupValue, 1);

    final cash = tester.widget<Material>(_row('Cash'));
    expect(cash.color, colors.sel);
    expect(
      tester.widget<Text>(find.text('Cash')).style?.fontWeight,
      FontWeight.w700,
    );
    final visa = tester.widget<Material>(_row('Visa'));
    expect(visa.color!.a, 0);
  });

  testWidgets('an archived account the page is filtered by is listed and '
      'checked (plan D25)', (tester) async {
    final container = _container(
      slices: const [
        AccountSlice(accountId: 1, currencyCode: 'USD', totalMinorUnits: 1000),
        AccountSlice(accountId: 4, currencyCode: 'USD', totalMinorUnits: 3000),
      ],
    );
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setAccountFilter(4);
    await _open(tester, container);
    const colors = AnalysisColors.light;

    expect(find.text('Old card'), findsOneWidget);
    expect(tester.widget<Material>(_row('Old card')).color, colors.sel);
    expect(
      tester.widget<Text>(find.text('Old card')).style?.fontWeight,
      FontWeight.w700,
    );
    final group = tester.widget<RadioGroup<int>>(find.byType(RadioGroup<int>));
    expect(group.groupValue, 4);
    expect(find.text(r'$30.00 · 75.0%'), findsOneWidget);
  });

  for (final (width, surface) in [
    (390.0, find.byType(BottomSheet)),
    (1000.0, find.byType(Dialog)),
  ]) {
    testWidgets('$width wide: picking another row keeps the archived row '
        'while the sheet closes, so it does not jump (plan D25)', (
      tester,
    ) async {
      final container = _container(
        slices: const [
          AccountSlice(
            accountId: 1,
            currencyCode: 'USD',
            totalMinorUnits: 1000,
          ),
          AccountSlice(
            accountId: 4,
            currencyCode: 'USD',
            totalMinorUnits: 3000,
          ),
        ],
      );
      container
          .read(chartsSelectionControllerProvider.notifier)
          .setAccountFilter(4);
      await _open(tester, container, size: Size(width, 844));
      final openHeight = tester.getSize(surface).height;

      await tester.tap(find.text('All accounts'));
      await tester.pump();
      // Part way through the exit animation.
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        container.read(chartsSelectionControllerProvider).accountFilterId,
        isNull,
      );
      expect(surface, findsOneWidget);
      expect(find.text('Old card'), findsOneWidget);
      expect(tester.getSize(surface).height, openHeight);

      await tester.pumpAndSettle();
      expect(surface, findsNothing);
    });
  }

  testWidgets('tapping an account applies the filter and closes the sheet', (
    tester,
  ) async {
    final container = _container();
    await _open(tester, container);

    await tester.tap(find.text('Visa'));
    await tester.pumpAndSettle();

    expect(
      container.read(chartsSelectionControllerProvider).accountFilterId,
      2,
    );
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('tapping the radio of the selected row still closes the sheet', (
    tester,
  ) async {
    final container = _container();
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setAccountFilter(1);
    await _open(tester, container);

    await tester.tap(
      find.descendant(of: _row('Cash'), matching: find.byType(Radio<int>)),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(chartsSelectionControllerProvider).accountFilterId,
      1,
    );
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('tapping the radio of another row picks it', (tester) async {
    final container = _container();
    await _open(tester, container);

    await tester.tap(
      find.descendant(of: _row('Visa'), matching: find.byType(Radio<int>)),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(chartsSelectionControllerProvider).accountFilterId,
      2,
    );
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('a totals error shows the error text, not a spinner', (
    tester,
  ) async {
    final container = _container(
      slicesStream: Stream.error(StateError('boom')),
    );
    await _open(tester, container);

    expect(find.text('Something went wrong while searching'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('All accounts'), findsNothing);
  });

  testWidgets('under All: subtitle says All time and rows cover the whole '
      'history', (tester) async {
    _MockTxRepo? repo;
    final container = _container(
      dateBounds: (first: DateTime(2024, 3, 10), last: DateTime(2026, 1, 2)),
      onRepo: (r) => repo = r,
    );
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setPeriod(PeriodType.all);
    await _open(tester, container);

    expect(tester.takeException(), isNull);
    expect(find.text('Filters the whole page · All time'), findsOneWidget);
    expect(_row('Visa'), findsOneWidget);
    final now = DateTime.now();
    verify(
      () => repo!.watchByAccountInRange(
        start: DateTime(2024, 3),
        end: DateTime(now.year, now.month + 1),
        type: any(named: 'type'),
      ),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets('All accounts clears the filter', (tester) async {
    final container = _container();
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setAccountFilter(2);
    await _open(tester, container);

    await tester.tap(find.text('All accounts'));
    await tester.pumpAndSettle();

    expect(
      container.read(chartsSelectionControllerProvider).accountFilterId,
      isNull,
    );
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('picking an account in the Account dimension switches to '
      'Category (AC 6)', (tester) async {
    final container = _container();
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setDimension(ChartDimension.account);
    await _open(tester, container);

    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();

    final selection = container.read(chartsSelectionControllerProvider);
    expect(selection.accountFilterId, 1);
    expect(selection.dimension, ChartDimension.category);
  });

  testWidgets('rows take keyboard focus and Enter picks them (D16)', (
    tester,
  ) async {
    final container = _container();
    await _open(tester, container);

    Focus.of(tester.element(find.text('Cash'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      container.read(chartsSelectionControllerProvider).accountFilterId,
      1,
    );
  });

  testWidgets('a row reads as one checked or unchecked radio', (tester) async {
    final handle = tester.ensureSemantics();
    final container = _container();
    container
        .read(chartsSelectionControllerProvider.notifier)
        .setAccountFilter(2);
    await _open(tester, container);

    expect(
      tester.getSemantics(_row('Visa')),
      isSemantics(
        label: 'Visa\n\$25.00 · 71.4%',
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(_row('Cash')),
      isSemantics(
        label: 'Cash\n\$10.00 · 28.6%',
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: false,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  for (final width in [600.0, 1000.0]) {
    testWidgets('$width wide opens a 480-max dialog (D10)', (tester) async {
      final container = _container();
      await _open(tester, container, size: Size(width, 800));
      const colors = AnalysisColors.light;

      expect(find.byType(BottomSheet), findsNothing);
      // The same 32% scrim as the bottom-sheet form (Main.dc.html:263).
      final barrier = tester
          .widgetList<ModalBarrier>(find.byType(ModalBarrier))
          .last;
      expect(barrier.color, Colors.black.withValues(alpha: 0.32));
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.backgroundColor, colors.card);
      expect(
        dialog.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      );
      final surface = find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first;
      expect(tester.getSize(surface).width, 480);
      // No drag handle in the dialog form.
      expect(find.byKey(const ValueKey('accountFilterHandle')), findsNothing);
      expect(find.text('Filter by account'), findsOneWidget);
      expect(_row('Visa'), findsOneWidget);

      await tester.tap(find.text('Visa'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(
        container.read(chartsSelectionControllerProvider).accountFilterId,
        2,
      );
    });
  }

  testWidgets('599 wide still opens the bottom sheet', (tester) async {
    final container = _container();
    await _open(tester, container, size: const Size(599, 800));

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('many accounts scroll in a lazy list', (tester) async {
    final container = _container(
      accounts: [
        for (var i = 1; i <= 40; i++)
          Account(id: i, name: 'Account $i', accountTypeId: 1, currency: _usd),
      ],
      slices: const [],
    );
    await _open(tester, container);

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Account 40'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('2× text scale at phone width (Roboto)', () {
    setUpAll(() async {
      final root = Platform.environment['FLUTTER_ROOT']!;
      final roboto = File(
        '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      ).readAsBytesSync();
      await (FontLoader(
        'Roboto',
      )..addFont(Future.value(ByteData.sublistView(roboto)))).load();
    });

    testWidgets('rows grow instead of clipping; the amount is never cut off', (
      tester,
    ) async {
      final container = _container(
        accounts: const [
          Account(
            id: 1,
            name: 'A very long credit card account name that wraps',
            accountTypeId: 2,
            currency: _usd,
          ),
        ],
        slices: const [
          AccountSlice(
            accountId: 1,
            currencyCode: 'USD',
            totalMinorUnits: 123456789012,
          ),
        ],
      );
      await _open(tester, container, size: const Size(360, 800), textScale: 2);

      expect(tester.takeException(), isNull);
      final name = find.textContaining('A very long');
      // 16/22 at 2× → one 44 line; the name ellipsizes.
      expect(tester.getSize(name).height, 44);
      final row = tester.getRect(
        _row(
          'A very long credit card account name '
          'that wraps',
        ),
      );
      expect(row.height, greaterThan(64));
      // The subtitle scales down to the column instead of overflowing.
      final sub = find.text(r'$1,234,567,890.12 · 100.0%').first;
      final subRect = tester.getRect(sub);
      expect(subRect.right, lessThanOrEqualTo(row.right));
      final title = find.text('Filter by account');
      expect(tester.getSize(title).height, 56);
    });
  });
}

String _monthLabel(DateTime d) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[d.month - 1]} ${d.year}';
}
