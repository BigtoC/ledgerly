// `CurrencySelectorTile` — Chunk 4 Task 8 Step 5.
//
// Tile that shows the selected transaction currency code. Tap opens the
// currency picker sheet. When `currency` is null (before an account is
// selected), the tile renders in a disabled state with a `—` placeholder.

import 'package:flutter/material.dart';

import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';

class CurrencySelectorTile extends StatelessWidget {
  const CurrencySelectorTile({
    super.key,
    required this.currency,
    required this.onTap,
  });

  final Currency? currency;

  /// Called when the user taps the tile. `null` when `currency` is null
  /// (tile is disabled until an account is selected).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = currency;
    if (c == null) {
      return ListTile(
        leading: const Icon(Icons.currency_exchange),
        title: Text(l10n.txCurrencyLabel),
        subtitle: const Text('—'),
        trailing: const Icon(Icons.chevron_right),
        onTap: null,
      );
    }
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
              c.code,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
