// `CurrencySelectorTile` — Chunk 4 Task 8 Step 5.
//
// Half-width tile (no chevron; issue #100) that shows the selected
// transaction currency code. Tap opens the currency picker sheet.

import 'package:material_ui/material_ui.dart';

import '../../../../domain/models/currency.dart';
import '../../../../l10n/app_localizations.dart';

class const CurrencySelectorTile({
  super.key,
  required final Currency currency,

  /// Called when the user taps the tile.
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      leading: const Icon(Icons.currency_exchange),
      title: Text(l10n.txCurrencyLabel),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              currency.code,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      horizontalTitleGap: 12,
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}
