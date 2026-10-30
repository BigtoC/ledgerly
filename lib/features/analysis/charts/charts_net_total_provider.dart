// Analysis net-total box — income minus expense for the period chosen in
// the chart's time picker, converted into the default currency.
//
// Watches only `(period, anchorDate)` from the selection, so toggling
// Expense/Income, the dimension, or a pie slice does not re-query. The
// net covers both types regardless of the Expense/Income toggle.

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/currency_converter.dart';
import '../../../data/models/currency.dart';
import 'charts_providers.dart';
import 'charts_selection_controller.dart';
import 'charts_state.dart' show PeriodType;

part 'charts_net_total_provider.g.dart';

/// Net for the selected period, in [currency] minor units.
class ChartsNetTotal {
  const ChartsNetTotal({
    required this.currency,
    required this.netMinorUnits,
    required this.isApproximate,
    required this.excludedCurrencyCodes,
  });

  /// The default currency the net is expressed in.
  final Currency currency;

  /// Income minus expense; negative when spending exceeds income. Null
  /// when every currency in the period lacks a rate, so there is nothing
  /// to show rather than a misleading zero.
  final int? netMinorUnits;

  /// True when at least one other currency was converted into
  /// [currency], so the UI prefixes the amount with `≈`.
  final bool isApproximate;

  /// Currencies left out because their exchange rate is missing, sorted.
  final List<String> excludedCurrencyCodes;
}

/// Per-currency net for the selected period's `[start, end)` range.
@Riverpod(dependencies: [transactionRepository, ChartsSelectionController])
Stream<Map<String, int>> chartsNetByCurrency(Ref ref) {
  final (PeriodType period, DateTime anchorDate) = ref.watch(
    chartsSelectionControllerProvider.select((s) => (s.period, s.anchorDate)),
  );
  final start = normalizeAnchor(anchorDate, period);
  final end = shiftAnchor(start, period, 1);
  return ref
      .watch(transactionRepositoryProvider)
      .watchNetByCurrencyInRange(start: start, end: end);
}

/// [chartsNetByCurrency] folded into the default currency. Null until the
/// net, FX status and currency metadata have all loaded, and while the
/// net query is in error so the previous period's net is not shown.
@Riverpod(
  dependencies: [chartsNetByCurrency, chartsFxStatus, chartsCurrenciesByCode],
)
ChartsNetTotal? chartsNetTotal(Ref ref) {
  final netAsync = ref.watch(chartsNetByCurrencyProvider);
  if (netAsync.hasError) return null;
  final byCurrency = netAsync.value;
  final fx = ref.watch(chartsFxStatusProvider).value;
  final currencies = ref.watch(chartsCurrenciesByCodeProvider).value;
  if (byCurrency == null || fx == null || currencies == null) return null;

  final toCode = fx.defaultCurrencyCode;
  final to =
      currencies[toCode] ?? Currency(code: toCode, decimals: 2, symbol: toCode);
  var total = 0;
  var isApproximate = false;
  final excluded = <String>[];
  for (final MapEntry(key: code, value: net) in byCurrency.entries) {
    final rate = fx.scaledRate(code);
    if (rate == null) {
      excluded.add(code);
      continue;
    }
    if (code != toCode) isApproximate = true;
    total += CurrencyConverter.convertMinorUnits(
      amountMinorUnits: net,
      rateScaledE9: rate,
      fromDecimals: currencies[code]?.decimals ?? 2,
      toDecimals: to.decimals,
    );
  }
  return ChartsNetTotal(
    currency: to,
    netMinorUnits: byCurrency.isNotEmpty && excluded.length == byCurrency.length
        ? null
        : total,
    isApproximate: isApproximate,
    excludedCurrencyCodes: excluded..sort(),
  );
}
