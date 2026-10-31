// Day-navigation header — Wave 3 §6, §10.
//
// Prev (◀) — selected-day label — next (▶) grouped on the left, and a
// "Jump to today" button on the right. Chevrons disable at the
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
    this.showJumpToToday = false,
    this.onJumpToToday,
  });

  final DateTime selectedDay;
  final String locale;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickDay;
  final bool canGoPrev;
  final bool canGoNext;

  /// When true, the button at the right of the row reads "Jump to today"
  /// and is enabled; when false (already on today) it reads "Today" and
  /// is disabled.
  final bool showJumpToToday;

  /// Called when the "Jump to today" button is tapped.
  final VoidCallback? onJumpToToday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = DateHelpers.formatDayHeader(
      DateHelpers.startOfDay(selectedDay),
      locale,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      // Wrap keeps the date pill's room: when the row cannot hold both
      // groups (narrow phone, large text scale) the jump button moves to
      // its own line instead of squeezing the pill.
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Chevrons hug the pill on the left; the jump button takes the
            // right edge.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.homeDayNavPrevLabel,
                  onPressed: canGoPrev ? onPrev : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Flexible(
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                IconButton(
                  tooltip: l10n.homeDayNavNextLabel,
                  onPressed: canGoNext ? onNext : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            TextButton(
              key: const ValueKey('homeDayHeader.jumpToToday'),
              onPressed: showJumpToToday ? onJumpToToday : null,
              child: Text(
                showJumpToToday ? l10n.homeJumpToToday : l10n.homeDayLabelToday,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
