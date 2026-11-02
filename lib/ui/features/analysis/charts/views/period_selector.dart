// Period selector for the charts section: a period track (one segment per
// PeriodType) above a navigator (prev / label + caption / next). Visual values
// from docs/design/analysis-redesign/Main.dc.html (lines 50-69, tabs style and
// prev/nextStyle in renderVals()).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../view_models/charts_state.dart';

final Map<String, DateFormat> _dateFormats = {};

DateFormat _dateFormat(String skeleton, String locale) => _dateFormats
    .putIfAbsent('$skeleton|$locale', () => DateFormat(skeleton, locale));

/// The navigator's period label, e.g. `May 18–May 24, 2026` for a week.
String formatPeriodLabel(
  PeriodType period,
  DateTime anchorDate,
  String locale,
) {
  switch (period) {
    case PeriodType.day:
      return _dateFormat(
        DateFormat.YEAR_ABBR_MONTH_DAY,
        locale,
      ).format(anchorDate);
    case PeriodType.week:
      final end = DateTime(
        anchorDate.year,
        anchorDate.month,
        anchorDate.day + 6,
      );
      final monthDay = _dateFormat(DateFormat.ABBR_MONTH_DAY, locale);
      final start = monthDay.format(anchorDate);
      final endStr = monthDay.format(end);
      return '$start–$endStr, ${anchorDate.year}';
    case PeriodType.month:
      return _dateFormat(DateFormat.YEAR_MONTH, locale).format(anchorDate);
    case PeriodType.year:
      return _dateFormat(DateFormat.YEAR, locale).format(anchorDate);
  }
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
  });

  final PeriodType period;
  final DateTime anchorDate;
  final bool isAtCurrent;
  final String locale;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<PeriodType> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final caption = !isAtCurrent
        ? null
        : switch (period) {
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
          label: formatPeriodLabel(period, anchorDate, locale),
          caption: caption,
          onPrevious: onPrevious,
          onNext: isAtCurrent ? null : onNext,
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
        // Segments share the tallest one's height when a label wraps at
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
          color: selected ? colors.thumb : const Color(0x00000000),
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected ? colors.thumbShadow : const <BoxShadow>[],
        ),
        // The ink paints on this Material, above the thumb's fill (plan D16).
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
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
    );
  }
}

/// Previous / next chevrons around the period label and its caption.
/// A null [onNext] disables the next chevron (at the current period).
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.label,
    required this.caption,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final String? caption;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        spacing: 4,
        children: [
          _NavButton(
            icon: Icons.chevron_left,
            tooltip: 'Previous period',
            onPressed: onPrevious,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: analysisText(
                    size: 18,
                    lineHeight: 24,
                    weight: FontWeight.w500,
                    color: colors.fg,
                  ),
                ),
                if (caption case final caption?)
                  Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: analysisText(
                      size: 12,
                      lineHeight: 16,
                      color: colors.fg3,
                    ),
                  ),
              ],
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right,
            tooltip: 'Next period',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
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
