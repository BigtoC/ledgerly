// Period selector for the charts section: a period track (one segment per
// PeriodType) above a navigator (prev / label + caption / next). Visual values
// from docs/design/analysis-redesign/Main.dc.html (lines 50-69, tabs style and
// prev/nextStyle in renderVals()). On All the chevrons are hidden but keep
// their slots, and the caption is the covered range. On the other periods the
// label is a button that opens the period picker (pkLabelBtnStyle and
// pkCaretStyle in renderVals()).

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../view_models/charts_range_providers.dart';
import '../view_models/charts_state.dart';

final Map<String, DateFormat> _dateFormats = {};

/// A [DateFormat] for [skeleton] (or pattern) and [locale], built once and
/// cached: never build one per row or cell.
DateFormat periodDateFormat(String skeleton, String locale) => _dateFormats
    .putIfAbsent('$skeleton|$locale', () => DateFormat(skeleton, locale));

/// The navigator's period label, e.g. `May 18–May 24, 2026` for a week.
///
/// All has no date label: show `AppLocalizations.chartsAllTime` instead.
/// Passing [PeriodType.all] throws an [ArgumentError].
String formatPeriodLabel(
  PeriodType period,
  DateTime anchorDate,
  String locale,
) {
  switch (period) {
    case PeriodType.day:
      return periodDateFormat(
        DateFormat.YEAR_ABBR_MONTH_DAY,
        locale,
      ).format(anchorDate);
    case PeriodType.week:
      final end = DateTime(
        anchorDate.year,
        anchorDate.month,
        anchorDate.day + 6,
      );
      final monthDay = periodDateFormat(DateFormat.ABBR_MONTH_DAY, locale);
      final start = monthDay.format(anchorDate);
      final endStr = monthDay.format(end);
      return '$start–$endStr, ${anchorDate.year}';
    case PeriodType.month:
      return periodDateFormat(DateFormat.YEAR_MONTH, locale).format(anchorDate);
    case PeriodType.year:
      return periodDateFormat(DateFormat.YEAR, locale).format(anchorDate);
    case PeriodType.all:
      throw ArgumentError.value(period, 'period', 'All has no date label');
  }
}

/// All's caption: the months the range covers, e.g. `Jan 2025 – Oct 2026`.
/// Null for an empty range (no transactions).
String? _allTimeCaption(ChartsRange range, String locale) {
  if (!range.start.isBefore(range.end)) return null;
  final month = periodDateFormat(DateFormat.YEAR_ABBR_MONTH, locale);
  final last = DateTime(range.end.year, range.end.month - 1);
  return '${month.format(range.start)} – ${month.format(last)}';
}

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.period,
    required this.anchorDate,
    required this.isAtCurrent,
    required this.locale,
    required this.onPrevious,
    required this.onNext,
    required this.onPeriodChanged,
    required this.onPick,
    required this.pickerOpen,
    this.allTimeRange,
  });

  final PeriodType period;
  final DateTime anchorDate;
  final bool isAtCurrent;

  /// All's resolved range, for its caption; null while it loads.
  final ChartsRange? allTimeRange;
  final String locale;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<PeriodType> onPeriodChanged;

  /// Opens the period picker; ignored on All, which has none.
  final VoidCallback onPick;

  /// Whether the period picker is open, for the label's caret.
  final bool pickerOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = period == PeriodType.all;
    final range = allTimeRange;
    final caption = switch (period) {
      PeriodType.all => range == null ? null : _allTimeCaption(range, locale),
      _ when !isAtCurrent => null,
      PeriodType.day => l10n.chartsCaptionToday,
      PeriodType.week => l10n.chartsCaptionThisWeek,
      PeriodType.month => l10n.chartsCaptionThisMonth,
      PeriodType.year => l10n.chartsCaptionThisYear,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeriodTrack(period: period, onPeriodChanged: onPeriodChanged),
        PeriodNavigator(
          label: all
              ? l10n.chartsAllTime
              : formatPeriodLabel(period, anchorDate, locale),
          caption: caption,
          showChevrons: !all,
          onPrevious: onPrevious,
          onNext: isAtCurrent ? null : onNext,
          pickerTitle: switch (period) {
            PeriodType.day => l10n.chartsPickDay,
            PeriodType.week => l10n.chartsPickWeek,
            PeriodType.month => l10n.chartsPickMonth,
            PeriodType.year => l10n.chartsPickYear,
            PeriodType.all => null,
          },
          onPick: all ? null : onPick,
          open: pickerOpen,
        ),
      ],
    );
  }
}

/// One equal column per [PeriodType] on a rounded track; the selected
/// segment is a raised thumb.
class PeriodTrack extends StatelessWidget {
  const PeriodTrack({
    super.key,
    required this.period,
    required this.onPeriodChanged,
  });

  final PeriodType period;
  final ValueChanged<PeriodType> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: colors.track,
          borderRadius: BorderRadius.circular(25),
        ),
        // Segments share the tallest one's height when a label grows at
        // large text scales, like the design's grid row.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 2,
            children: [
              for (final p in PeriodType.values)
                Expanded(
                  child: _PeriodSegment(
                    label: switch (p) {
                      PeriodType.day => l10n.chartsPeriodDay,
                      PeriodType.week => l10n.chartsPeriodWeek,
                      PeriodType.month => l10n.chartsPeriodMonth,
                      PeriodType.year => l10n.chartsPeriodYear,
                      PeriodType.all => l10n.chartsPeriodAll,
                    },
                    selected: p == period,
                    onTap: () => onPeriodChanged(p),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: AnalysisMotion.standardDuration,
        curve: AnalysisMotion.standardCurve,
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          color: selected ? colors.thumb : colors.thumb.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected ? colors.thumbShadow : const <BoxShadow>[],
        ),
        // The ink paints on this Material, above the thumb's fill (plan D16).
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            // One line, shrunk only when it would not fit (plan D23).
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    color: selected ? colors.fg : colors.fg2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Previous / next chevrons around the period label and its caption.
/// A null [onNext] disables the next chevron (at the current period).
/// Without [showChevrons] both are hidden but keep their 48 px slots, so
/// the label stays centred. With [onPick] the label and caption are one
/// button with a caret that opens the period picker; [open] fills it and
/// turns the caret up while the picker is open.
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.label,
    required this.caption,
    required this.onPrevious,
    required this.onNext,
    this.showChevrons = true,
    this.pickerTitle,
    this.onPick,
    this.open = false,
  });

  final String label;
  final String? caption;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final bool showChevrons;

  /// The picker's title, which starts the button's screen-reader name.
  final String? pickerTitle;

  /// Null on All: a plain label with no caret.
  final VoidCallback? onPick;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    final labelText = Text(
      label,
      textAlign: TextAlign.center,
      style: analysisText(
        size: 18,
        lineHeight: 24,
        weight: FontWeight.w500,
        color: colors.fg,
      ),
    );
    final captionText = switch (caption) {
      final caption? => Text(
        caption,
        textAlign: TextAlign.center,
        style: analysisText(size: 12, lineHeight: 16, color: colors.fg3),
      ),
      null => null,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        spacing: 4,
        children: [
          if (showChevrons)
            PeriodNavButton(
              icon: Icons.chevron_left,
              tooltip: l10n.chartsPreviousPeriod,
              onPressed: onPrevious,
            )
          else
            const SizedBox.square(dimension: 48),
          Expanded(
            child: switch (onPick) {
              null => Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [labelText, ?captionText],
              ),
              final onPick => Center(
                child: Semantics(
                  container: true,
                  button: true,
                  expanded: open,
                  label: l10n.chartsPickerOpenLabel(pickerTitle ?? '', label),
                  onTap: onPick,
                  excludeSemantics: true,
                  child: AnimatedContainer(
                    duration: AnalysisMotion.standardDuration,
                    curve: AnalysisMotion.standardCurve,
                    decoration: BoxDecoration(
                      color: open
                          ? colors.sel
                          : colors.sel.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // The ink paints above the open fill.
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: onPick,
                        borderRadius: BorderRadius.circular(16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 2,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 4,
                                  children: [
                                    Flexible(child: labelText),
                                    AnimatedRotation(
                                      turns: open ? 0.5 : 0,
                                      duration: AnalysisMotion.standardDuration,
                                      curve: AnalysisMotion.standardCurve,
                                      child: Icon(
                                        Icons.expand_more,
                                        size: 18,
                                        color: colors.fg2,
                                      ),
                                    ),
                                  ],
                                ),
                                ?captionText,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            },
          ),
          if (showChevrons)
            PeriodNavButton(
              icon: Icons.chevron_right,
              tooltip: l10n.chartsNextPeriod,
              onPressed: onNext,
            )
          else
            const SizedBox.square(dimension: 48),
        ],
      ),
    );
  }
}

/// A 48×48 period chevron, `fg`, `off` when disabled.
class PeriodNavButton extends StatelessWidget {
  const PeriodNavButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 24,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(48),
        minimumSize: const Size.square(48),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        foregroundColor: colors.fg,
        disabledForegroundColor: colors.off,
      ),
    );
  }
}
