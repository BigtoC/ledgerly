// Chart slice — co-located Riverpod providers.
//
// `chartsFxStatusProvider` joins the user's default currency with the
// repository's per-pair `(rate, fetchedAt)` snapshot so the controller
// can decide warm-start eligibility, blocked state, and refresh
// triggers without touching the DAO directly.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/default_currency_provider.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../data/models/currency.dart';
import '../../../data/repositories/exchange_rate_repository.dart';

part 'charts_providers.g.dart';

/// FX readiness + freshness snapshot for the active default currency.
class ChartsFxStatus {
  const ChartsFxStatus({
    required this.defaultCurrencyCode,
    required this.rates,
  });

  final String defaultCurrencyCode;

  /// `from→default` keyed snapshot of converted-and-timestamped rates.
  final Map<String, ExchangeRateMetadata> rates;

  /// Forward rate lookup for `from → defaultCurrency`. Returns 1e9 when
  /// `from == defaultCurrency` (identity). Null when no row exists.
  int? scaledRate(String from) {
    if (from == defaultCurrencyCode) return 1000000000;
    return rates['$from→$defaultCurrencyCode']?.rateScaledE9;
  }

  /// Metadata lookup for an exact FX pair.
  ExchangeRateMetadata? metadataForPair(String from, String to) {
    if (from == to) return null;
    return rates['$from→$to'];
  }
}

/// Stream of the joined FX status. Re-emits whenever either the default
/// currency or the per-pair rate metadata changes. Uses an internal
/// `StreamController` so both inputs feed the same output without
/// dropping events from whichever input wasn't last awaited.
///
/// `keepAlive` because the kept-alive `ChartsController` and
/// `SliceDrilldownController` listen to it for their whole lifetime.
@Riverpod(
  keepAlive: true,
  dependencies: [
    initialDefaultCurrency,
    defaultCurrency,
    exchangeRateRepository,
  ],
)
Stream<ChartsFxStatus> chartsFxStatus(Ref ref) {
  final initialDefault = ref.watch(initialDefaultCurrencyProvider);
  final repo = ref.watch(exchangeRateRepositoryProvider);
  final metadataStream = repo.watchRatesMetadata();

  final controller = StreamController<ChartsFxStatus>();
  var defaultCode = initialDefault;
  var rates = <String, ExchangeRateMetadata>{};

  void emit() {
    if (!controller.isClosed) {
      controller.add(
        ChartsFxStatus(defaultCurrencyCode: defaultCode, rates: rates),
      );
    }
  }

  // Seed immediately so the UI never sits in AsyncValue.loading just
  // because no rates have arrived yet.
  emit();

  final ratesSub = metadataStream.listen((next) {
    rates = next;
    emit();
  });
  // Listen rather than watch: watching the AsyncValue would rebuild this
  // provider on every emission. Like Riverpod 2's `.stream`, this reacts to
  // later values only.
  ref.listen(defaultCurrencyProvider, (_, next) {
    if (next case AsyncData(:final value)) {
      defaultCode = value;
      emit();
    }
  });
  ref.onDispose(() {
    ratesSub.cancel();
    controller.close();
  });

  return controller.stream;
}

/// `code → Currency` for `MoneyFormatter` lookups in chart widgets.
/// Mirrors `homeCurrenciesByCodeProvider` shape so chart code can format
/// amounts identically to the Home summary strip.
///
/// `keepAlive` because the kept-alive `ChartsController` listens to it.
@Riverpod(keepAlive: true, dependencies: [currencyRepository])
Stream<Map<String, Currency>> chartsCurrenciesByCode(Ref ref) {
  final repo = ref.watch(currencyRepositoryProvider);
  return repo
      .watchAll(includeTokens: true)
      .map((rows) => {for (final c in rows) c.code: c});
}
