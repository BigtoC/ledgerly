// Period selector for the charts section. Renders prev/next arrows
// around the period label, plus a 4-way segmented toggle for
// Day/Week/Month/Year. See basic-charts spec § Period Selector.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../../../l10n/app_localizations.dart';
import '../charts_state.dart';

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

  String _formatLabel(BuildContext context) {
    switch (period) {
      case PeriodType.day:
        return DateHelpers.formatDisplayDate(anchorDate, locale);
      case PeriodType.week:
        final end = DateTime(
          anchorDate.year,
          anchorDate.month,
          anchorDate.day + 6,
        );
        final start = DateFormat.MMMd(locale).format(anchorDate);
        final endStr = DateFormat.MMMd(locale).format(end);
        return '$start–$endStr, ${anchorDate.year}';
      case PeriodType.month:
        return DateFormat.yMMMM(locale).format(anchorDate);
      case PeriodType.year:
        return DateFormat.y(locale).format(anchorDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous period',
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevious,
            ),
            Expanded(
              child: Center(
                child: Text(
                  _formatLabel(context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next period',
              icon: const Icon(Icons.chevron_right),
              onPressed: isAtCurrent ? null : onNext,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<PeriodType>(
          segments: [
            ButtonSegment(
              value: PeriodType.day,
              label: Text(l10n.chartsPeriodDay),
            ),
            ButtonSegment(
              value: PeriodType.week,
              label: Text(l10n.chartsPeriodWeek),
            ),
            ButtonSegment(
              value: PeriodType.month,
              label: Text(l10n.chartsPeriodMonth),
            ),
            ButtonSegment(
              value: PeriodType.year,
              label: Text(l10n.chartsPeriodYear),
            ),
          ],
          selected: {period},
          onSelectionChanged: (s) => onPeriodChanged(s.first),
        ),
      ],
    );
  }
}
