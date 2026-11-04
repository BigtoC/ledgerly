// `AccountSelectorTile` — Wave 2 §4.1.
//
// Half-width tile (no chevron; issue #100) that shows the selected
// account's name + currency code. Tap opens the account picker sheet
// (caller decides whether the result triggers the currency-change
// confirm dialog).

import 'package:flutter/material.dart';

import '../../../../domain/models/account.dart';
import '../../../../l10n/app_localizations.dart';

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
    final a = account;
    // The error colour marks only the empty state; a selected account
    // signals the error through `tileColor` alone.
    final emptyErrorColor = a == null && hasError
        ? theme.colorScheme.error
        : null;
    return ListTile(
      leading: Icon(
        Icons.account_balance_wallet_outlined,
        color: emptyErrorColor,
      ),
      title: Text(l10n.txAccountLabel),
      subtitle: a == null
          ? Text(l10n.txAccountEmpty, style: TextStyle(color: emptyErrorColor))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(a.name)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      horizontalTitleGap: 12,
      visualDensity: VisualDensity.compact,
      onTap: onTap,
      tileColor: hasError ? theme.colorScheme.errorContainer : null,
    );
  }
}
