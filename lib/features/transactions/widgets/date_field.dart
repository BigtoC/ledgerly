// `DateField` — Wave 2 §4.1.
//
// Tile that displays the current transaction date and opens
// `showDatePicker` on tap. Uses `core/utils/date_helpers.dart` for the
// locale-aware display string.

import 'package:flutter/material.dart';

import '../../../core/utils/date_helpers.dart';
import '../../../l10n/app_localizations.dart';

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return ListTile(
      leading: const Icon(Icons.calendar_today_outlined),
      title: Text(l10n.txDateLabel),
      subtitle: Text(DateHelpers.formatDisplayDate(value, locale)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _pick(context),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      // Allow up to 5 years ago — covers backdated entries (PRD has no
      // explicit window, but unbounded picks are user-hostile).
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    onChanged(DateTime(picked.year, picked.month, picked.day));
  }
}
