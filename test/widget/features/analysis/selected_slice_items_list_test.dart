import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:ledgerly/features/analysis/charts/selected_slice.dart';
import 'package:ledgerly/features/analysis/charts/widgets/selected_slice_items_list.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Transaction _tx(int id) => Transaction(
  id: id,
  amountMinorUnits: 100 * id,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  date: DateTime(2026, 5, 18),
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

Widget _harness({
  required _MockRepo repo,
  required ChartSlice slice,
  SelectedSlice? activeSelection,
  void Function(ProviderContainer container)? onContainer,
}) {
  final container = ProviderContainer(
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
        (ref) => Stream.value(const <int, Account>{}),
      ),
      chartsCurrenciesByCodeProvider.overrideWith(
        (ref) => Stream.value({'USD': _usd}),
      ),
      chartsFxStatusProvider.overrideWith(
        (ref) => Stream.value(
          const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
        ),
      ),
    ],
  );
  if (activeSelection != null) {
    container
        .read(chartsSelectionControllerProvider.notifier)
        .toggleSlice(activeSelection);
  }
  onContainer?.call(container);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SelectedSliceItemsList(slice: slice, locale: 'en'),
        ),
      ),
    ),
  );
}

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
  });

  testWidgets('renders header + rows when selection active', (tester) async {
    final repo = _MockRepo();
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1), _tx(2)]));

    await tester.pumpWidget(
      _harness(
        repo: repo,
        slice: _slice(const SelectedSlice.category(1)),
        activeSelection: const SelectedSlice.category(1),
      ),
    );
    await tester.pumpAndSettle();
    // header label (1) + one row title per transaction (2) = 3
    expect(find.text('Food'), findsNWidgets(3));
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('inline empty placeholder when rows == []', (tester) async {
    final repo = _MockRepo();
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value(const <Transaction>[]));

    await tester.pumpWidget(
      _harness(
        repo: repo,
        slice: _slice(const SelectedSlice.category(1)),
        activeSelection: const SelectedSlice.category(1),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No transactions in this period'), findsOneWidget);
  });

  testWidgets('pending delete keeps row visible and shows snackbar undo', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(
      () => repo.watchTransactionsForSliceInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value([_tx(1)]));
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
    expect(find.byType(ListTile), findsOneWidget);

    // Drain the kUndoWindow timer so it doesn't leak past teardown.
    await tester.pump(const Duration(seconds: 5));
  });
}
