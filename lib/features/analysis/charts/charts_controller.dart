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

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/color_palette.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/account.dart';
import '../../../data/models/account_slice.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_slice.dart';
import '../../../data/models/currency_slice.dart';
import '../../../data/models/time_bucket_slice.dart';
import '../search/analysis_providers.dart';
import 'charts_providers.dart';
import 'charts_state.dart';

part 'charts_controller.g.dart';

@Riverpod(keepAlive: true, dependencies: [transactionRepository])
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

  @override
  Stream<ChartsState> build() {
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
    if (_period == period) return;
    _period = period;
    _anchor = _normalizeAnchor(_anchor, period);
    _resubscribe();
  }

  void previousPeriod() {
    _anchor = _shiftAnchor(_anchor, _period, -1);
    _resubscribe();
  }

  void nextPeriod() {
    if (_isAtCurrentPeriod()) return; // Disabled at current period.
    _anchor = _shiftAnchor(_anchor, _period, 1);
    _resubscribe();
  }

  void toggleType() {
    _type = _type == CategoryType.expense
        ? CategoryType.income
        : CategoryType.expense;
    _resubscribe();
  }

  void toggleDimension(ChartDimension d) {
    if (_dimension == d) return;
    _dimension = d;
    _resubscribe();
  }

  void retry() {
    _resubscribe();
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
    _emitter?.add(ChartsState.loading(previous: _lastEmittedData));

    final repo = ref.read(transactionRepositoryProvider);
    final range = _currentRange();

    _bucketsSub = repo
        .watchTimeBucketsInRange(
          start: range.start,
          end: range.end,
          type: _type,
          granularity: _granularity(),
        )
        .listen(
          (buckets) {
            if (myGen != _generation) return;
            _lastBuckets = buckets;
            _emitIfReady();
          },
          onError: (Object e, StackTrace st) {
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
                if (myGen != _generation) return;
                _emitter?.add(ChartsState.error(e, st));
              },
            );
    }
  }

  void _onSlices(int myGen, List<Object> slices) {
    if (myGen != _generation) return;
    _lastSlices = slices;
    _emitIfReady();
  }

  // Task 9 emission path: builds slices directly from un-converted data,
  // one ChartSlice per (id, currency) pair. Task 11 replaces this body
  // with conversion + regrouping logic.
  void _emitIfReady() {
    final slices = _lastSlices;
    final buckets = _lastBuckets;
    if (slices == null || buckets == null) return;
    if (slices.isEmpty && buckets.isEmpty) {
      _lastEmittedData = null;
      _emitter?.add(const ChartsState.empty());
      return;
    }

    final cats =
        ref.read(analysisCategoriesByIdProvider).valueOrNull ?? const {};
    final accts =
        ref.read(analysisAccountsByIdProvider).valueOrNull ?? const {};

    final chartSlices = <ChartSlice>[];
    for (final s in slices) {
      final (label, code, total, colorIndex, iconKey) = switch (s) {
        CategorySlice() => (
          _categoryLabel(s.categoryId, cats),
          s.currencyCode,
          s.totalMinorUnits,
          (cats[s.categoryId]?.color) ?? 0,
          cats[s.categoryId]?.icon ?? '',
        ),
        AccountSlice() => (
          _accountLabel(s.accountId, accts),
          s.currencyCode,
          s.totalMinorUnits,
          (accts[s.accountId]?.color) ?? CategoryPaletteIndex.neutralVariant50,
          accts[s.accountId]?.icon ?? '',
        ),
        CurrencySlice() => (
          s.currencyCode,
          s.currencyCode,
          s.totalMinorUnits,
          _currencyColorIndex(s.currencyCode),
          '',
        ),
        _ => ('', 'USD', 0, 0, ''),
      };
      chartSlices.add(
        ChartSlice(
          label: label,
          currencyCode: code,
          totalMinorUnits: total,
          colorIndex: colorIndex,
          iconKey: iconKey,
          fraction: null,
        ),
      );
    }

    final bucketTotals = <ChartBucketTotal>[
      for (final b in buckets)
        ChartBucketTotal(
          bucketStart: b.bucketStart,
          totalMinorUnits: b.totalMinorUnits,
        ),
    ];

    final data = ChartsData(
      period: _period,
      anchorDate: _normalizeAnchor(_anchor, _period),
      type: _type,
      dimension: _dimension,
      slices: chartSlices,
      bucketTotals: bucketTotals,
      grandTotalMinorUnits: null,
      displayCurrencyCode: null,
      mixedCurrencies:
          chartSlices.map((s) => s.currencyCode).toSet().length > 1,
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
