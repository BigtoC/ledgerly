// Analysis summary totals — expense, income and their net for the period
// chosen in the chart's time picker, converted into the default currency.
//
// Watches only `(period, anchorDate)` from the selection, so toggling
// Expense/Income, the dimension, or a pie slice does not re-query. The
// totals cover both types regardless of the Expense/Income toggle.

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../app/providers/repository_providers.dart';
import '../../../../../core/utils/currency_converter.dart';
import '../../../../../domain/models/currency.dart';
import 'charts_providers.dart';
import 'charts_selection_controller.dart';
import 'charts_state.dart' show PeriodType;

part 'charts_net_total_providers.g.dart';

/// Expense, income and net for the selected period, in [currency] minor
/// units.
class ChartsNetTotal {
  const ChartsNetTotal({
    required this.currency,
    required this.expenseMinorUnits,
    required this.incomeMinorUnits,
    required this.netMinorUnits,
    required this.excludedCurrencyCodes,
  });

  /// The default currency the totals are expressed in.
  final Currency currency;

  /// Converted expense total (non-negative). Null when every currency
  /// carrying expense in the period lacks a rate.
  final int? expenseMinorUnits;

  /// Converted income total (non-negative). Null when every currency
  /// carrying income in the period lacks a rate.
  final int? incomeMinorUnits;

  /// Income minus expense; negative when spending exceeds income. Null
  /// when every currency in the period lacks a rate, so there is nothing
  /// to show rather than a misleading zero.
  final int? netMinorUnits;

  /// Currencies left out of all three totals because their exchange rate
  /// is missing, sorted.
  final List<String> excludedCurrencyCodes;
}

/// Per-currency expense and income for the selected period's
/// `[start, end)` range.
@Riverpod(dependencies: [transactionRepository, ChartsSelectionController])
Stream<Map<String, ({int expense, int income})>> chartsNetByCurrency(Ref ref) {
  final (PeriodType period, DateTime anchorDate) = ref.watch(
    chartsSelectionControllerProvider.select((s) => (s.period, s.anchorDate)),
  );
  final start = normalizeAnchor(anchorDate, period);
  final end = shiftAnchor(start, period, 1);
  return ref
      .watch(transactionRepositoryProvider)
      .watchTotalsByTypeInRange(start: start, end: end);
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
    final rate = fx.scaledRate(code);
    if (rate == null) {
      excluded.add(code);
      continue;
    }
    hasExpenseRate |= totals.expense != 0;
    hasIncomeRate |= totals.income != 0;
    int convert(int amount) => CurrencyConverter.convertMinorUnits(
      amountMinorUnits: amount,
      rateScaledE9: rate,
      fromDecimals: currencies[code]?.decimals ?? 2,
      toDecimals: to.decimals,
    );
    expense += convert(totals.expense);
    income += convert(totals.income);
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
