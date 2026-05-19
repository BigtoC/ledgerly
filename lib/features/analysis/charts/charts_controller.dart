// ChartsController — Analysis-tab chart slice owner.
//
// Mirrors `AnalysisController` (search slice) in structure: a private
// `StreamController<ChartsState>` is opened in `build()` and re-opened
// on every Riverpod rebuild; subscriptions use a generation counter so
// stale emissions from a prior period/dimension/type cannot leak into
// the active state.
//
// Tasks 9–10: skeleton (range computation, command surface, raw emission).
// Task 11 layers in currency conversion.
// Tasks 12–13 add blocked-state handling and warm-start reuse.

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/color_palette.dart';
import '../../../core/utils/currency_converter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/account.dart';
import '../../../data/models/account_slice.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_slice.dart';
import '../../../data/models/currency.dart';
import '../../../data/models/currency_slice.dart';
import '../../../data/models/time_bucket_slice.dart';
import '../search/analysis_providers.dart';
import 'charts_providers.dart';
import 'charts_state.dart';

part 'charts_controller.g.dart';

@Riverpod(
  keepAlive: true,
  dependencies: [transactionRepository, exchangeRateRepository],
)
class ChartsController extends _$ChartsController {
  PeriodType _period = PeriodType.week;
  DateTime _anchor = DateTime.now();
  CategoryType _type = CategoryType.expense;
  ChartDimension _dimension = ChartDimension.category;

  int _generation = 0;
  StreamSubscription<List<Object>>? _sliceSub;
  StreamSubscription<List<TimeBucketSlice>>? _bucketsSub;
  StreamController<ChartsState>? _emitter;

  List<Object>? _lastSlices; // CategorySlice | AccountSlice | CurrencySlice
  List<TimeBucketSlice>? _lastBuckets;
  ChartsData? _lastEmittedData;
  bool _autoSwitchedToCurrency = false;

  // TODO(charts/warm-start): per the spec, week+expense+category may seed
  // from a warmed snapshot when FX freshness < 1h, default currency
  // unchanged, locale unchanged, and no transaction/category/account
  // mutations occurred since warm-up. Deferred — the cold path is already
  // sub-frame in practice. Revisit if cold-start jank surfaces.
  @override
  Stream<ChartsState> build() {
    debugPrint(
      '[ChartsController] build() — period=$_period type=$_type '
      'dimension=$_dimension anchor=$_anchor',
    );
    _emitter?.close();
    _sliceSub?.cancel();
    _bucketsSub?.cancel();

    final controller = StreamController<ChartsState>();
    _emitter = controller;

    // Re-resolve the current chart when FX or label metadata changes.
    ref.listen(chartsFxStatusProvider, (_, _) {
      if (_lastSlices != null && _lastBuckets != null) {
        _emitIfReady();
      }
    });
    ref.listen(chartsCurrenciesByCodeProvider, (_, _) {
      if (_lastSlices != null && _lastBuckets != null) {
        _emitIfReady();
      }
    });
    ref.listen(analysisCategoriesByIdProvider, (_, _) {
      if (_lastSlices != null && _lastBuckets != null) {
        _emitIfReady();
      }
    });
    ref.listen(analysisAccountsByIdProvider, (_, _) {
      if (_lastSlices != null && _lastBuckets != null) {
        _emitIfReady();
      }
    });

    controller.add(const ChartsState.idle());
    _resubscribe();

    ref.onDispose(() {
      _sliceSub?.cancel();
      _bucketsSub?.cancel();
      _sliceSub = null;
      _bucketsSub = null;
      controller.close();
    });

    return controller.stream;
  }

  // ---------- Commands ----------

  void setPeriod(PeriodType period) {
    debugPrint('[ChartsController] setPeriod($period) current=$_period');
    if (_period == period) {
      debugPrint('[ChartsController] setPeriod no-op (same period)');
      return;
    }
    _period = period;
    _anchor = _normalizeAnchor(_anchor, period);
    _resubscribe();
  }

  void previousPeriod() {
    debugPrint('[ChartsController] previousPeriod() from anchor=$_anchor');
    _anchor = _shiftAnchor(_anchor, _period, -1);
    _resubscribe();
  }

  void nextPeriod() {
    debugPrint('[ChartsController] nextPeriod() from anchor=$_anchor');
    if (_isAtCurrentPeriod()) {
      debugPrint('[ChartsController] nextPeriod no-op (at current period)');
      return;
    }
    _anchor = _shiftAnchor(_anchor, _period, 1);
    _resubscribe();
  }

  void toggleType() {
    debugPrint('[ChartsController] toggleType() current=$_type');
    _type = _type == CategoryType.expense
        ? CategoryType.income
        : CategoryType.expense;
    _resubscribe();
  }

  void toggleDimension(ChartDimension d) {
    debugPrint('[ChartsController] toggleDimension($d) current=$_dimension');
    if (_dimension == d) {
      debugPrint('[ChartsController] toggleDimension no-op (same dimension)');
      return;
    }
    _dimension = d;
    // User took over; the auto-switch banner is no longer relevant.
    _autoSwitchedToCurrency = false;
    _resubscribe();
  }

  void retry() {
    debugPrint('[ChartsController] retry()');
    _resubscribe();
  }

  /// Clears the auto-switch banner without changing dimension.
  void dismissAutoSwitchBanner() {
    if (!_autoSwitchedToCurrency) return;
    _autoSwitchedToCurrency = false;
    final last = _lastEmittedData;
    if (last != null) {
      final cleared = last.copyWith(autoSwitchedFromCategoryDimension: false);
      _lastEmittedData = cleared;
      _emitter?.add(ChartsState.data(chartData: cleared));
    }
  }

  // ---------- Subscription wiring ----------

  ({DateTime start, DateTime end}) _currentRange() {
    final start = _normalizeAnchor(_anchor, _period);
    final end = _shiftAnchor(start, _period, 1);
    return (start: start, end: end);
  }

  TimeBucketGranularity _granularity() => switch (_period) {
    PeriodType.day => TimeBucketGranularity.hour,
    PeriodType.week => TimeBucketGranularity.day,
    PeriodType.month => TimeBucketGranularity.day,
    PeriodType.year => TimeBucketGranularity.month,
  };

  void _resubscribe() {
    _sliceSub?.cancel();
    _bucketsSub?.cancel();
    _lastSlices = null;
    _lastBuckets = null;
    final myGen = ++_generation;
    final range = _currentRange();
    debugPrint(
      '[ChartsController] _resubscribe gen=$myGen period=$_period '
      'dimension=$_dimension type=$_type '
      'range=[${range.start.toIso8601String()}, ${range.end.toIso8601String()}) '
      'previousData=${_lastEmittedData != null}',
    );
    _emitter?.add(ChartsState.loading(previous: _lastEmittedData));

    final repo = ref.read(transactionRepositoryProvider);

    _bucketsSub = repo
        .watchTimeBucketsInRange(
          start: range.start,
          end: range.end,
          type: _type,
          granularity: _granularity(),
        )
        .listen(
          (buckets) {
            debugPrint(
              '[ChartsController] buckets emit gen=$myGen '
              '(active=$_generation) count=${buckets.length}',
            );
            if (myGen != _generation) {
              debugPrint('[ChartsController] buckets dropped — stale gen');
              return;
            }
            _lastBuckets = buckets;
            _emitIfReady();
          },
          onError: (Object e, StackTrace st) {
            debugPrint('[ChartsController] buckets error gen=$myGen: $e');
            if (myGen != _generation) return;
            _emitter?.add(ChartsState.error(e, st));
          },
        );

    switch (_dimension) {
      case ChartDimension.category:
        _sliceSub = repo
            .watchByCategoryInRange(
              start: range.start,
              end: range.end,
              type: _type,
            )
            .listen(
              (slices) => _onSlices(myGen, slices),
              onError: (Object e, StackTrace st) {
                debugPrint(
                  '[ChartsController] category slice error gen=$myGen: $e',
                );
                if (myGen != _generation) return;
                _emitter?.add(ChartsState.error(e, st));
              },
            );
      case ChartDimension.account:
        _sliceSub = repo
            .watchByAccountInRange(
              start: range.start,
              end: range.end,
              type: _type,
            )
            .listen(
              (slices) => _onSlices(myGen, slices),
              onError: (Object e, StackTrace st) {
                debugPrint(
                  '[ChartsController] account slice error gen=$myGen: $e',
                );
                if (myGen != _generation) return;
                _emitter?.add(ChartsState.error(e, st));
              },
            );
      case ChartDimension.currency:
        _sliceSub = repo
            .watchByCurrencyInRange(
              start: range.start,
              end: range.end,
              type: _type,
            )
            .listen(
              (slices) => _onSlices(myGen, slices),
              onError: (Object e, StackTrace st) {
                debugPrint(
                  '[ChartsController] currency slice error gen=$myGen: $e',
                );
                if (myGen != _generation) return;
                _emitter?.add(ChartsState.error(e, st));
              },
            );
    }
  }

  void _onSlices(int myGen, List<Object> slices) {
    debugPrint(
      '[ChartsController] slices emit gen=$myGen '
      '(active=$_generation) dimension=$_dimension count=${slices.length}',
    );
    if (myGen != _generation) {
      debugPrint('[ChartsController] slices dropped — stale gen');
      return;
    }
    _lastSlices = slices;
    _emitIfReady();
  }

  void _emitIfReady() {
    final slices = _lastSlices;
    final buckets = _lastBuckets;
    if (slices == null || buckets == null) {
      debugPrint(
        '[ChartsController] _emitIfReady waiting — '
        'slices=${slices == null ? "null" : slices.length} '
        'buckets=${buckets == null ? "null" : buckets.length}',
      );
      return;
    }
    if (slices.isEmpty && buckets.isEmpty) {
      debugPrint('[ChartsController] emit → ChartsEmpty');
      _lastEmittedData = null;
      _emitter?.add(const ChartsState.empty());
      return;
    }

    final fx = ref.read(chartsFxStatusProvider).valueOrNull;
    final currencies =
        ref.read(chartsCurrenciesByCodeProvider).valueOrNull ?? const {};
    if (fx == null) {
      debugPrint(
        '[ChartsController] emit → ChartsLoading (fx null, hold prior)',
      );
      _emitter?.add(ChartsState.loading(previous: _lastEmittedData));
      return;
    }

    final cats =
        ref.read(analysisCategoriesByIdProvider).valueOrNull ?? const {};
    final accts =
        ref.read(analysisAccountsByIdProvider).valueOrNull ?? const {};

    final activeCurrencies = _activeCurrencies(slices, buckets);
    final missingCurrencies = activeCurrencies
        .where((code) => fx.scaledRate(code) == null)
        .toSet();
    final missingRate = missingCurrencies.isNotEmpty;
    final allMissing =
        activeCurrencies.isNotEmpty &&
        missingCurrencies.length == activeCurrencies.length;

    debugPrint(
      '[ChartsController] _emitIfReady active=$activeCurrencies '
      'default=${fx.defaultCurrencyCode} '
      'missing=$missingCurrencies allMissing=$allMissing '
      'cats=${cats.length} accts=${accts.length}',
    );

    if (missingRate) {
      final repo = ref.read(exchangeRateRepositoryProvider);
      unawaited(repo.refreshAll(fx.defaultCurrencyCode));
    }

    if (_dimension == ChartDimension.currency) {
      _emitCurrencyDimension(
        slices: slices.cast<CurrencySlice>(),
        buckets: buckets,
        fx: fx,
        currencies: currencies,
      );
      return;
    }

    final shouldAutoSwitch =
        !_autoSwitchedToCurrency &&
        _dimension == ChartDimension.category &&
        _period == PeriodType.week &&
        allMissing &&
        _lastEmittedData == null;
    if (shouldAutoSwitch) {
      debugPrint('[ChartsController] auto-switch → currency dimension');
      _autoSwitchedToCurrency = true;
      _dimension = ChartDimension.currency;
      _resubscribe();
      return;
    }

    if (allMissing) {
      debugPrint(
        '[ChartsController] emit → ChartsBlockedByMissingRates '
        '(prior=${_lastEmittedData != null})',
      );
      _emitter?.add(
        ChartsState.blockedByMissingRates(previous: _lastEmittedData),
      );
      return;
    }

    _emitCategoryOrAccountDimension(
      slices: slices,
      buckets: buckets,
      fx: fx,
      currencies: currencies,
      cats: cats,
      accts: accts,
      missingCurrencies: missingCurrencies,
    );
  }

  Set<String> _activeCurrencies(
    List<Object> slices,
    List<TimeBucketSlice> buckets,
  ) {
    final set = <String>{};
    for (final s in slices) {
      set.add(switch (s) {
        CategorySlice() => s.currencyCode,
        AccountSlice() => s.currencyCode,
        CurrencySlice() => s.currencyCode,
        _ => '',
      });
    }
    for (final b in buckets) {
      set.add(b.currencyCode);
    }
    set.remove('');
    return set;
  }

  void _emitCategoryOrAccountDimension({
    required List<Object> slices,
    required List<TimeBucketSlice> buckets,
    required ChartsFxStatus fx,
    required Map<String, Currency> currencies,
    required Map<int, Category> cats,
    required Map<int, Account> accts,
    required Set<String> missingCurrencies,
  }) {
    final regrouped = <int, int>{}; // id → converted minor units
    for (final s in slices) {
      final (id, code, amount) = switch (s) {
        CategorySlice() => (s.categoryId, s.currencyCode, s.totalMinorUnits),
        AccountSlice() => (s.accountId, s.currencyCode, s.totalMinorUnits),
        _ => (-1, '', 0),
      };
      if (id < 0) continue;
      if (missingCurrencies.contains(code)) continue;
      final fromDecimals = currencies[code]?.decimals ?? 2;
      final toDecimals = currencies[fx.defaultCurrencyCode]?.decimals ?? 2;
      final scaled = fx.scaledRate(code)!;
      final converted = CurrencyConverter.convertMinorUnits(
        amountMinorUnits: amount,
        rateScaledE9: scaled,
        fromDecimals: fromDecimals,
        toDecimals: toDecimals,
      );
      regrouped[id] = (regrouped[id] ?? 0) + converted;
    }

    final grandTotal = regrouped.values.fold<int>(0, (a, b) => a + b);

    final chartSlices = <ChartSlice>[];
    regrouped.forEach((id, total) {
      String label;
      int colorIndex;
      String iconKey;
      if (_dimension == ChartDimension.category) {
        final c = cats[id];
        label = _categoryLabel(id, cats);
        colorIndex = c?.color ?? CategoryPaletteIndex.neutralVariant50;
        iconKey = c?.icon ?? '';
      } else {
        label = _accountLabel(id, accts);
        colorIndex = accts[id]?.color ?? CategoryPaletteIndex.neutralVariant50;
        iconKey = accts[id]?.icon ?? '';
      }
      chartSlices.add(
        ChartSlice(
          label: label,
          currencyCode: fx.defaultCurrencyCode,
          totalMinorUnits: total,
          colorIndex: colorIndex,
          iconKey: iconKey,
          fraction: grandTotal == 0 ? 0 : total / grandTotal,
        ),
      );
    });
    chartSlices.sort((a, b) => b.totalMinorUnits.compareTo(a.totalMinorUnits));

    final convertedBuckets = <DateTime, int>{};
    for (final b in buckets) {
      if (missingCurrencies.contains(b.currencyCode)) continue;
      final fromDecimals = currencies[b.currencyCode]?.decimals ?? 2;
      final toDecimals = currencies[fx.defaultCurrencyCode]?.decimals ?? 2;
      final scaled = fx.scaledRate(b.currencyCode)!;
      final converted = CurrencyConverter.convertMinorUnits(
        amountMinorUnits: b.totalMinorUnits,
        rateScaledE9: scaled,
        fromDecimals: fromDecimals,
        toDecimals: toDecimals,
      );
      convertedBuckets[b.bucketStart] =
          (convertedBuckets[b.bucketStart] ?? 0) + converted;
    }
    final bucketTotals = [
      for (final e in convertedBuckets.entries)
        ChartBucketTotal(bucketStart: e.key, totalMinorUnits: e.value),
    ]..sort((a, b) => a.bucketStart.compareTo(b.bucketStart));

    final data = ChartsData(
      period: _period,
      anchorDate: _normalizeAnchor(_anchor, _period),
      type: _type,
      dimension: _dimension,
      slices: chartSlices,
      bucketTotals: bucketTotals,
      grandTotalMinorUnits: grandTotal,
      displayCurrencyCode: fx.defaultCurrencyCode,
      mixedCurrencies: false,
      autoSwitchedFromCategoryDimension: false,
      excludedCurrencyCodes: missingCurrencies.toList()..sort(),
    );
    debugPrint(
      '[ChartsController] emit → ChartsDataState (${_dimension.name}) '
      'slices=${chartSlices.length} buckets=${bucketTotals.length} '
      'grand=$grandTotal excluded=${data.excludedCurrencyCodes}',
    );
    _lastEmittedData = data;
    _emitter?.add(ChartsState.data(chartData: data));
  }

  void _emitCurrencyDimension({
    required List<CurrencySlice> slices,
    required List<TimeBucketSlice> buckets,
    required ChartsFxStatus fx,
    required Map<String, Currency> currencies,
  }) {
    final missingRate = slices.any(
      (s) => fx.scaledRate(s.currencyCode) == null,
    );

    final chartSlices = <ChartSlice>[];
    int? grandTotal;
    if (!missingRate) {
      grandTotal = 0;
      final converted = <CurrencySlice, int>{};
      for (final s in slices) {
        final fromDecimals = currencies[s.currencyCode]?.decimals ?? 2;
        final toDecimals = currencies[fx.defaultCurrencyCode]?.decimals ?? 2;
        final amount = CurrencyConverter.convertMinorUnits(
          amountMinorUnits: s.totalMinorUnits,
          rateScaledE9: fx.scaledRate(s.currencyCode)!,
          fromDecimals: fromDecimals,
          toDecimals: toDecimals,
        );
        converted[s] = amount;
        grandTotal = grandTotal! + amount;
      }
      for (final s in slices) {
        final amount = converted[s]!;
        chartSlices.add(
          ChartSlice(
            label: s.currencyCode,
            currencyCode: fx.defaultCurrencyCode,
            totalMinorUnits: amount,
            colorIndex: _currencyColorIndex(s.currencyCode),
            iconKey: '',
            fraction: grandTotal == 0 ? 0 : amount / grandTotal!,
          ),
        );
      }
    } else {
      for (final s in slices) {
        chartSlices.add(
          ChartSlice(
            label: s.currencyCode,
            currencyCode: s.currencyCode,
            totalMinorUnits: s.totalMinorUnits,
            colorIndex: _currencyColorIndex(s.currencyCode),
            iconKey: '',
            fraction: null,
          ),
        );
      }
    }

    // Bar chart: hidden until every bucket currency is convertible.
    final bucketsMissing = buckets.any(
      (b) => fx.scaledRate(b.currencyCode) == null,
    );
    final bucketTotals = <ChartBucketTotal>[];
    if (!bucketsMissing) {
      final regrouped = <DateTime, int>{};
      for (final b in buckets) {
        final fromDecimals = currencies[b.currencyCode]?.decimals ?? 2;
        final toDecimals = currencies[fx.defaultCurrencyCode]?.decimals ?? 2;
        final converted = CurrencyConverter.convertMinorUnits(
          amountMinorUnits: b.totalMinorUnits,
          rateScaledE9: fx.scaledRate(b.currencyCode)!,
          fromDecimals: fromDecimals,
          toDecimals: toDecimals,
        );
        regrouped[b.bucketStart] = (regrouped[b.bucketStart] ?? 0) + converted;
      }
      for (final e in regrouped.entries) {
        bucketTotals.add(
          ChartBucketTotal(bucketStart: e.key, totalMinorUnits: e.value),
        );
      }
      bucketTotals.sort((a, b) => a.bucketStart.compareTo(b.bucketStart));
    }

    chartSlices.sort((a, b) => b.totalMinorUnits.compareTo(a.totalMinorUnits));

    final data = ChartsData(
      period: _period,
      anchorDate: _normalizeAnchor(_anchor, _period),
      type: _type,
      dimension: _dimension,
      slices: chartSlices,
      bucketTotals: bucketTotals,
      grandTotalMinorUnits: missingRate ? null : grandTotal,
      displayCurrencyCode: missingRate ? null : fx.defaultCurrencyCode,
      mixedCurrencies: missingRate,
      autoSwitchedFromCategoryDimension: _autoSwitchedToCurrency,
    );
    debugPrint(
      '[ChartsController] emit → ChartsDataState (currency) '
      'slices=${chartSlices.length} buckets=${bucketTotals.length} '
      'mixed=$missingRate grand=${data.grandTotalMinorUnits} '
      'autoSwitched=$_autoSwitchedToCurrency',
    );
    _lastEmittedData = data;
    _emitter?.add(ChartsState.data(chartData: data));
  }

  String _categoryLabel(int id, Map<int, Category> cats) {
    final c = cats[id];
    if (c == null) return '';
    if (c.customName != null && c.customName!.trim().isNotEmpty) {
      return c.customName!;
    }
    return c.l10nKey ?? '';
  }

  String _accountLabel(int id, Map<int, Account> accts) {
    return accts[id]?.name ?? '';
  }

  int _currencyColorIndex(String code) =>
      code.hashCode.abs() % kCategoryColorPalette.length;

  // ---------- Period math ----------

  DateTime _normalizeAnchor(DateTime anchor, PeriodType period) {
    switch (period) {
      case PeriodType.day:
        return DateHelpers.startOfDay(anchor);
      case PeriodType.week:
        return DateHelpers.startOfWeek(anchor);
      case PeriodType.month:
        return DateHelpers.startOfMonth(anchor);
      case PeriodType.year:
        return DateHelpers.startOfYear(anchor);
    }
  }

  DateTime _shiftAnchor(DateTime anchor, PeriodType period, int delta) {
    final base = _normalizeAnchor(anchor, period);
    switch (period) {
      case PeriodType.day:
        return DateTime(base.year, base.month, base.day + delta);
      case PeriodType.week:
        return DateTime(base.year, base.month, base.day + 7 * delta);
      case PeriodType.month:
        return DateTime(base.year, base.month + delta, 1);
      case PeriodType.year:
        return DateTime(base.year + delta, 1, 1);
    }
  }

  bool _isAtCurrentPeriod() {
    final now = DateTime.now();
    final currentAnchor = _normalizeAnchor(now, _period);
    final myAnchor = _normalizeAnchor(_anchor, _period);
    return !myAnchor.isBefore(currentAnchor);
  }
}
