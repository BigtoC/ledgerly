import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart' as drift;
import '../database/daos/exchange_rate_dao.dart';
import '../services/exchange_rate_service.dart';

/// Concrete Drift-backed exchange-rate repository.
///
/// Single implementation — no abstract base. If a second backend is ever
/// needed, extract an interface at that point at near-zero cost.
///
/// Responsibilities:
/// - Subscribes to `dao.watchAll()` and maintains an in-memory snapshot
///   for synchronous UI lookups.
/// - Subscribes to a `defaultCurrency$` stream and re-fetches rates for
///   every in-use currency when the default changes, with a single-flight
///   guard so concurrent triggers coalesce into one network request.
/// - Stores only forward rates (foreign → default). UI never looks up the
///   reverse direction; computing inverses on the fly would be possible
///   if needed.
/// - Sanity-checks every fetched rate against an absolute plausible-range
///   table (rejects negative/zero, rejects values outside `[1e-6, 1e6]`).
///   No "drift multiplier" check — legitimate currency moves should not be
///   blocked by stale cache. The plausible-range filter is the only guard.
/// - Sanitized logging: caught exceptions log only the runtime type, never
///   the exception object (which can contain URL + currency pairs that
///   violate CLAUDE.md's "no financial data in logs" rule).
final class ExchangeRateRepository {
  ExchangeRateRepository(
    this._db,
    this._service,
    Stream<String> defaultCurrency$,
  ) {
    _daoSub = _db.exchangeRateDao.watchAll().listen(
      _rebuildSnapshot,
      onError: (Object e, StackTrace s) {
        debugPrint(
          'ExchangeRateRepository: DAO stream error '
          '(${e.runtimeType})',
        );
      },
    );
    _currencySub = defaultCurrency$.listen((code) {
      unawaited(refreshAll(code));
    });
  }

  final drift.AppDatabase _db;
  final ExchangeRateService _service;

  ExchangeRateDao get _dao => _db.exchangeRateDao;

  late final StreamSubscription<List<drift.ExchangeRateRow>> _daoSub;
  late final StreamSubscription<String> _currencySub;

  Map<String, int> _snapshot = const {};

  /// Single-flight guard: when a refresh for [defaultCurrency] is in
  /// flight, additional calls await the existing future instead of
  /// firing a parallel network request.
  Future<void>? _inFlight;
  String? _inFlightCurrency;

  /// Absolute plausible-range guard against malicious or buggy upstream
  /// responses. Applies on every fetch including cold-start (no cached
  /// baseline needed). Conservative envelope: covers normal fiat
  /// (e.g. JPY/USD ≈ 0.0067, BTC/USD ≈ 100000) without admitting
  /// nonsense values. Tightening per-pair is deferred.
  static const double _minRate = 1e-6;
  static const double _maxRate = 1e6;

  // ---------- Snapshot management ----------

  void _rebuildSnapshot(List<drift.ExchangeRateRow> rows) {
    final map = <String, int>{};
    for (final row in rows) {
      final key = '${row.baseCurrency}→${row.quoteCurrency}';
      map[key] = row.rateScaledE9;
    }
    _snapshot = map;
  }

  // ---------- Reads ----------

  /// Synchronous lookup against the in-memory snapshot. Returns the
  /// scaled-e9 integer for forward (`from → to`) lookups, or `1e9`
  /// (i.e. 1.0 × 10⁹) for same-currency pairs. Returns null when no
  /// rate is known.
  ///
  /// **Snapshot timing note:** Drift's `watch()` delivers its first
  /// emission one microtask after subscription. A UI widget that builds
  /// in the same synchronous frame as repository construction may read
  /// an empty snapshot even when the DB has cached rates. Tiles
  /// gracefully degrade to no-conversion display when `getRate` returns
  /// null.
  int? getRate(String from, String to) {
    if (from == to) return 1000000000;
    final key = '${from.toUpperCase()}→${to.toUpperCase()}';
    return _snapshot[key];
  }

  /// Stream of the snapshot map (scaled-e9 ints keyed by `from→to`).
  /// Consumed by `exchangeRatesProvider` and surfaced to UI tiles.
  Stream<Map<String, int>> watchRates() {
    return _dao.watchAll().map((rows) {
      final map = <String, int>{};
      for (final row in rows) {
        final key = '${row.baseCurrency}→${row.quoteCurrency}';
        map[key] = row.rateScaledE9;
      }
      return map;
    });
  }

  // ---------- Writes ----------

  /// Fetches rates for every in-use currency (excluding [defaultCurrency])
  /// and upserts results. Caught exceptions are logged by runtime type
  /// only; on failure the cached DAO snapshot continues to back [getRate].
  ///
  /// **Single-flight:** if a refresh is already in flight for the same
  /// [defaultCurrency], the current call awaits that future. If a
  /// refresh is in flight for a different default currency, the current
  /// call awaits the existing future and then starts a new one — so a
  /// rapid USD → EUR → USD toggle still ends with exactly one EUR fetch
  /// and one USD fetch, not three overlapping requests.
  Future<void> refreshAll(String defaultCurrency) async {
    if (_inFlight != null && _inFlightCurrency == defaultCurrency) {
      return _inFlight;
    }
    if (_inFlight != null) {
      await _inFlight;
    }
    final fut = _doRefreshAll(defaultCurrency);
    _inFlight = fut;
    _inFlightCurrency = defaultCurrency;
    try {
      await fut;
    } finally {
      if (identical(_inFlight, fut)) {
        _inFlight = null;
        _inFlightCurrency = null;
      }
    }
  }

  Future<void> _doRefreshAll(String defaultCurrency) async {
    try {
      final currencies = await _dao.distinctCurrenciesAcrossAllTables();
      final pairs = currencies
          .where((c) => c != defaultCurrency)
          .map((c) => (from: c, to: defaultCurrency))
          .toList();
      if (pairs.isEmpty) return;

      final results = await _service.fetchRates(pairs);
      await _upsertValidRates(results);
    } on Exception catch (e) {
      debugPrint(
        'ExchangeRateRepository.refreshAll failed '
        '(${e.runtimeType})',
      );
    }
  }

  /// Fetches a single pair on demand (used after creating a non-default-
  /// currency account or transaction). Errors swallowed with sanitized
  /// logging. Callers in form controllers should debounce to avoid 1:1
  /// timing correlation with financial actions.
  Future<void> fetchRate(String from, String defaultCurrency) async {
    try {
      final results = await _service.fetchRates([
        (from: from, to: defaultCurrency),
      ]);
      await _upsertValidRates(results);
    } on Exception catch (e) {
      debugPrint(
        'ExchangeRateRepository.fetchRate failed '
        '(${e.runtimeType})',
      );
    }
  }

  Future<void> _upsertValidRates(
    List<({String from, String to, double rate, DateTime fetchedAt})> results,
  ) async {
    if (results.isEmpty) return;

    final companions = <drift.ExchangeRatesCompanion>[];
    for (final r in results) {
      if (!_passesSanityBounds(r.rate)) continue;
      // Forward rate only — UI never looks up the reverse direction.
      companions.add(
        drift.ExchangeRatesCompanion(
          baseCurrency: Value(r.from),
          quoteCurrency: Value(r.to),
          rateScaledE9: Value((r.rate * 1000000000).round()),
          fetchedAt: Value(r.fetchedAt),
        ),
      );
    }

    await _dao.upsertAll(companions);
  }

  bool _passesSanityBounds(double rate) {
    if (rate <= 0) return false;
    if (rate < _minRate || rate > _maxRate) {
      // Sanitized: rate values and currency codes deliberately omitted.
      debugPrint('ExchangeRateRepository: rate outside plausible range');
      return false;
    }
    return true;
  }

  // ---------- Lifecycle ----------

  void dispose() {
    _daoSub.cancel();
    _currencySub.cancel();
  }
}
