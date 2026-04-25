// `AccountSelectorTile` — Wave 2 §4.1.
//
// Tile that shows the selected account's name + currency code. Tap
// opens the account picker sheet (caller decides whether the result
// triggers the currency-change confirm dialog).

import 'package:flutter/material.dart';

import '../../../data/models/account.dart';
import '../../../l10n/app_localizations.dart';

class AccountSelectorTile extends StatelessWidget {
  const AccountSelectorTile({
    super.key,
    required this.account,
    required this.onTap,
    this.hasError = false,
  });

  final Account? account;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tileColor = hasError ? theme.colorScheme.errorContainer : null;
    final a = account;
    if (a == null) {
      return ListTile(
        leading: Icon(
          Icons.account_balance_wallet_outlined,
          color: hasError ? theme.colorScheme.error : null,
        ),
        title: Text(l10n.txAccountLabel),
        subtitle: Text(
          l10n.txAccountEmpty,
          style: TextStyle(
            color: hasError ? theme.colorScheme.error : null,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        tileColor: tileColor,
      );
    }
    return ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined),
      title: Text(l10n.txAccountLabel),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(a.name)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              a.currency.code,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      tileColor: tileColor,
    );
  }
}
