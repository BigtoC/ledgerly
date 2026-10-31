import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../app/providers/default_currency_provider.dart';
import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';
import '../search/analysis_providers.dart';
import 'charts_controller.dart';
import 'charts_net_total_providers.dart';
import 'charts_providers.dart';
import 'charts_selection_controller.dart';
import 'charts_state.dart';
import 'slice_drilldown_controller.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/chart_legend.dart';
import 'widgets/charts_net_total_card.dart';
import 'widgets/daily_bar_chart.dart';
import 'widgets/dimension_toggle.dart';
import 'widgets/period_selector.dart';
import 'widgets/selected_slice_items_list.dart';
import 'widgets/type_toggle.dart';

@Dependencies([
  ChartsSelectionController,
  ChartsController,
  chartsCurrenciesByCode,
  initialDefaultCurrency,
  SliceDrilldownController,
  analysisCategoriesById,
  analysisAccountsById,
  chartsFxStatus,
  chartsNetTotal,
])
class ChartsSection extends ConsumerStatefulWidget {
  const ChartsSection({super.key});

  @override
  ConsumerState<ChartsSection> createState() => _ChartsSectionState();
}

class _ChartsSectionState extends ConsumerState<ChartsSection>
    with SingleTickerProviderStateMixin {
  // Matches Home's day-switch animation so the two surfaces feel the same
  // when the user swipes — same duration, same curve, same offset shape.
  static const _kPeriodSwitchDuration = Duration(milliseconds: 360);
  static const _kPeriodSwitchCurve = Curves.easeInOut;
  // Velocity threshold for treating a horizontal fling as a period swipe.
  // Mirrors Home's 300 px/s gate.
  static const _kSwipeVelocity = 300.0;

  late final AnimationController _switchController;
  late Animation<Offset> _incomingOffset;
  final Queue<int> _directionQueue = Queue<int>();

  @override
  void initState() {
    super.initState();
    _switchController = AnimationController(
      duration: _kPeriodSwitchDuration,
      vsync: this,
    );
    _incomingOffset = _buildOffsetAnimation(0);
    _switchController.value = 1.0; // start fully visible
  }

  @override
  void dispose() {
    _switchController.dispose();
    super.dispose();
  }

  Animation<Offset> _buildOffsetAnimation(int direction) {
    // direction +1 → newer period, new content enters from the right.
    // direction -1 → older period, new content enters from the left.
    // direction  0 → no slide (used for the initial mount).
    final begin = direction > 0
        ? const Offset(1.0, 0.0)
        : direction < 0
        ? const Offset(-1.0, 0.0)
        : Offset.zero;
    return Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _switchController, curve: _kPeriodSwitchCurve),
    );
  }

  void _enqueuePeriodStep(int delta) {
    _directionQueue.add(delta > 0 ? 1 : -1);
    if (!_switchController.isAnimating) {
      unawaited(_runQueuedTransitions());
    }
  }

  Future<void> _runQueuedTransitions() async {
    final selection = ref.read(chartsSelectionControllerProvider.notifier);
    while (_directionQueue.isNotEmpty) {
      final direction = _directionQueue.removeFirst();
      if (direction > 0) {
        if (selection.isAtCurrentPeriod()) continue;
        selection.nextPeriod();
      } else {
        selection.previousPeriod();
      }
      _incomingOffset = _buildOffsetAnimation(direction);
      _switchController.reset();
      await _switchController.forward();
    }
  }

  void _onHorizontalFling(DragEndDetails details) {
    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;
    if (dx.abs() < _kSwipeVelocity || dx.abs() <= dy.abs()) return;
    final selection = ref.read(chartsSelectionControllerProvider.notifier);
    if (dx > 0) {
      _enqueuePeriodStep(-1);
    } else if (!selection.isAtCurrentPeriod()) {
      _enqueuePeriodStep(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stateAsync = ref.watch(chartsControllerProvider);
    final controller = ref.read(chartsControllerProvider.notifier);
    final selection = ref.watch(chartsSelectionControllerProvider);
    final selectionNotifier = ref.read(
      chartsSelectionControllerProvider.notifier,
    );
    final currenciesAsync = ref.watch(chartsCurrenciesByCodeProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Touch the provider to keep it warm in tests + production.
    // ignore: unused_local_variable
    final defaultCurrency = ref.watch(initialDefaultCurrencyProvider);

    // Stale-selection self-heal: clear the drill-down selection when the
    // selected slice is no longer present in the latest emission, or when
    // the state transitions to a variant that has no chart data
    // (Empty / Error / no-previous BlockedByMissingRates).
    ref.listen(chartsControllerProvider, (_, next) {
      if (next is! AsyncData) return;
      final value = next.value;
      final sel = ref.read(chartsSelectionControllerProvider).selectedSlice;
      if (sel == null) return;
      switch (value) {
        case ChartsDataState(:final chartData):
          final hit = chartData.slices.any((s) => s.selectionKey == sel);
          if (!hit) {
            ref.read(chartsSelectionControllerProvider.notifier).clearSlice();
          }
        case ChartsBlockedByMissingRates(:final previous):
          if (previous == null) {
            ref.read(chartsSelectionControllerProvider.notifier).clearSlice();
          }
        case ChartsEmpty():
        case ChartsError():
          ref.read(chartsSelectionControllerProvider.notifier).clearSlice();
        default:
          break;
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: stateAsync.when(
        // Skip the AsyncLoading flash that fires between Stream swaps when
        // ChartsController.build() re-runs (e.g. on slice toggle). Without
        // this the chart area briefly shrinks to a bare spinner, which
        // collapses the outer SingleChildScrollView and clamps its offset.
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => _frame(
          context,
          controller,
          selection,
          selectionNotifier,
          body: const Center(child: CircularProgressIndicator()),
          l10n: l10n,
        ),
        error: (e, _) => _frame(
          context,
          controller,
          selection,
          selectionNotifier,
          body: _errorBody(e, controller),
          l10n: l10n,
        ),
        data: (state) => switch (state) {
          ChartsLoading(:final previous) => _frame(
            context,
            controller,
            selection,
            selectionNotifier,
            // Render the prior chart directly (no Stack + dim overlay) so
            // the _ChartBody element stays put across Loading↔DataState.
            // The dim/spinner overlay was structurally different from the
            // DataState body, which forced fl_chart's pie/bar StatefulWidget
            // state to remount on every slice tap.
            body: previous == null
                ? const Center(child: CircularProgressIndicator())
                : _ChartBody(
                    data: previous,
                    locale: locale,
                    currencies: currenciesAsync.value ?? const {},
                  ),
            l10n: l10n,
            chartData: previous,
            locale: locale,
          ),
          ChartsEmpty() => _frame(
            context,
            controller,
            selection,
            selectionNotifier,
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(l10n.chartsNoData)),
            ),
            l10n: l10n,
          ),
          ChartsBlockedByMissingRates(:final previous) => _frame(
            context,
            controller,
            selection,
            selectionNotifier,
            body: previous == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text(l10n.chartsRatesRequired)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MaterialBanner(
                        content: Text(l10n.chartsRatesRequired),
                        actions: [
                          TextButton(
                            onPressed: controller.retry,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                      _ChartBody(
                        data: previous,
                        locale: locale,
                        currencies: currenciesAsync.value ?? const {},
                      ),
                    ],
                  ),
            l10n: l10n,
            chartData: previous,
            locale: locale,
          ),
          ChartsDataState(:final chartData) => _frame(
            context,
            controller,
            selection,
            selectionNotifier,
            body: _ChartBody(
              data: chartData,
              locale: locale,
              currencies: currenciesAsync.value ?? const {},
            ),
            l10n: l10n,
            chartData: chartData,
            locale: locale,
          ),
          ChartsError(:final error) => _frame(
            context,
            controller,
            selection,
            selectionNotifier,
            body: _errorBody(error, controller),
            l10n: l10n,
          ),
        },
      ),
    );
  }

  Widget _errorBody(Object error, ChartsController controller) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$error'),
      const SizedBox(height: 8),
      TextButton(onPressed: controller.retry, child: const Text('Retry')),
    ],
  );

  Widget _frame(
    BuildContext context,
    ChartsController controller,
    ChartsSelection selection,
    ChartsSelectionController selectionNotifier, {
    required Widget body,
    required AppLocalizations l10n,
    ChartsData? chartData,
    String? locale,
  }) {
    // Toggles bind to the live selection, not `chartData`. During loading the
    // `previous` data still has the *old* period; in the empty/blocked/error
    // variants `chartData` is null. Either way, reading from the selection
    // notifier keeps the segmented buttons in sync with whatever the user
    // just tapped.
    final dimension = selection.dimension;
    final type = selection.type;
    final period = selection.period;
    final anchor = selection.anchorDate;

    // Wrap the chart body in a SlideTransition keyed on (period, anchor)
    // so the body slides in from the swipe direction every time those
    // values change. Mirrors `home_screen.dart`'s day-switch animation.
    final animatedBody = SlideTransition(
      position: _incomingOffset,
      child: KeyedSubtree(
        key: ValueKey<String>('${period.name}|${anchor.toIso8601String()}'),
        child: body,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeriodSelector(
          period: period,
          anchorDate: anchor,
          isAtCurrent: selectionNotifier.isAtCurrentPeriod(),
          locale: locale ?? 'en',
          onPrevious: () => _enqueuePeriodStep(-1),
          onNext: () => _enqueuePeriodStep(1),
          onPeriodChanged: selectionNotifier.setPeriod,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TypeToggle(
                type: type,
                onChanged: (t) {
                  if (t != type) selectionNotifier.toggleType();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DimensionToggle(
          dimension: dimension,
          onChanged: selectionNotifier.setDimension,
        ),
        const SizedBox(height: 16),
        const ChartsNetTotalCard(),
        const SizedBox(height: 16),
        if (chartData?.autoSwitchedFromCategoryDimension ?? false)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MaterialBanner(
              content: Text(l10n.chartsAutoSwitchedToCurrency),
              actions: [
                TextButton(
                  onPressed: controller.dismissAutoSwitchBanner,
                  child: Text(
                    MaterialLocalizations.of(context).closeButtonLabel,
                  ),
                ),
              ],
            ),
          ),
        if ((chartData?.excludedCurrencyCodes ?? const <String>[]).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MaterialBanner(
              content: Text(
                l10n.chartsExcludedCurrencies(
                  chartData!.excludedCurrencyCodes.join(', '),
                ),
              ),
              actions: const [SizedBox.shrink()],
            ),
          ),
        if (chartData?.mixedCurrencies ?? false)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.chartsMixedCurrencies,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _onHorizontalFling,
          child: animatedBody,
        ),
        if (chartData != null)
          Builder(
            builder: (ctx) {
              final sel = selection.selectedSlice;
              if (sel == null) return const SizedBox.shrink();
              final idx = chartData.slices.indexWhere(
                (s) => s.selectionKey == sel,
              );
              if (idx == -1) return const SizedBox.shrink();
              return SelectedSliceItemsList(
                slice: chartData.slices[idx],
                locale: locale ?? 'en',
              );
            },
          ),
      ],
    );
  }
}

@Dependencies([ChartsSelectionController])
class _ChartBody extends ConsumerStatefulWidget {
  const _ChartBody({
    required this.data,
    required this.locale,
    required this.currencies,
  });

  final ChartsData data;
  final String locale;
  final Map<String, Currency> currencies;

  @override
  ConsumerState<_ChartBody> createState() => _ChartBodyState();
}

class _ChartBodyState extends ConsumerState<_ChartBody> {
  static const _kScrollDuration = Duration(milliseconds: 300);
  static const _kScrollCurve = Curves.easeInOut;

  /// Long enough for the drill-down rows to load and finish growing in.
  static const _kFollowWindow = Duration(seconds: 2);

  final _pieKey = GlobalKey();
  final _legendKey = GlobalKey();

  /// True from the moment a slice is selected until the legend card reaches
  /// the top of the page, the user scrolls, or [_kFollowWindow] runs out.
  /// The drill-down list below the card loads asynchronously and grows in
  /// through an AnimatedSize, so the first scroll can stop short at the old
  /// scroll extent; while this is set, every extent change scrolls the card
  /// further up. The window stops a card that can never reach the top from
  /// chasing later resizes, such as the keyboard opening.
  bool _followLegend = false;
  Timer? _followTimer;
  ScrollNotificationObserverState? _scrollObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = ScrollNotificationObserver.maybeOf(context);
    if (observer == _scrollObserver) return;
    _scrollObserver?.removeListener(_onScrollNotification);
    _scrollObserver = observer?..addListener(_onScrollNotification);
  }

  @override
  void dispose() {
    _followTimer?.cancel();
    _scrollObserver?.removeListener(_onScrollNotification);
    super.dispose();
  }

  /// Selecting a slice (or switching to another one) brings the legend card
  /// to the top of the page so the card, the filtered bar chart and the
  /// drill-down list are in view. Runs after the frame so the drill-down
  /// list is mounted first.
  ///
  /// Clearing the selection scrolls back up until the whole pie chart shows.
  /// A period change clears it too, and also remounts this widget under a
  /// new period key, so the scroll is driven through the page's Scrollable,
  /// which outlives this State, and the pie is measured after the frame:
  /// the new period's banners above it can differ.
  void _onSelectionChanged({required bool selected}) {
    _followLegend = selected;
    _followTimer?.cancel();
    if (selected) {
      _followTimer = Timer(_kFollowWindow, () => _followLegend = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_revealLegend(animate: true));
      });
      return;
    }
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollable.mounted) return;
      final position = scrollable.position;
      final pie = _currentPie(scrollable.context);
      final pieTop = pie == null || !pie.attached
          ? position.minScrollExtent
          : _revealOffset(pie);
      final target = math.max(pieTop, position.minScrollExtent);
      if (position.pixels <= target) return;
      unawaited(
        position.animateTo(
          target,
          duration: _kScrollDuration,
          curve: _kScrollCurve,
        ),
      );
    });
  }

  Future<void> _revealLegend({required bool animate}) async {
    final legend = _legendKey.currentContext;
    final legendBox = legend?.findRenderObject();
    if (legend == null || legendBox == null) return;
    final position = Scrollable.of(context).position;
    final target = _revealOffset(legendBox)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    await Scrollable.ensureVisible(
      legend,
      duration: animate ? _kScrollDuration : Duration.zero,
      curve: _kScrollCurve,
    );
    if (!mounted || !_followLegend) return;
    if (_legendAtTop(position) || (position.pixels - target).abs() > 0.5) {
      // At the top, or a touch interrupted the animation: stop following.
      _followLegend = false;
    } else if (animate) {
      // The extent may have grown while the animation ran.
      await _revealLegend(animate: false);
    }
  }

  /// The pie of whichever [_ChartBody] is on the page now: this one, or the
  /// one a period change mounted in its place.
  RenderObject? _currentPie(BuildContext scrollContext) {
    if (mounted) return _pieKey.currentContext?.findRenderObject();
    _ChartBodyState? body;
    void visit(Element element) {
      if (element is StatefulElement && element.state is _ChartBodyState) {
        body = element.state as _ChartBodyState;
      } else {
        element.visitChildren(visit);
      }
    }

    scrollContext.visitChildElements(visit);
    return body?._pieKey.currentContext?.findRenderObject();
  }

  /// Scroll offset that puts [box]'s top edge at the top of the page.
  double _revealOffset(RenderObject box) =>
      RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;

  bool _legendAtTop(ScrollPosition position) {
    final legend = _legendKey.currentContext?.findRenderObject();
    if (legend == null || !legend.attached) return true;
    return _revealOffset(legend) <= position.pixels + 0.5;
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (!_followLegend || notification.depth != 0) return;
    if (notification is UserScrollNotification ||
        (notification is ScrollStartNotification &&
            notification.dragDetails != null)) {
      _followLegend = false;
      return;
    }
    // A content-size change reaches observers as an update with no delta.
    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta == null &&
        !Scrollable.of(context).position.isScrollingNotifier.value) {
      unawaited(_revealLegend(animate: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final selection = ref
        .watch(chartsSelectionControllerProvider)
        .selectedSlice;
    ref.listen(
      chartsSelectionControllerProvider.select((s) => s.selectedSlice),
      (previous, next) {
        if (previous != next) _onSelectionChanged(selected: next != null);
      },
    );
    final hit = selection == null
        ? -1
        : data.slices.indexWhere((s) => s.selectionKey == selection);
    final selectedIndex = hit == -1 ? null : hit;
    final showBar =
        data.bucketTotals.isNotEmpty &&
        !(data.dimension == ChartDimension.currency && data.mixedCurrencies);
    @Dependencies([ChartsSelectionController])
    void selectSlice(int? i) {
      if (i == null) {
        ref.read(chartsSelectionControllerProvider.notifier).clearSlice();
        return;
      }
      final key = data.slices[i].selectionKey;
      if (key != null) {
        ref.read(chartsSelectionControllerProvider.notifier).toggleSlice(key);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _pieKey,
          child: CategoryPieChart(
            slices: data.slices,
            currenciesByCode: widget.currencies,
            locale: widget.locale,
            grandTotalMinorUnits: data.grandTotalMinorUnits,
            displayCurrencyCode: data.displayCurrencyCode,
            selectedIndex: selectedIndex,
            onSelectionChanged: selectSlice,
          ),
        ),
        const SizedBox(height: 12),
        ChartLegend(
          key: _legendKey,
          slices: data.slices,
          currenciesByCode: widget.currencies,
          locale: widget.locale,
          selectedSliceIndex: selectedIndex,
          onSelectSlice: selectSlice,
        ),
        if (showBar) ...[
          const SizedBox(height: 16),
          RepaintBoundary(
            child: DailyBarChart(
              period: data.period,
              anchorDate: data.anchorDate,
              bucketTotals: data.bucketTotals,
              locale: widget.locale,
              currenciesByCode: widget.currencies,
              displayCurrencyCode: data.displayCurrencyCode,
            ),
          ),
        ],
      ],
    );
  }
}
