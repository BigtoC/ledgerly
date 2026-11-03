// chartsAccountFilterOptionsProvider tests — the account sheet's rows:
// every active account with its converted total and share of the current
// type for the selected period, largest first, zero-amount accounts last.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/bootstrap.dart' show noProviderRetry;
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/utils/color_palette.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/account_slice.dart';
import 'package:ledgerly/domain/models/account_type.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/account_filter_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/search/view_models/analysis_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');
const _eur = Currency(code: 'EUR', decimals: 2, symbol: '€');

const _cashType = AccountType(id: 1, icon: 'wallet', color: 3);
const _cardType = AccountType(id: 2, icon: 'credit_card', color: 5);

Account _account(
  int id,
  String name, {
  int typeId = 2,
  String? icon,
  int? color,
  bool archived = false,
}) => Account(
  id: id,
  name: name,
  accountTypeId: typeId,
  currency: _usd,
  icon: icon,
  color: color,
  isArchived: archived,
);

ProviderContainer _container({
  required TransactionRepository repo,
  required List<Account> accounts,
  Map<String, int> ratesToUsd = const {},
}) {
  final container = ProviderContainer(
    retry: noProviderRetry,
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repo),
      chartsCurrenciesByCodeProvider.overrideWith(
        (ref) => Stream.value({'USD': _usd, 'JPY': _jpy, 'EUR': _eur}),
      ),
      chartsFxStatusProvider.overrideWith(
        (ref) => Stream.value(
          ChartsFxStatus(
            defaultCurrencyCode: 'USD',
            rates: {
              for (final e in ratesToUsd.entries)
                '${e.key}→USD': ExchangeRateMetadata(
                  rateScaledE9: e.value,
                  fetchedAt: DateTime(2026, 10, 30),
                ),
            },
          ),
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
  return container;
}

void _stubSlices(_MockTxRepo repo, List<AccountSlice> slices) {
  when(
    () => repo.watchByAccountInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      type: any(named: 'type'),
    ),
  ).thenAnswer((_) => Stream.value(slices));
}

/// Keeps the provider alive and waits until it has a non-null value.
@Dependencies([chartsAccountFilterOptions])
Future<ChartsAccountFilterOptions> _settle(ProviderContainer container) async {
  container.listen(chartsAccountFilterOptionsProvider, (_, _) {});
  for (var i = 0; i < 20; i++) {
    final value = container.read(chartsAccountFilterOptionsProvider).value;
    if (value != null) return value;
    await Future<void>.delayed(Duration.zero);
  }
  fail('chartsAccountFilterOptionsProvider never produced a value');
}

@Dependencies([ChartsSelectionController, chartsAccountFilterOptions])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
  });

  test('lists every active account by converted amount, zeros last', () async {
    final repo = _MockTxRepo();
    _stubSlices(repo, const [
      AccountSlice(accountId: 1, currencyCode: 'USD', totalMinorUnits: 1000),
      AccountSlice(accountId: 2, currencyCode: 'USD', totalMinorUnits: 500),
      // ¥3,000 at 0.0067 = $20.10, so account 2 totals $25.10.
      AccountSlice(accountId: 2, currencyCode: 'JPY', totalMinorUnits: 3000),
      AccountSlice(accountId: 4, currencyCode: 'USD', totalMinorUnits: 490),
    ]);

    final options = await _settle(
      _container(
        repo: repo,
        ratesToUsd: {'JPY': 6700000},
        accounts: [
          _account(1, 'Cash', typeId: 1),
          _account(2, 'Visa'),
          _account(3, 'Savings'),
          _account(4, 'Old card', archived: true),
          _account(5, 'Wallet'),
        ],
      ),
    );

    expect(options.currency, _usd);
    // The type total covers every account, archived ones included, so the
    // "All accounts" row matches the summary tile.
    expect(options.totalMinorUnits, 1000 + 2510 + 490);
    expect(
      [for (final o in options.accounts) o.name],
      ['Visa', 'Cash', 'Savings', 'Wallet'],
    );
    expect([for (final o in options.accounts) o.accountId], [2, 1, 3, 5]);
    expect(
      [for (final o in options.accounts) o.totalMinorUnits],
      [2510, 1000, 0, 0],
    );
    expect(options.accounts[0].share, closeTo(2510 / 4000, 1e-9));
    expect(options.accounts[1].share, closeTo(1000 / 4000, 1e-9));
    expect(options.accounts[2].share, 0);
  });

  test('leaves currencies without a rate out of every amount', () async {
    final repo = _MockTxRepo();
    _stubSlices(repo, const [
      AccountSlice(accountId: 1, currencyCode: 'USD', totalMinorUnits: 400),
      AccountSlice(accountId: 2, currencyCode: 'EUR', totalMinorUnits: 9000),
    ]);

    final options = await _settle(
      _container(
        repo: repo,
        accounts: [_account(1, 'Cash'), _account(2, 'Euro card')],
      ),
    );

    expect(options.totalMinorUnits, 400);
    expect([for (final o in options.accounts) o.name], ['Cash', 'Euro card']);
    expect(options.accounts[0].share, 1);
    expect(options.accounts[1].totalMinorUnits, 0);
    expect(options.accounts[1].share, 0);
  });

  test(
    'an account without its own icon or colour takes its type\'s (D4)',
    () async {
      final repo = _MockTxRepo();
      _stubSlices(repo, const []);

      final options = await _settle(
        _container(
          repo: repo,
          accounts: [
            _account(1, 'Cash', typeId: 1),
            _account(2, 'Visa', icon: 'savings', color: 9),
            _account(3, 'Orphan', typeId: 99),
          ],
        ),
      );

      final byName = {for (final o in options.accounts) o.name: o};
      expect(byName['Cash']!.iconKey, 'wallet');
      expect(byName['Cash']!.colorIndex, 3);
      expect(byName['Visa']!.iconKey, 'savings');
      expect(byName['Visa']!.colorIndex, 9);
      expect(byName['Orphan']!.iconKey, '');
      expect(
        byName['Orphan']!.colorIndex,
        CategoryPaletteIndex.neutralVariant50,
      );
      expect(options.totalMinorUnits, 0);
    },
  );

  test('queries the selected period and type, and re-queries when the '
      'type changes', () async {
    final repo = _MockTxRepo();
    final queries = <({DateTime start, DateTime end, CategoryType type})>[];
    when(
      () => repo.watchByAccountInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((invocation) {
      final type = invocation.namedArguments[#type] as CategoryType;
      queries.add((
        start: invocation.namedArguments[#start] as DateTime,
        end: invocation.namedArguments[#end] as DateTime,
        type: type,
      ));
      return Stream.value([
        AccountSlice(
          accountId: 1,
          currencyCode: 'USD',
          totalMinorUnits: type == CategoryType.income ? 70 : 30,
        ),
      ]);
    });
    final container = _container(repo: repo, accounts: [_account(1, 'Cash')]);
    final selection = container.read(
      chartsSelectionControllerProvider.notifier,
    );
    selection.setPeriod(PeriodType.month);

    final expense = await _settle(container);
    expect(expense.totalMinorUnits, 30);
    final month = queries.last;
    expect(month.type, CategoryType.expense);
    expect(month.start.day, 1);
    expect(month.end, DateTime(month.start.year, month.start.month + 1));

    selection.toggleType();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(queries.last.type, CategoryType.income);
    expect(queries.last.start, month.start);
    expect(
      container.read(chartsAccountFilterOptionsProvider).value?.totalMinorUnits,
      70,
    );
  });

  test('is not limited by the account filter itself', () async {
    final repo = _MockTxRepo();
    _stubSlices(repo, const [
      AccountSlice(accountId: 1, currencyCode: 'USD', totalMinorUnits: 100),
      AccountSlice(accountId: 2, currencyCode: 'USD', totalMinorUnits: 300),
    ]);
    final container = _container(
      repo: repo,
      accounts: [_account(1, 'Cash'), _account(2, 'Visa')],
    );
    await _settle(container);

    container
        .read(chartsSelectionControllerProvider.notifier)
        .setAccountFilter(1);
    await Future<void>.delayed(Duration.zero);

    final options = container.read(chartsAccountFilterOptionsProvider).value!;
    expect(options.totalMinorUnits, 400);
    expect(options.accounts, hasLength(2));
    verify(
      () => repo.watchByAccountInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).called(1);
  });

  test('also lists the archived account the page is filtered by, with its '
      'amount and share, sorted like the rest (plan D25)', () async {
    final repo = _MockTxRepo();
    _stubSlices(repo, const [
      AccountSlice(accountId: 1, currencyCode: 'USD', totalMinorUnits: 100),
      AccountSlice(accountId: 2, currencyCode: 'USD', totalMinorUnits: 300),
      AccountSlice(accountId: 3, currencyCode: 'USD', totalMinorUnits: 50),
    ]);
    final container = _container(
      repo: repo,
      accounts: [
        _account(1, 'Cash'),
        _account(2, 'Old card', archived: true),
        _account(3, 'Old wallet', archived: true),
      ],
    );
    final before = await _settle(container);
    expect([for (final o in before.accounts) o.accountId], [1]);

    container
        .read(chartsSelectionControllerProvider.notifier)
        .setAccountFilter(2);
    await Future<void>.delayed(Duration.zero);

    final options = container.read(chartsAccountFilterOptionsProvider).value!;
    // The other archived account stays out.
    expect([for (final o in options.accounts) o.accountId], [2, 1]);
    expect(options.accounts[0].name, 'Old card');
    expect(options.accounts[0].totalMinorUnits, 300);
    expect(options.accounts[0].share, closeTo(300 / 450, 1e-9));
    expect(options.totalMinorUnits, 450);
  });

  test(
    'is an error, not endless loading, when the totals query fails',
    () async {
      final repo = _MockTxRepo();
      when(
        () => repo.watchByAccountInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) => Stream.error(StateError('boom')));
      final container = _container(repo: repo, accounts: [_account(1, 'Cash')]);
      container.listen(chartsAccountFilterOptionsProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final options = container.read(chartsAccountFilterOptionsProvider);
      expect(options.hasError, isTrue);
      expect(options.error, isA<StateError>());
    },
  );

  test('is loading until every input has loaded', () {
    final repo = _MockTxRepo();
    _stubSlices(repo, const []);
    final container = _container(repo: repo, accounts: [_account(1, 'Cash')]);

    expect(
      container.read(chartsAccountFilterOptionsProvider),
      isA<AsyncLoading<ChartsAccountFilterOptions>>(),
    );
  });
}
