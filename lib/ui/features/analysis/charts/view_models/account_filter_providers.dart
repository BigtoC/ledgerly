// Account sheet rows — every active account with its converted total and
// share of the current chart type for the selected period. See
// `docs/superpowers/specs/2026-11-02-analysis-redesign-design.md`
// § Account filter → Account sheet.
//
// Watches only `(period, anchorDate, type)` from the selection: the sheet
// lists every account whatever the account filter is.

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../app/providers/repository_providers.dart';
import '../../../../../core/utils/color_palette.dart';
import '../../../../../core/utils/currency_converter.dart';
import '../../../../../domain/models/account_slice.dart';
import '../../../../../domain/models/category.dart' show CategoryType;
import '../../../../../domain/models/currency.dart';
import '../../search/view_models/analysis_providers.dart';
import 'charts_providers.dart';
import 'charts_selection_controller.dart';
import 'charts_state.dart' show PeriodType;

part 'account_filter_providers.g.dart';

/// One account row of the account sheet.
class ChartsAccountFilterOption {
  const ChartsAccountFilterOption({
    required this.accountId,
    required this.name,
    required this.iconKey,
    required this.colorIndex,
    required this.totalMinorUnits,
    required this.share,
  });

  final int accountId;
  final String name;

  /// `account.icon ?? accountType.icon` (plan D4); empty when neither is
  /// known.
  final String iconKey;

  /// `account.color ?? accountType.color` (plan D4).
  final int colorIndex;

  /// Converted total of the current type in the period; 0 when the account
  /// has none.
  final int totalMinorUnits;

  /// [totalMinorUnits] over the type total, `0.0–1.0`; 0 when the type
  /// total is 0.
  final double share;
}

/// The account sheet's data, in [currency] minor units.
class ChartsAccountFilterOptions {
  const ChartsAccountFilterOptions({
    required this.currency,
    required this.totalMinorUnits,
    required this.accounts,
  });

  /// The default currency every amount is converted into.
  final Currency currency;

  /// Converted total of the current type across every account, for the
  /// "All accounts" row.
  final int totalMinorUnits;

  /// Active accounts, largest amount first; zero-amount accounts last in
  /// repository order.
  final List<ChartsAccountFilterOption> accounts;
}

/// Per-account, per-currency totals of the selected type in the selected
/// period's `[start, end)` range.
@Riverpod(dependencies: [transactionRepository, ChartsSelectionController])
Stream<List<AccountSlice>> chartsAccountTotals(Ref ref) {
  final (PeriodType period, DateTime anchorDate, CategoryType type) = ref.watch(
    chartsSelectionControllerProvider.select(
      (s) => (s.period, s.anchorDate, s.type),
    ),
  );
  final start = normalizeAnchor(anchorDate, period);
  final end = shiftAnchor(start, period, 1);
  return ref
      .watch(transactionRepositoryProvider)
      .watchByAccountInRange(start: start, end: end, type: type);
}

/// [chartsAccountTotals] converted into the default currency and joined
/// with the active accounts. Currencies without a rate are left out, like
/// the summary card. Loading until every input has loaded; an error when
/// any input is in error, so the sheet never shows stale rows.
@Riverpod(
  dependencies: [
    chartsAccountTotals,
    chartsFxStatus,
    chartsCurrenciesByCode,
    analysisAccountsById,
    analysisAccountTypesById,
  ],
)
AsyncValue<ChartsAccountFilterOptions> chartsAccountFilterOptions(Ref ref) {
  final slicesAsync = ref.watch(chartsAccountTotalsProvider);
  final fxAsync = ref.watch(chartsFxStatusProvider);
  final currenciesAsync = ref.watch(chartsCurrenciesByCodeProvider);
  final accountsAsync = ref.watch(analysisAccountsByIdProvider);
  final typesAsync = ref.watch(analysisAccountTypesByIdProvider);
  for (final input in [
    slicesAsync,
    fxAsync,
    currenciesAsync,
    accountsAsync,
    typesAsync,
  ]) {
    if (input.hasError) return AsyncError(input.error!, input.stackTrace!);
  }
  final slices = slicesAsync.value;
  final fx = fxAsync.value;
  final currencies = currenciesAsync.value;
  final accounts = accountsAsync.value;
  final types = typesAsync.value;
  if (slices == null ||
      fx == null ||
      currencies == null ||
      accounts == null ||
      types == null) {
    return const AsyncLoading();
  }

  final toCode = fx.defaultCurrencyCode;
  final to =
      currencies[toCode] ?? Currency(code: toCode, decimals: 2, symbol: toCode);
  final byAccount = <int, int>{};
  var total = 0;
  for (final s in slices) {
    final rate = fx.scaledRate(s.currencyCode);
    if (rate == null) continue;
    final converted = CurrencyConverter.convertMinorUnits(
      amountMinorUnits: s.totalMinorUnits,
      rateScaledE9: rate,
      fromDecimals: currencies[s.currencyCode]?.decimals ?? 2,
      toDecimals: to.decimals,
    );
    byAccount[s.accountId] = (byAccount[s.accountId] ?? 0) + converted;
    total += converted;
  }

  final active = [
    for (final a in accounts.values)
      if (!a.isArchived) a,
  ];
  final options = [
    for (final a in active)
      ChartsAccountFilterOption(
        accountId: a.id,
        name: a.name,
        iconKey: a.icon ?? types[a.accountTypeId]?.icon ?? '',
        colorIndex:
            a.color ??
            types[a.accountTypeId]?.color ??
            CategoryPaletteIndex.neutralVariant50,
        totalMinorUnits: byAccount[a.id] ?? 0,
        share: total == 0 ? 0 : (byAccount[a.id] ?? 0) / total,
      ),
  ];
  // List.sort is not stable: break ties on repository order.
  final order = {for (var i = 0; i < active.length; i++) active[i].id: i};
  options.sort((a, b) {
    final byAmount = b.totalMinorUnits.compareTo(a.totalMinorUnits);
    if (byAmount != 0) return byAmount;
    return order[a.accountId]!.compareTo(order[b.accountId]!);
  });
  return AsyncData(
    ChartsAccountFilterOptions(
      currency: to,
      totalMinorUnits: total,
      accounts: options,
    ),
  );
}
