// `AccountSelectorTile` — Wave 2 §4.1.
//
// Half-width tile (no chevron; issue #100) that shows the selected
// account's name + currency code. Tap opens the account picker sheet
// (caller decides whether the result triggers the currency-change
// confirm dialog). When it switches to another account, for example
// because a memo suggestion was picked (issue #152), the tile plays the
// theme's tap ripple from its centre so the user notices.

import 'package:material_ui/material_ui.dart';

import '../../../../domain/models/account.dart';
import '../../../../l10n/app_localizations.dart';

class const AccountSelectorTile({
  super.key,
  required final Account? account,
  required final VoidCallback onTap,
  final bool hasError = false,
}) extends StatefulWidget {
  @override
  State<AccountSelectorTile> createState() => _AccountSelectorTileState();
}

class _AccountSelectorTileState extends State<AccountSelectorTile> {
  InteractiveInkFeature? _splash;

  @override
  void didUpdateWidget(AccountSelectorTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only a switch from one account to another; an account appearing
    // where none was shown (still loading) is not a change.
    final old = oldWidget.account;
    if (old != null && widget.account?.id != old.id) {
      // After layout, so the ripple is centred on the new size.
      WidgetsBinding.instance.addPostFrameCallback((_) => _ripple());
    }
  }

  void _ripple() {
    if (!mounted) return;
    final box = context.findRenderObject()! as RenderBox;
    final theme = Theme.of(context);
    _splash?.dispose();
    _splash = theme.splashFactory.create(
      controller: Material.of(context),
      referenceBox: box,
      position: box.size.center(Offset.zero),
      color: theme.colorScheme.primary.withValues(alpha: 0.24),
      containedInkWell: true,
      textDirection: Directionality.of(context),
      onRemoved: () => _splash = null,
    )..confirm();
  }

  @override
  void dispose() {
    _splash?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final a = widget.account;
    final hasError = widget.hasError;
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
      onTap: widget.onTap,
      tileColor: hasError ? theme.colorScheme.errorContainer : null,
    );
  }
}
