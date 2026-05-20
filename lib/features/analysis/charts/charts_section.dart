import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/default_currency_provider.dart';
import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';
import 'charts_controller.dart';
import 'charts_providers.dart';
import 'charts_state.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/chart_legend.dart';
import 'widgets/daily_bar_chart.dart';
import 'widgets/dimension_toggle.dart';
import 'widgets/period_selector.dart';
import 'widgets/type_toggle.dart';

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
    final controller = ref.read(chartsControllerProvider.notifier);
    while (_directionQueue.isNotEmpty) {
      final direction = _directionQueue.removeFirst();
      if (direction > 0) {
        if (controller.isAtCurrentPeriod) continue;
        controller.nextPeriod();
      } else {
        controller.previousPeriod();
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
    final controller = ref.read(chartsControllerProvider.notifier);
    if (dx > 0) {
      _enqueuePeriodStep(-1);
    } else if (!controller.isAtCurrentPeriod) {
      _enqueuePeriodStep(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stateAsync = ref.watch(chartsControllerProvider);
    final controller = ref.read(chartsControllerProvider.notifier);
    final currenciesAsync = ref.watch(chartsCurrenciesByCodeProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    debugPrint(
      '[ChartsSection] build state=${stateAsync.runtimeType} '
      'value=${stateAsync.valueOrNull?.runtimeType} '
      'currencies=${currenciesAsync.valueOrNull?.length}',
    );
    // Touch the provider to keep it warm in tests + production.
    // ignore: unused_local_variable
    final defaultCurrency = ref.watch(initialDefaultCurrencyProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: stateAsync.when(
        loading: () => _frame(
          context,
          ref,
          controller,
          body: const Center(child: CircularProgressIndicator()),
          l10n: l10n,
        ),
        error: (e, _) => _frame(
          context,
          ref,
          controller,
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: controller.retry,
                child: const Text('Retry'),
              ),
            ],
          ),
          l10n: l10n,
        ),
        data: (state) => switch (state) {
          ChartsIdle() => _frame(
            context,
            ref,
            controller,
            body: const Center(child: CircularProgressIndicator()),
            l10n: l10n,
          ),
          ChartsLoading(:final previous) => _frame(
            context,
            ref,
            controller,
            body: previous == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      _ChartBody(
                        data: previous,
                        locale: locale,
                        currencies: currenciesAsync.valueOrNull ?? const {},
                      ),
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: ColoredBox(color: Color(0x33000000)),
                        ),
                      ),
                      const CircularProgressIndicator(),
                    ],
                  ),
            l10n: l10n,
            chartData: previous,
            locale: locale,
            currencies: currenciesAsync.valueOrNull ?? const {},
          ),
          ChartsEmpty() => _frame(
            context,
            ref,
            controller,
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(l10n.chartsNoData)),
            ),
            l10n: l10n,
          ),
          ChartsBlockedByMissingRates(:final previous) => _frame(
            context,
            ref,
            controller,
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
                        currencies: currenciesAsync.valueOrNull ?? const {},
                      ),
                    ],
                  ),
            l10n: l10n,
            chartData: previous,
            locale: locale,
            currencies: currenciesAsync.valueOrNull ?? const {},
          ),
          ChartsDataState(:final chartData) => _frame(
            context,
            ref,
            controller,
            body: _ChartBody(
              data: chartData,
              locale: locale,
              currencies: currenciesAsync.valueOrNull ?? const {},
            ),
            l10n: l10n,
            chartData: chartData,
            locale: locale,
            currencies: currenciesAsync.valueOrNull ?? const {},
          ),
          ChartsError(:final error) => _frame(
            context,
            ref,
            controller,
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$error'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: controller.retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
            l10n: l10n,
          ),
        },
      ),
    );
  }

  Widget _frame(
    BuildContext context,
    WidgetRef ref,
    ChartsController controller, {
    required Widget body,
    required AppLocalizations l10n,
    ChartsData? chartData,
    String? locale,
    Map<String, Currency> currencies = const {},
  }) {
    // Toggles bind to the controller's live selection, not `chartData`.
    // During loading the `previous` data still has the *old* period; in
    // the empty/blocked/error variants `chartData` is null. Either way,
    // reading from the controller keeps the segmented buttons in sync
    // with whatever the user just tapped.
    final dimension = controller.currentDimension;
    final type = controller.currentType;
    final period = controller.currentPeriod;
    final anchor = controller.currentAnchor;

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
          isAtCurrent: controller.isAtCurrentPeriod,
          locale: locale ?? 'en',
          onPrevious: () => _enqueuePeriodStep(-1),
          onNext: () => _enqueuePeriodStep(1),
          onPeriodChanged: controller.setPeriod,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TypeToggle(
                type: type,
                onChanged: (t) {
                  if (t != type) controller.toggleType();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DimensionToggle(
          dimension: dimension,
          onChanged: controller.toggleDimension,
        ),
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
      ],
    );
  }
}

class _ChartBody extends StatefulWidget {
  const _ChartBody({
    required this.data,
    required this.locale,
    required this.currencies,
  });

  final ChartsData data;
  final String locale;
  final Map<String, Currency> currencies;

  @override
  State<_ChartBody> createState() => _ChartBodyState();
}

class _ChartBodyState extends State<_ChartBody> {
  int? _selectedSliceIndex;

  @override
  void didUpdateWidget(covariant _ChartBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Drop selection when the slice list changes — the index is no longer
    // referentially valid after a period/dimension/type swap.
    if (oldWidget.data.slices.length != widget.data.slices.length ||
        oldWidget.data.dimension != widget.data.dimension ||
        oldWidget.data.type != widget.data.type ||
        oldWidget.data.period != widget.data.period ||
        oldWidget.data.anchorDate != widget.data.anchorDate) {
      _selectedSliceIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final showBar =
        data.bucketTotals.isNotEmpty &&
        !(data.dimension == ChartDimension.currency && data.mixedCurrencies);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryPieChart(
          slices: data.slices,
          currenciesByCode: widget.currencies,
          locale: widget.locale,
          grandTotalMinorUnits: data.grandTotalMinorUnits,
          displayCurrencyCode: data.displayCurrencyCode,
          selectedIndex: _selectedSliceIndex,
          onSelectionChanged: (i) => setState(() => _selectedSliceIndex = i),
        ),
        const SizedBox(height: 12),
        ChartLegend(
          slices: data.slices,
          currenciesByCode: widget.currencies,
          locale: widget.locale,
          mixedCurrencies: data.mixedCurrencies,
          selectedSliceIndex: _selectedSliceIndex,
          onSelectSlice: (i) => setState(() => _selectedSliceIndex = i),
        ),
        if (showBar) ...[
          const SizedBox(height: 16),
          DailyBarChart(
            period: data.period,
            anchorDate: data.anchorDate,
            bucketTotals: data.bucketTotals,
            locale: widget.locale,
            currenciesByCode: widget.currencies,
            displayCurrencyCode: data.displayCurrencyCode,
          ),
        ],
      ],
    );
  }
}
