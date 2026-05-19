import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/default_currency_provider.dart';
import '../../../data/models/category.dart' show CategoryType;
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

class ChartsSection extends ConsumerWidget {
  const ChartsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final dimension = chartData?.dimension ?? ChartDimension.category;
    final type = chartData?.type ?? CategoryType.expense;
    final period = chartData?.period ?? PeriodType.week;
    final anchor = chartData?.anchorDate ?? DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeriodSelector(
          period: period,
          anchorDate: anchor,
          isAtCurrent: _isAtCurrent(period, anchor),
          locale: locale ?? 'en',
          onPrevious: controller.previousPeriod,
          onNext: controller.nextPeriod,
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
        body,
      ],
    );
  }

  bool _isAtCurrent(PeriodType period, DateTime anchor) {
    final now = DateTime.now();
    switch (period) {
      case PeriodType.day:
        return anchor.year == now.year &&
            anchor.month == now.month &&
            anchor.day == now.day;
      case PeriodType.week:
        return !anchor
            .add(const Duration(days: 7))
            .isBefore(DateTime(now.year, now.month, now.day));
      case PeriodType.month:
        return anchor.year == now.year && anchor.month == now.month;
      case PeriodType.year:
        return anchor.year == now.year;
    }
  }
}

class _ChartBody extends StatelessWidget {
  const _ChartBody({
    required this.data,
    required this.locale,
    required this.currencies,
  });

  final ChartsData data;
  final String locale;
  final Map<String, Currency> currencies;

  @override
  Widget build(BuildContext context) {
    final showBar =
        data.bucketTotals.isNotEmpty &&
        !(data.dimension == ChartDimension.currency && data.mixedCurrencies);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryPieChart(
          slices: data.slices,
          currenciesByCode: currencies,
          locale: locale,
          grandTotalMinorUnits: data.grandTotalMinorUnits,
          displayCurrencyCode: data.displayCurrencyCode,
        ),
        const SizedBox(height: 12),
        ChartLegend(
          slices: data.slices,
          currenciesByCode: currencies,
          locale: locale,
          mixedCurrencies: data.mixedCurrencies,
        ),
        if (showBar) ...[
          const SizedBox(height: 16),
          DailyBarChart(
            period: data.period,
            anchorDate: data.anchorDate,
            bucketTotals: data.bucketTotals,
            locale: locale,
            currenciesByCode: currencies,
            displayCurrencyCode: data.displayCurrencyCode,
          ),
        ],
      ],
    );
  }
}
