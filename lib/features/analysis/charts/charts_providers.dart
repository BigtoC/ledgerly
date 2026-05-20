// Chart slice — co-located Riverpod providers.
//
// `chartsFxStatusProvider` joins the user's default currency with the
// repository's per-pair `(rate, fetchedAt)` snapshot so the controller
// can decide warm-start eligibility, blocked state, and refresh
// triggers without touching the DAO directly.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/default_currency_provider.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../data/models/currency.dart';
import '../../../data/repositories/exchange_rate_repository.dart';

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

  /// Most recent `fetchedAt` across all relevant pairs. Used by the
  /// warm-start gate (1h freshness window). `null` when there are no
  /// rates at all (cold start).
  DateTime? mostRecentFetchedAt() {
    DateTime? latest;
    for (final m in rates.values) {
      if (latest == null || m.fetchedAt.isAfter(latest)) {
        latest = m.fetchedAt;
      }
    }
    return latest;
  }
}

/// Stream of the joined FX status. Re-emits whenever either the default
/// currency or the per-pair rate metadata changes. Uses an internal
/// `StreamController` so both inputs feed the same output without
/// dropping events from whichever input wasn't last awaited.
final chartsFxStatusProvider = StreamProvider.autoDispose<ChartsFxStatus>((
  ref,
) {
  final initialDefault = ref.watch(initialDefaultCurrencyProvider);
  // `.stream` is the correct primitive for combining two streams into
  // one. AsyncValue listening would force a re-watch on every emission.
  // ignore: deprecated_member_use
  final defaultsStream = ref.watch(defaultCurrencyProvider.stream);
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
  final defaultSub = defaultsStream.listen((next) {
    defaultCode = next;
    emit();
  });
  ref.onDispose(() {
    ratesSub.cancel();
    defaultSub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// `code → Currency` for `MoneyFormatter` lookups in chart widgets.
/// Mirrors `homeCurrenciesByCodeProvider` shape so chart code can format
/// amounts identically to the Home summary strip.
final chartsCurrenciesByCodeProvider =
    StreamProvider.autoDispose<Map<String, Currency>>((ref) {
      final repo = ref.watch(currencyRepositoryProvider);
      return repo
          .watchAll(includeTokens: true)
          .map((rows) => {for (final c in rows) c.code: c});
    });
