// Analysis summary card: the Expense / Income tiles (which are the chart
// type toggle), a ratio bar between the two totals, and the period's net.
// Values from docs/design/analysis-redesign/Main.dc.html (section
// "Summary" and its renderVals tile / ratio / net styles).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../../core/utils/money_formatter.dart';
import '../../../../../domain/models/category.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../view_models/charts_net_total_providers.dart';
import '../view_models/charts_selection_controller.dart';
import '../view_models/charts_state.dart';

/// Always renders, even before the totals load, because it is the type
/// toggle; amounts show "—" until then.
@Dependencies([chartsNetTotal, ChartsSelectionController])
class ChartsSummaryCard extends ConsumerWidget {
  const ChartsSummaryCard({super.key});

  static const _dash = '—';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(chartsNetTotalProvider);
    final (CategoryType type, PeriodType period) = ref.watch(
      chartsSelectionControllerProvider.select((s) => (s.type, s.period)),
    );
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    String amount(int? minor) => totals == null || minor == null
        ? _dash
        : MoneyFormatter.format(
            amountMinorUnits: minor,
            currency: totals.currency,
            locale: locale,
          );

    @Dependencies([ChartsSelectionController])
    void select(CategoryType tapped) {
      final selection = ref.read(chartsSelectionControllerProvider.notifier);
      // Design: any tile tap sets the type and clears the slice.
      if (tapped == type) {
        selection.clearSlice();
      } else {
        selection.toggleType();
      }
    }

    final net = totals?.netMinorUnits;
    final excluded = totals?.excludedCurrencyCodes ?? const <String>[];

    return Container(
      key: const ValueKey('summaryCard'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TypeTile(
                    tileKey: const ValueKey('summaryTile.expense'),
                    dotKey: const ValueKey('summaryDot.expense'),
                    label: l10n.chartsTypeExpense,
                    amount: amount(totals?.expenseMinorUnits),
                    selected: type == CategoryType.expense,
                    fill: colors.exp,
                    text: colors.expText,
                    tint: colors.expTint,
                    onTap: () => select(CategoryType.expense),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeTile(
                    tileKey: const ValueKey('summaryTile.income'),
                    dotKey: const ValueKey('summaryDot.income'),
                    label: l10n.chartsTypeIncome,
                    amount: amount(totals?.incomeMinorUnits),
                    selected: type == CategoryType.income,
                    fill: colors.inc,
                    text: colors.incText,
                    tint: colors.incTint,
                    onTap: () => select(CategoryType.income),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _RatioBar(
            expense: totals?.expenseMinorUnits ?? 0,
            income: totals?.incomeMinorUnits ?? 0,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MergeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          switch (period) {
                            PeriodType.day => l10n.chartsNetToday,
                            PeriodType.week => l10n.chartsNetThisWeek,
                            PeriodType.month => l10n.chartsNetThisMonth,
                            PeriodType.year => l10n.chartsNetThisYear,
                          },
                          style: analysisText(
                            size: 14,
                            lineHeight: 20,
                            color: colors.fg2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        totals == null || net == null
                            ? _dash
                            : MoneyFormatter.formatSigned(
                                amountMinorUnits: net,
                                currency: totals.currency,
                                locale: locale,
                              ),
                        maxLines: 1,
                        softWrap: false,
                        style: analysisText(
                          size: 16,
                          lineHeight: 24,
                          weight: FontWeight.w500,
                          tabular: true,
                          color: switch (net) {
                            final n? when n > 0 => colors.incText,
                            final n? when n < 0 => colors.expText,
                            _ => colors.fg,
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (excluded.isNotEmpty)
                  Text(
                    l10n.chartsExcludedCurrencies(excluded.join(', ')),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.tileKey,
    required this.dotKey,
    required this.label,
    required this.amount,
    required this.selected,
    required this.fill,
    required this.text,
    required this.tint,
    required this.onTap,
  });

  final Key tileKey;
  final Key dotKey;
  final String label;
  final String amount;
  final bool selected;

  /// The type's fill (`exp` / `inc`): dot, selected border.
  final Color fill;

  /// The type's text colour (`expText` / `incText`): selected label.
  final Color text;

  /// The type's tint (`expTint` / `incTint`): selected background.
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          key: tileKey,
          duration: AnalysisMotion.standardDuration,
          curve: AnalysisMotion.standardCurve,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? tint : Colors.transparent,
            border: Border.all(
              color: selected ? fill : colors.line,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    key: dotKey,
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: analysisText(
                        size: 13,
                        lineHeight: 18,
                        weight: FontWeight.w500,
                        color: selected ? text : colors.fg2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // D2: shrink only when the amount does not fit.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  amount,
                  maxLines: 1,
                  softWrap: false,
                  style: analysisText(
                    size: 18,
                    lineHeight: 24,
                    weight: FontWeight.w500,
                    tabular: true,
                    color: colors.fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Expense and income segments sized like CSS `flex: <total> 1 0` with a
/// 3 px gap: the gap stays when one side is zero, and both zero leave an
/// empty track.
class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.expense, required this.income});

  final int expense;
  final int income;

  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    final sum = expense + income;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Container(
          key: const ValueKey('summaryRatio.track'),
          height: 6,
          decoration: BoxDecoration(color: colors.track),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final available = (constraints.maxWidth - _gap).clamp(
                0.0,
                double.infinity,
              );
              final expenseWidth = sum == 0 ? 0.0 : available * expense / sum;
              final incomeWidth = sum == 0 ? 0.0 : available - expenseWidth;
              return Row(
                children: [
                  _segment(
                    const ValueKey('summaryRatio.expense'),
                    expenseWidth,
                    colors.exp,
                  ),
                  const SizedBox(width: _gap),
                  _segment(
                    const ValueKey('summaryRatio.income'),
                    incomeWidth,
                    colors.inc,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _segment(Key key, double width, Color color) => AnimatedContainer(
    key: key,
    duration: AnalysisMotion.emphasizedDuration,
    curve: AnalysisMotion.standardCurve,
    width: width,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}
