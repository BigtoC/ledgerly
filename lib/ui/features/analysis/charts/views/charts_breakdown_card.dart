import 'package:material_ui/material_ui.dart';

import '../../../../../domain/models/category.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../view_models/charts_state.dart';
import 'dimension_toggle.dart';

/// Breakdown card: "Expense/Income breakdown" title and the dimension
/// chips above [child] (donut + ranked rows, the empty state, or a
/// loading / blocked / error body). Carries no horizontal margin; the
/// charts section provides it.
class ChartsBreakdownCard extends StatelessWidget {
  const ChartsBreakdownCard({
    super.key,
    required this.type,
    required this.dimension,
    required this.onDimensionChanged,
    required this.child,
  });

  final CategoryType type;
  final ChartDimension dimension;
  final ValueChanged<ChartDimension> onDimensionChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == CategoryType.income
                      ? l10n.chartsBreakdownIncome
                      : l10n.chartsBreakdownExpense,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: analysisText(
                    size: 16,
                    lineHeight: 24,
                    weight: FontWeight.w500,
                    color: colors.fg,
                  ),
                ),
                const SizedBox(height: 4),
                DimensionChips(
                  dimension: dimension,
                  onChanged: onDimensionChanged,
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Breakdown body when the period has no transactions of [type].
class BreakdownEmptyState extends StatelessWidget {
  const BreakdownEmptyState({super.key, required this.type, this.accountName});

  final CategoryType type;

  /// The filtered account's name; null = all accounts.
  final String? accountName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    final isIncome = type == CategoryType.income;
    final account = accountName;
    final title = account != null
        ? (isIncome
              ? l10n.chartsEmptyTitleAccountIncome(account)
              : l10n.chartsEmptyTitleAccountExpense(account))
        : (isIncome
              ? l10n.chartsEmptyTitleIncome
              : l10n.chartsEmptyTitleExpense);
    final subtitle = account != null
        ? l10n.chartsEmptyPickAnother
        : l10n.chartsEmptySwitchType(
            isIncome ? l10n.chartsTypeExpense : l10n.chartsTypeIncome,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.track,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bar_chart, size: 22, color: colors.fg2),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: analysisText(
              size: 15,
              lineHeight: 20,
              weight: FontWeight.w500,
              color: colors.fg,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: analysisText(size: 13, lineHeight: 18, color: colors.fg2),
          ),
        ],
      ),
    );
  }
}
