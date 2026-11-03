// Account sheet opened from the app-bar account filter button. Visual
// values from docs/design/analysis-redesign/Main.dc.html (lines 263-291,
// sheetItems in renderVals()). A bottom sheet below 600 dp, a Dialog at
// 600 dp and wider (plan D10).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../../core/utils/color_palette.dart';
import '../../../../../core/utils/icon_registry.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../domain/models/currency.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../view_models/account_filter_providers.dart';
import '../view_models/charts_selection_controller.dart';
import '../view_models/charts_state.dart' show PeriodType;
import 'period_selector.dart' show formatPeriodLabel;

/// Radio value of the "All accounts" row; account ids are positive.
const int _kAllAccounts = -1;

/// Opens the account sheet. Picking a row sets the account filter and
/// closes it.
@Dependencies([chartsAccountFilterOptions, ChartsSelectionController])
Future<void> showAccountFilterSheet(BuildContext context) {
  final colors = AnalysisColors.of(context);
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showDialog<void>(
      context: context,
      // The bottom sheet's 32% scrim (Main.dc.html:263), not black54.
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (_) => Dialog(
        backgroundColor: colors.card,
        surfaceTintColor: const Color(0x00000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const _AccountFilterSheet(showHandle: false),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The sheet paints its own card surface so it can carry the design's
    // shadow; Material elevation cannot draw a CSS box-shadow.
    backgroundColor: const Color(0x00000000),
    elevation: 0,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (_) => DecoratedBox(
      key: const ValueKey('accountFilterSheetSurface'),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        // 0 -2px 16px rgba(0,0,0,.12)
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            offset: Offset(0, -2),
            blurRadius: 16,
          ),
        ],
      ),
      child: const _AccountFilterSheet(showHandle: true),
    ),
  );
}

@Dependencies([chartsAccountFilterOptions, ChartsSelectionController])
class _AccountFilterSheet extends ConsumerStatefulWidget {
  const _AccountFilterSheet({required this.showHandle});

  /// The drag handle belongs to the bottom-sheet form only.
  final bool showHandle;

  @override
  ConsumerState<_AccountFilterSheet> createState() =>
      _AccountFilterSheetState();
}

class _AccountFilterSheetState extends ConsumerState<_AccountFilterSheet> {
  /// The rows on screen when a row was picked. The sheet keeps building
  /// while it animates closed, and the new filter can drop the archived
  /// account it was filtered by (D25); freezing the rows keeps that row
  /// in place so the list and the sheet do not jump mid-exit.
  ChartsAccountFilterOptions? _closingOptions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final selection = ref.watch(chartsSelectionControllerProvider);
    final optionsAsync = ref.watch(chartsAccountFilterOptionsProvider);
    final options = _closingOptions ?? optionsAsync.value;

    @Dependencies([ChartsSelectionController])
    void pick(int? value) {
      _closingOptions = options;
      ref
          .read(chartsSelectionControllerProvider.notifier)
          .setAccountFilter(
            value == null || value == _kAllAccounts ? null : value,
          );
      Navigator.of(context).pop();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHandle)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Center(
                child: Container(
                  key: const ValueKey('accountFilterHandle'),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            )
          else
            // The dialog has no handle; keep its 16 top inset.
            const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chartsFilterByAccount,
                  style: analysisText(
                    size: 20,
                    lineHeight: 28,
                    weight: FontWeight.w500,
                    color: colors.fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.chartsFilterSheetSubtitle(
                    selection.period == PeriodType.all
                        ? l10n.chartsAllTime
                        : formatPeriodLabel(
                            selection.period,
                            selection.anchorDate,
                            locale,
                          ),
                  ),
                  style: analysisText(
                    size: 14,
                    lineHeight: 20,
                    color: colors.fg2,
                  ),
                ),
              ],
            ),
          ),
          if (_closingOptions == null && optionsAsync.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(l10n.analysisErrorMessage)),
            )
          else if (options == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Flexible(
              child: RadioGroup<int>(
                groupValue: selection.accountFilterId ?? _kAllAccounts,
                onChanged: pick,
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: options.accounts.length + 1,
                  itemBuilder: (context, i) {
                    final row = i == 0
                        ? _AccountRow(
                            value: _kAllAccounts,
                            name: l10n.chartsAllAccounts,
                            subtitle: _subtitle(
                              options.totalMinorUnits,
                              options.totalMinorUnits > 0 ? 1 : 0,
                              options.currency,
                              locale,
                            ),
                            selected: selection.accountFilterId == null,
                            circleColor: colors.track,
                            icon: Icons.layers_outlined,
                            iconColor: colors.fg2,
                            onTap: () => pick(_kAllAccounts),
                          )
                        : _accountRow(
                            options.accounts[i - 1],
                            options.currency,
                            locale,
                            selected:
                                selection.accountFilterId ==
                                options.accounts[i - 1].accountId,
                            onTap: pick,
                          );
                    // Gap 2 between rows.
                    return i == 0
                        ? row
                        : Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: row,
                          );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const _darkInk = Color(0xFF1B1B1B);
  static const _lightInk = Color(0xFFFFFFFF);

  Widget _accountRow(
    ChartsAccountFilterOption option,
    Currency currency,
    String locale, {
    required bool selected,
    required ValueChanged<int> onTap,
  }) {
    final fill = colorForIndex(option.colorIndex);
    return _AccountRow(
      value: option.accountId,
      name: option.name,
      subtitle: _subtitle(
        option.totalMinorUnits,
        option.share,
        currency,
        locale,
      ),
      selected: selected,
      circleColor: fill,
      icon: iconForKey(option.iconKey),
      iconColor: fill.computeLuminance() > 0.35 ? _darkInk : _lightInk,
      onTap: () => onTap(option.accountId),
    );
  }

  String _subtitle(
    int minorUnits,
    double share,
    Currency currency,
    String locale,
  ) {
    final amount = MoneyFormatter.format(
      amountMinorUnits: minorUnits,
      currency: currency,
      locale: locale,
    );
    return '$amount · ${(share * 100).toStringAsFixed(1)}%';
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.value,
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.circleColor,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final int value;
  final String name;
  final String subtitle;
  final bool selected;
  final Color circleColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    return MergeSemantics(
      child: Material(
        key: const ValueKey('accountFilterRow'),
        color: selected ? colors.sel : colors.sel.withValues(alpha: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    key: const ValueKey('accountFilterIcon'),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: analysisText(
                            size: 16,
                            lineHeight: 22,
                            weight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: colors.fg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // The amount is never cut off: one line, scaled
                        // down only when it does not fit (D2).
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            softWrap: false,
                            style: analysisText(
                              size: 13,
                              lineHeight: 18,
                              color: colors.fg2,
                              tabular: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The design's 16 gap and 20 radio with a 4 end margin,
                  // around Flutter's 24 dp minimum-density radio.
                  const SizedBox(width: 14),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 2),
                    // The row's InkWell is the tab stop and takes every
                    // tap, so the selected row's radio closes the sheet
                    // too; the radio only shows and reports the checked
                    // state.
                    child: ExcludeFocus(
                      child: IgnorePointer(
                        child: Radio<int>(
                          value: value,
                          activeColor: colors.expText,
                          visualDensity: const VisualDensity(
                            horizontal: VisualDensity.minimumDensity,
                            vertical: VisualDensity.minimumDensity,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
