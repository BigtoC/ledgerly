// Day-navigation header — Wave 3 §6, §10.
//
// Prev (◀) — selected-day label — next (▶). Chevrons disable at the
// boundaries (no older / newer activity day). The selected-day label
// is tappable and opens a manual `showDatePicker` so the user can jump
// to any day in range.

import 'package:flutter/material.dart';

import '../../../core/utils/date_helpers.dart';
import '../../../l10n/app_localizations.dart';

class DayNavigationHeader extends StatelessWidget {
  const DayNavigationHeader({
    super.key,
    required this.selectedDay,
    required this.locale,
    required this.onPrev,
    required this.onNext,
    required this.onPickDay,
    required this.canGoPrev,
    required this.canGoNext,
  });

  final DateTime selectedDay;
  final String locale;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickDay;
  final bool canGoPrev;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = DateHelpers.startOfDay(DateTime.now());
    final selDay = DateHelpers.startOfDay(selectedDay);

    final label = DateHelpers.isSameDay(selDay, today)
        ? l10n.homeDayLabelToday
        : DateHelpers.formatDayHeader(selDay, locale);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.homeDayNavPrevLabel,
            onPressed: canGoPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: Tooltip(
                message: label,
                // Pill filled with the home cards' colour so the label
                // reads as part of the same card family.
                child: TextButton(
                  key: const ValueKey('homeDayHeader.pickDay'),
                  onPressed: onPickDay,
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainer,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.homeDayNavNextLabel,
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
