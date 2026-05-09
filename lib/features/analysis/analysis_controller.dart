// Analysis-search controller — see spec § State & Controller.
//
// Composes `transactionRepository.watchByMemo(query)` with
// `analysisCategoriesByIdProvider` to build per-(category, currency)
// result groups. Cleanup axes:
//   - `_debounceTimer` — 300ms search-as-you-type pacing.
//   - `_subscription`  — cancelled on every `updateQuery`; a slow
//     'co' stream cannot leak emissions onto a faster 'coffee' result.
//   - `_generation`    — counter bumped on every updateQuery; async
//     callbacks compare against captured-at-dispatch value (stronger
//     than a query-string compare).
//   - `_lastTransactions` — cached so a category-map emission can
//     re-group without waiting for a new transactions emission.
//
// `keepAlive: true` so navigation to the detail screen and back
// preserves the typed query and result list. `build()` may still re-run
// (ref.invalidate / dependency churn / hot-reload), so the prior
// `_emitter` is closed at the top of build before a new one is opened.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';
import '../../data/models/transaction.dart';
import 'analysis_providers.dart';
import 'analysis_state.dart';

part 'analysis_controller.g.dart';

const Duration _kDebounce = Duration(milliseconds: 300);

@Riverpod(keepAlive: true, dependencies: [transactionRepository])
class AnalysisController extends _$AnalysisController {
  Timer? _debounceTimer;
  StreamSubscription<List<Transaction>>? _subscription;
  String _activeQuery = '';
  int _generation = 0;
  List<CategorySearchResult>? _lastResults;
  List<Transaction>? _lastTransactions;
  StreamController<AnalysisState>? _emitter;

  @override
  Stream<AnalysisState> build() {
    // Close any prior emitter from a previous `build()` run — `keepAlive: true`
    // does not prevent rebuilds (e.g. on `ref.invalidate`, dependency churn,
    // or hot-reload), and Riverpod calls `ref.onDispose` only on full
    // teardown, not on rebuild. Without this, the prior emitter and its
    // active `_subscription` would leak.
    _emitter?.close();

    final controller = StreamController<AnalysisState>();
    controller.add(const AnalysisState.idle());

    // Re-group on category-map emissions (rename / archive / icon-color
    // change) without requiring a new transactions emission. We re-use the
    // cached `_lastTransactions`; if no query is active or no results have
    // landed yet, this is a no-op.
    ref.listen<AsyncValue<Map<int, Category>>>(analysisCategoriesByIdProvider, (
      _,
      next,
    ) {
      final txs = _lastTransactions;
      final cats = next.valueOrNull;
      if (txs == null || cats == null || _activeQuery.isEmpty) return;
      final results = _group(txs, cats);
      if (results.isEmpty) {
        _lastResults = null;
        _emitter?.add(AnalysisState.empty(query: _activeQuery));
      } else {
        _lastResults = results;
        _emitter?.add(
          AnalysisState.results(categories: results, query: _activeQuery),
        );
      }
    });

    ref.onDispose(() {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _subscription?.cancel();
      _subscription = null;
      controller.close();
    });

    _emitter = controller;
    return controller.stream;
  }

  /// Called by the SearchBar `onChanged`.
  void updateQuery(String query) {
    final trimmed = query.trim();
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _lastTransactions = null;
    final myGen = ++_generation;

    if (trimmed.isEmpty) {
      _activeQuery = '';
      _lastResults = null;
      _emitter?.add(const AnalysisState.idle());
      return;
    }

    _activeQuery = trimmed;
    _emitter?.add(
      AnalysisState.loading(query: trimmed, previous: _lastResults),
    );

    _debounceTimer = Timer(_kDebounce, () => _subscribe(trimmed, myGen));
  }

  void _subscribe(String query, int gen) {
    if (gen != _generation) return;
    final repo = ref.read(transactionRepositoryProvider);
    _subscription = repo
        .watchByMemo(query)
        .listen(
          (txs) {
            if (gen != _generation) return;
            _lastTransactions = txs;
            final categoriesById =
                ref.read(analysisCategoriesByIdProvider).valueOrNull ??
                const <int, Category>{};
            final results = _group(txs, categoriesById);
            if (results.isEmpty) {
              _lastResults = null;
              _emitter?.add(AnalysisState.empty(query: query));
            } else {
              _lastResults = results;
              _emitter?.add(
                AnalysisState.results(categories: results, query: query),
              );
            }
          },
          onError: (Object e, StackTrace st) {
            if (gen != _generation) return;
            _emitter?.addError(e, st);
          },
        );
  }

  List<CategorySearchResult> _group(
    List<Transaction> txs,
    Map<int, Category> categoriesById,
  ) {
    final buckets = <(int, String), _Bucket>{};
    for (final tx in txs) {
      final key = (tx.categoryId, tx.currency.code);
      final bucket = buckets.putIfAbsent(
        key,
        () => _Bucket(currency: tx.currency, mostRecentDate: tx.date),
      );
      bucket.count++;
      bucket.totalMinor += tx.amountMinorUnits;
      if (tx.date.isAfter(bucket.mostRecentDate)) {
        bucket.mostRecentDate = tx.date;
      }
    }

    final results = <CategorySearchResult>[];
    buckets.forEach((key, bucket) {
      final cat = categoriesById[key.$1];
      if (cat == null) return;
      results.add(
        CategorySearchResult(
          category: cat,
          transactionCount: bucket.count,
          totalAmountMinorUnits: bucket.totalMinor,
          currency: bucket.currency,
          mostRecentDate: bucket.mostRecentDate,
        ),
      );
    });

    results.sort((a, b) {
      final byDate = b.mostRecentDate.compareTo(a.mostRecentDate);
      if (byDate != 0) return byDate;
      return a.category.id.compareTo(b.category.id);
    });
    return results;
  }
}

class _Bucket {
  _Bucket({required this.currency, required this.mostRecentDate});

  final Currency currency;
  DateTime mostRecentDate;
  int count = 0;
  int totalMinor = 0;
}
