// `DateField` — Wave 2 §4.1.
//
// Half-width tile (no chevron; issue #100) that displays the current
// transaction date and opens `showDatePicker` on tap. Uses
// `core/utils/date_helpers.dart` for the locale-aware display string.

import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../../../l10n/app_localizations.dart';

class const DateField({
  super.key,
  required final DateTime value,
  required final ValueChanged<DateTime> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return ListTile(
      leading: const Icon(Icons.calendar_today_outlined),
      title: Text(l10n.txDateLabel),
      subtitle: Text(DateHelpers.formatDisplayDate(value, locale)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      horizontalTitleGap: 12,
      visualDensity: VisualDensity.compact,
      onTap: () => _pick(context),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(1900),
      lastDate: DateTime(9999, 12, 31),
    );
    if (picked == null) return;
    onChanged(picked);
  }
}
