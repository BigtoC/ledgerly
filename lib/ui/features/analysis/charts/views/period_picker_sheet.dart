// Period picker opened from the Analysis period label (issue #73): pick a
// day, week, month or year of the selected period type. Behaviour from
// docs/superpowers/specs/2026-11-03-analysis-period-picker-design.md; visual
// values from docs/design/analysis-redesign/Main.dc.html (pkShow markup, PK
// block in renderVals()). A bottom sheet below 600 dp, a Dialog at 600 dp
// and wider, presented like the account sheet.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../../core/utils/date_helpers.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../view_models/charts_range_providers.dart';
import '../view_models/charts_selection_controller.dart';
import '../view_models/charts_state.dart' show PeriodType;
import 'analysis_sheet.dart';
import 'period_selector.dart'
    show PeriodNavButton, formatPeriodLabel, periodDateFormat;

enum _View { days, weeks, months, years }

/// Opens the period picker for the selected period. A pick sets the anchor
/// and closes it; dismissing it changes nothing.
@Dependencies([chartsDateBounds, ChartsSelectionController])
Future<void> showPeriodPicker(BuildContext context) {
  return showAnalysisSheet(
    context,
    surfaceKey: const ValueKey('periodPickerSheetSurface'),
    builder: (showHandle) => PeriodPickerSheet(showHandle: showHandle),
  );
}

/// The picker's content. Opens on the selected period's view and month or
/// year; picking a cell of the period's own unit, or Now, applies it through
/// [ChartsSelectionController.setAnchor] and closes the route.
@Dependencies([chartsDateBounds, ChartsSelectionController])
class PeriodPickerSheet extends ConsumerStatefulWidget {
  const PeriodPickerSheet({super.key, required this.showHandle});

  /// The drag handle belongs to the bottom-sheet form only.
  final bool showHandle;

  @override
  ConsumerState<PeriodPickerSheet> createState() => _PeriodPickerSheetState();
}

class _PeriodPickerSheetState extends ConsumerState<PeriodPickerSheet> {
  /// Browsing state, dropped on close: the next open starts again from the
  /// selected period.
  late _View _view;
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final selection = ref.read(chartsSelectionControllerProvider);
    _view = switch (selection.period) {
      PeriodType.day => _View.days,
      PeriodType.week => _View.weeks,
      PeriodType.month => _View.months,
      PeriodType.year || PeriodType.all => _View.years,
    };
    // For Week the anchor is its Monday, so this is the Monday's month.
    _year = selection.anchorDate.year;
    _month = selection.anchorDate.month;
  }

  @Dependencies([ChartsSelectionController])
  void _apply(DateTime date) {
    ref.read(chartsSelectionControllerProvider.notifier).setAnchor(date);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final selection = ref.watch(chartsSelectionControllerProvider);
    final period = selection.period;
    final anchor = selection.anchorDate;
    // Null with no transactions, and while the bounds load or after they
    // fail: then the lower bound is the anchor's month and there is no
    // footnote.
    final first = ref.watch(chartsDateBoundsProvider).value?.first;

    final now = DateTime.now();
    final today = DateHelpers.startOfDay(now);
    final thisMonth = DateHelpers.startOfMonth(now);
    // Lower bound L: the earlier of the first record's month and the
    // anchor's month, so the picker never opens on a disabled selection
    // after ‹ stepped back past the first record.
    final anchorMonth = DateHelpers.startOfMonth(anchor);
    final recordMonth = first == null ? null : DateHelpers.startOfMonth(first);
    final low = recordMonth != null && recordMonth.isBefore(anchorMonth)
        ? recordMonth
        : anchorMonth;

    final yearFormat = periodDateFormat(DateFormat.YEAR, locale);
    final browsed = DateTime(_year, _month);
    final inMonth = _view == _View.days || _view == _View.weeks;
    final browseTitle = switch (_view) {
      _View.days || _View.weeks => periodDateFormat(
        DateFormat.YEAR_MONTH,
        locale,
      ).format(browsed),
      _View.months => yearFormat.format(browsed),
      _View.years =>
        '${yearFormat.format(DateTime(low.year))} – '
            '${yearFormat.format(DateTime(now.year))}',
    };
    final previousOff = inMonth ? !browsed.isAfter(low) : _year <= low.year;
    final nextOff = inMonth ? !browsed.isBefore(thisMonth) : _year >= now.year;

    final title = switch (period) {
      PeriodType.day => l10n.chartsPickDay,
      PeriodType.week => l10n.chartsPickWeek,
      PeriodType.month => l10n.chartsPickMonth,
      PeriodType.year || PeriodType.all => l10n.chartsPickYear,
    };
    final nowLabel = switch (period) {
      PeriodType.day => l10n.chartsCaptionToday,
      PeriodType.week => l10n.chartsCaptionThisWeek,
      PeriodType.month => l10n.chartsCaptionThisMonth,
      PeriodType.year || PeriodType.all => l10n.chartsCaptionThisYear,
    };

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: analysisText(
                        size: 20,
                        lineHeight: 28,
                        weight: FontWeight.w500,
                        color: colors.fg,
                      ),
                    ),
                  ),
                  Text(
                    l10n.chartsPickerSelected(
                      period == PeriodType.all
                          ? l10n.chartsAllTime
                          : formatPeriodLabel(period, anchor, locale),
                    ),
                    style: analysisText(
                      size: 14,
                      lineHeight: 20,
                      color: colors.fg2,
                      tabular: true,
                    ),
                  ),
                ],
              ),
            ),
            // flex: none like the design; capped at half the width so large
            // text cannot squeeze the title until it breaks inside a word.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
              child: TextButton(
                onPressed: () => _apply(DateTime.now()),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: const StadiumBorder(),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.standard,
                  foregroundColor: colors.expText,
                  textStyle: analysisText(
                    size: 14,
                    lineHeight: 20,
                    weight: FontWeight.w500,
                    color: colors.expText,
                  ),
                ),
                child: Text(nowLabel),
              ),
            ),
          ],
        ),
      ),
    );

    final titleStyle = analysisText(
      size: 16,
      lineHeight: 22,
      weight: FontWeight.w500,
      color: colors.fg,
    );
    final browseBar = Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
      child: Row(
        spacing: 4,
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _view == _View.years
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Align(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: Text(browseTitle, style: titleStyle),
                        ),
                      ),
                    )
                  : _BrowseTitleButton(
                      title: browseTitle,
                      semanticsLabel: inMonth
                          ? l10n.chartsPickerChooseMonth(browseTitle)
                          : l10n.chartsPickerChooseYear(browseTitle),
                      style: titleStyle,
                      onTap: () => setState(
                        () => _view = inMonth ? _View.months : _View.years,
                      ),
                    ),
            ),
          ),
          if (_view != _View.years) ...[
            PeriodNavButton(
              icon: Icons.chevron_left,
              tooltip: inMonth
                  ? l10n.chartsPickerPreviousMonth
                  : l10n.chartsPickerPreviousYear,
              onPressed: previousOff ? null : () => _step(inMonth, -1),
            ),
            PeriodNavButton(
              icon: Icons.chevron_right,
              tooltip: inMonth
                  ? l10n.chartsPickerNextMonth
                  : l10n.chartsPickerNextYear,
              onPressed: nextOff ? null : () => _step(inMonth, 1),
            ),
          ],
        ],
      ),
    );

    final body = switch (_view) {
      _View.days => _daysView(locale, anchor, period, today, low),
      _View.weeks => _weeksView(l10n, locale, anchor, today, low),
      _View.months => _monthsView(locale, anchor, period, thisMonth, low),
      _View.years => _yearsView(locale, anchor, period, now, low),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalysisSheetHandle(
            showHandle: widget.showHandle,
            handleKey: const ValueKey('periodPickerHandle'),
          ),
          // Everything below scrolls when large text makes it taller than
          // the sheet.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  browseBar,
                  body,
                  if (first != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Text(
                        l10n.chartsPickerRecordsStart(
                          periodDateFormat(
                            DateFormat.YEAR_ABBR_MONTH_DAY,
                            locale,
                          ).format(first),
                        ),
                        style: analysisText(
                          size: 12,
                          lineHeight: 16,
                          color: colors.fg3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ‹ › in the browse bar: one month on Days / Weeks, one year on Months.
  void _step(bool inMonth, int delta) {
    setState(() {
      if (inMonth) {
        final month = DateTime(_year, _month + delta);
        _year = month.year;
        _month = month.month;
      } else {
        _year += delta;
      }
    });
  }

  Widget _daysView(
    String locale,
    DateTime anchor,
    PeriodType period,
    DateTime today,
    DateTime low,
  ) {
    final dayLabel = periodDateFormat(DateFormat.YEAR_MONTH_DAY, locale);
    final firstDay = DateTime(_year, _month);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    // Blank cells before the 1st, Monday first.
    final cells = <Widget>[
      for (var i = 1; i < firstDay.weekday; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        Builder(
          builder: (context) {
            final date = DateTime(_year, _month, d);
            final off = date.isAfter(today) || date.isBefore(low);
            return _DayCell(
              label: '$d',
              semanticsLabel: dayLabel.format(date),
              selected: period == PeriodType.day && date == anchor,
              today: date == today,
              disabled: off,
              onTap: () => _apply(date),
            );
          },
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeekdayHeader(locale: locale),
          // Row gap 2 between day rows only, not under the header.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 2,
            children: [
              for (var row = 0; row < cells.length; row += 7)
                Row(
                  children: [
                    for (var i = row; i < row + 7; i++)
                      Expanded(
                        child: i < cells.length ? cells[i] : const SizedBox(),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weeksView(
    AppLocalizations l10n,
    String locale,
    DateTime anchor,
    DateTime today,
    DateTime low,
  ) {
    final monthEnd = DateTime(_year, _month + 1, 0);
    final thisWeek = DateHelpers.startOfWeek(today);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeekdayHeader(
            locale: locale,
            weekColumn: l10n.chartsPickerWeekColumn,
          ),
          // Gap 4 between week rows only, not under the header.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              // One row per Monday-start week that touches the browsed month.
              for (
                var start = DateHelpers.startOfWeek(DateTime(_year, _month));
                !start.isAfter(monthEnd);
                start = DateTime(start.year, start.month, start.day + 7)
              )
                Builder(
                  builder: (context) {
                    final monday = start;
                    final end = DateTime(
                      monday.year,
                      monday.month,
                      monday.day + 6,
                    );
                    final week = DateHelpers.isoWeekNumber(monday);
                    return _WeekRow(
                      start: monday,
                      weekLabel: l10n.chartsPickerWeekNumber(week),
                      semanticsLabel: l10n.chartsPickerWeekRow(
                        week,
                        formatPeriodLabel(PeriodType.week, monday, locale),
                      ),
                      browsedMonth: _month,
                      today: today,
                      selected: monday == anchor,
                      current: monday == thisWeek,
                      disabled: monday.isAfter(today) || end.isBefore(low),
                      onTap: () => _apply(monday),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthsView(
    String locale,
    DateTime anchor,
    PeriodType period,
    DateTime thisMonth,
    DateTime low,
  ) {
    final short = periodDateFormat(DateFormat.ABBR_MONTH, locale);
    final full = periodDateFormat(DateFormat.YEAR_MONTH, locale);
    return _PillGrid(
      cells: [
        for (var m = 1; m <= 12; m++)
          Builder(
            builder: (context) {
              final month = DateTime(_year, m);
              return _PillCell(
                label: short.format(month),
                semanticsLabel: full.format(month),
                selected: anchor.year == _year && anchor.month == m,
                current: month == thisMonth,
                disabled: month.isAfter(thisMonth) || month.isBefore(low),
                onTap: () => period == PeriodType.month
                    ? _apply(month)
                    : setState(() {
                        _month = m;
                        _view = period == PeriodType.day
                            ? _View.days
                            : _View.weeks;
                      }),
              );
            },
          ),
      ],
    );
  }

  Widget _yearsView(
    String locale,
    DateTime anchor,
    PeriodType period,
    DateTime now,
    DateTime low,
  ) {
    final yearFormat = periodDateFormat(DateFormat.YEAR, locale);
    return _PillGrid(
      cells: [
        for (var y = low.year; y <= now.year; y++)
          Builder(
            builder: (context) {
              final year = y;
              final label = yearFormat.format(DateTime(year));
              return _PillCell(
                label: label,
                semanticsLabel: label,
                selected: anchor.year == year,
                current: year == now.year,
                disabled: false,
                onTap: () => period == PeriodType.year
                    ? _apply(DateTime(year))
                    : setState(() {
                        _year = year;
                        _view = _View.months;
                      }),
              );
            },
          ),
      ],
    );
  }
}

/// Narrow weekday names, Monday first to match [DateHelpers.startOfWeek],
/// with an optional leading 40-wide week-number column.
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.locale, this.weekColumn});

  final String locale;
  final String? weekColumn;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    final style = analysisText(
      size: 12,
      lineHeight: 16,
      weight: FontWeight.w500,
      color: colors.fg3,
    );
    final narrow = periodDateFormat('EEEEE', locale);
    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Row(
          children: [
            if (weekColumn case final weekColumn?)
              SizedBox(
                width: 40,
                child: Text(
                  weekColumn,
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  // Jan 1, 2024 is a Monday.
                  narrow.format(DateTime(2024, 1, 1 + i)),
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A 44-high cell holding a 40×40 circle that grows with large text.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.today,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final bool today;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: !disabled,
      label: semanticsLabel,
      onTap: disabled ? null : onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: disabled ? null : onTap,
        radius: 22,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: AnimatedContainer(
              duration: AnalysisMotion.standardDuration,
              curve: AnalysisMotion.standardCurve,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              decoration: ShapeDecoration(
                color: selected
                    ? colors.onBg
                    : colors.onBg.withValues(alpha: 0),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: today && !selected
                        ? colors.fg
                        : colors.fg.withValues(alpha: 0),
                  ),
                ),
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  label,
                  style: analysisText(
                    size: 14,
                    lineHeight: 20,
                    weight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: selected
                        ? colors.onFg
                        : disabled
                        ? colors.off
                        : colors.fg,
                    tabular: true,
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

/// One Monday-start week: the ISO week number, then its seven day numbers.
/// The whole row is the tap target.
class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.start,
    required this.weekLabel,
    required this.semanticsLabel,
    required this.browsedMonth,
    required this.today,
    required this.selected,
    required this.current,
    required this.disabled,
    required this.onTap,
  });

  final DateTime start;
  final String weekLabel;
  final String semanticsLabel;
  final int browsedMonth;
  final DateTime today;
  final bool selected;
  final bool current;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    final shape = StadiumBorder(
      side: BorderSide(
        color: current && !selected
            ? colors.fg
            : colors.fg.withValues(alpha: 0),
      ),
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: !disabled,
      label: semanticsLabel,
      onTap: disabled ? null : onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.onBg : colors.onBg.withValues(alpha: 0),
        shape: shape,
        animationDuration: AnalysisMotion.standardDuration,
        child: InkWell(
          customBorder: shape,
          onTap: disabled ? null : onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    weekLabel,
                    textAlign: TextAlign.center,
                    // The design fixes this column at 40, so the number
                    // clamps at 1.5× rather than break inside "W38".
                    textScaler: MediaQuery.textScalerOf(context)
                        .clamp(maxScaleFactor: 1.5),
                    style: analysisText(
                      size: 11,
                      lineHeight: 16,
                      weight: FontWeight.w500,
                      color: selected
                          ? colors.onFg
                          : disabled
                          ? colors.off
                          : colors.fg3,
                    ),
                  ),
                ),
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final day = DateTime(
                          start.year,
                          start.month,
                          start.day + i,
                        );
                        return Text(
                          '${day.day}',
                          textAlign: TextAlign.center,
                          style: analysisText(
                            size: 14,
                            lineHeight: 20,
                            weight: selected
                                ? FontWeight.w500
                                : FontWeight.w400,
                            // A selected row never fades its labels.
                            color: selected
                                ? colors.onFg
                                : disabled || day.isAfter(today)
                                ? colors.off
                                : day.month != browsedMonth
                                ? colors.fg3
                                : colors.fg,
                            tabular: true,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Months and Years grid: 3 columns, gap 8, padding 8 16 0.
class _PillGrid extends StatelessWidget {
  const _PillGrid({required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          for (var row = 0; row < cells.length; row += 3)
            Row(
              spacing: 8,
              children: [
                for (var i = row; i < row + 3; i++)
                  Expanded(
                    child: i < cells.length ? cells[i] : const SizedBox(),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A 52-high pill with a 1px border: a month or a year.
class _PillCell extends StatelessWidget {
  const _PillCell({
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.current,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final bool current;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: !disabled,
      label: semanticsLabel,
      onTap: disabled ? null : onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AnalysisMotion.standardDuration,
        curve: AnalysisMotion.standardCurve,
        // 52 high including the 1px border, like CSS border-box.
        constraints: const BoxConstraints(minHeight: 52),
        decoration: ShapeDecoration(
          color: selected ? colors.onBg : colors.onBg.withValues(alpha: 0),
          shape: StadiumBorder(
            side: BorderSide(
              color: selected
                  ? colors.onBg
                  : current
                  ? colors.fg
                  : colors.line,
            ),
          ),
        ),
        // The ink paints above the pill's fill.
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: disabled ? null : onTap,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: analysisText(
                  size: 15,
                  lineHeight: 20,
                  weight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: selected
                      ? colors.onFg
                      : disabled
                      ? colors.off
                      : colors.fg,
                  tabular: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The browsed month or year with a caret; tapping it drills up.
class _BrowseTitleButton extends StatelessWidget {
  const _BrowseTitleButton({
    required this.title,
    required this.semanticsLabel,
    required this.style,
    required this.onTap,
  });

  final String title;
  final String semanticsLabel;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    return Semantics(
      container: true,
      button: true,
      label: semanticsLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Flexible(child: Text(title, style: style)),
                Icon(Icons.expand_more, size: 18, color: colors.fg2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
