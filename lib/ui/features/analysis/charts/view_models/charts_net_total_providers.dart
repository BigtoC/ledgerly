// Analysis summary totals — expense, income and their net for the period
// chosen in the chart's time picker, converted into the default currency.
//
// Watches only the period's range (`chartsRange`) and `accountFilterId` from
// the selection, so toggling Expense/Income, the dimension, or a pie slice
// does not re-query. The totals cover both types regardless of the
// Expense/Income toggle, and only the filtered account while the account
// filter is set.

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../app/providers/repository_providers.dart';
import '../../../../../domain/models/currency.dart';
import 'charts_providers.dart';
import 'charts_range_providers.dart';
import 'charts_selection_controller.dart';

part 'charts_net_total_providers.g.dart';

/// Expense, income and net for the selected period, in [currency] minor
/// units.
class const ChartsNetTotal({
  /// The default currency the totals are expressed in.
  required final Currency currency,

  /// Converted expense total (non-negative). Null when every currency
  /// carrying expense in the period lacks a rate.
  required final int? expenseMinorUnits,

  /// Converted income total (non-negative). Null when every currency
  /// carrying income in the period lacks a rate.
  required final int? incomeMinorUnits,

  /// Income minus expense; negative when spending exceeds income. Null
  /// when every currency in the period lacks a rate, so there is nothing
  /// to show rather than a misleading zero.
  required final int? netMinorUnits,

  /// Currencies left out of all three totals because their exchange rate
  /// is missing, sorted.
  required final List<String> excludedCurrencyCodes,
});

/// Per-currency expense and income for the selected period's
/// `[start, end)` range, limited to the filtered account when one is set.
@Riverpod(
  dependencies: [transactionRepository, chartsRange, ChartsSelectionController],
)
Stream<Map<String, ({int expense, int income})>> chartsNetByCurrency(Ref ref) {
  final range = ref.watch(chartsRangeProvider);
  final accountId = ref.watch(
    chartsSelectionControllerProvider.select((s) => s.accountFilterId),
  );
  if (range case AsyncError(:final error, :final stackTrace)) {
    return Stream.error(error, stackTrace);
  }
  // Loading: wait for the range without querying.
  final value = range.value;
  if (value == null) return const Stream.empty();
  return ref
      .watch(transactionRepositoryProvider)
      .watchTotalsByTypeInRange(
        start: value.start,
        end: value.end,
        accountId: accountId,
      );
}

/// [chartsNetByCurrency] folded into the default currency. Null until the
/// totals, FX status and currency metadata have all loaded, and while the
/// totals query is in error so the previous period's totals are not shown.
@Riverpod(
  dependencies: [chartsNetByCurrency, chartsFxStatus, chartsCurrenciesByCode],
)
ChartsNetTotal? chartsNetTotal(Ref ref) {
  final totalsAsync = ref.watch(chartsNetByCurrencyProvider);
  if (totalsAsync.hasError) return null;
  final byCurrency = totalsAsync.value;
  final fx = ref.watch(chartsFxStatusProvider).value;
  final currencies = ref.watch(chartsCurrenciesByCodeProvider).value;
  if (byCurrency == null || fx == null || currencies == null) return null;

  final toCode = fx.defaultCurrencyCode;
  final to =
      currencies[toCode] ?? Currency(code: toCode, decimals: 2, symbol: toCode);
  var expense = 0;
  var income = 0;
  // Whether some currency carrying that type converted.
  var hasExpenseRate = false;
  var hasIncomeRate = false;
  var hasExpense = false;
  var hasIncome = false;
  final excluded = <String>[];
  for (final MapEntry(key: code, value: totals) in byCurrency.entries) {
    hasExpense |= totals.expense != 0;
    hasIncome |= totals.income != 0;
    if (fx.scaledRate(code) == null) {
      excluded.add(code);
      continue;
    }
    hasExpenseRate |= totals.expense != 0;
    hasIncomeRate |= totals.income != 0;
    expense += fx.convert(totals.expense, code, currencies)!;
    income += fx.convert(totals.income, code, currencies)!;
  }
  final allExcluded =
      byCurrency.isNotEmpty && excluded.length == byCurrency.length;
  return ChartsNetTotal(
    currency: to,
    expenseMinorUnits: hasExpense && !hasExpenseRate ? null : expense,
    incomeMinorUnits: hasIncome && !hasIncomeRate ? null : income,
    netMinorUnits: allExcluded ? null : income - expense,
    excludedCurrencyCodes: excluded..sort(),
  );
}
