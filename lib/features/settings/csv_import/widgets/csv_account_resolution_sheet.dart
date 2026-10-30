// CSV import account decision sheet.
//
// Adaptive like `manage_accounts_sheet.dart`: bottom sheet (<600dp) or
// dialog (>=600dp). Lists the three choices of the spec's decision sheet
// and pops with the one the user taps; dismissing it returns null. Pure:
// everything it shows comes from the matcher's `CsvAccountMatch`.

import 'package:flutter/material.dart';

import '../../../../data/models/account.dart';
import '../../../../data/models/csv_import.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/widgets/account_type_display.dart';
import '../csv_import_matcher.dart';

/// Shows the decision sheet for [match] and returns the chosen
/// resolution, or null when dismissed.
Future<AccountResolution?> showCsvAccountResolutionSheet(
  BuildContext context,
  CsvAccountMatch match,
) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 600) {
    return showDialog<AccountResolution>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: CsvAccountResolutionSheet(match: match),
        ),
      ),
    );
  }
  return showModalBottomSheet<AccountResolution>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.75,
      child: CsvAccountResolutionSheet(match: match),
    ),
  );
}

class CsvAccountResolutionSheet extends StatelessWidget {
  const CsvAccountResolutionSheet({super.key, required this.match});

  final CsvAccountMatch match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final createAccount = match.createAccountOption;
    final createBoth = match.createTypeAndAccountOption;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    match.csvValue,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: CustomScrollView(
              slivers: [
                if (createAccount != null)
                  SliverToBoxAdapter(
                    child: _OptionTile(
                      key: const ValueKey('csvImportSheetCreateAccount'),
                      label: l10n.csvImportAccountCreate(
                        match.csvValue,
                        accountTypeDisplayName(match.matchedType!, l10n),
                      ),
                      icon: Icons.add_card_outlined,
                      option: createAccount,
                      current: match.resolution,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _OptionTile(
                    key: const ValueKey('csvImportSheetCreateTypeAndAccount'),
                    label: l10n.csvImportAccountCreateWithType(match.csvValue),
                    icon: Icons.create_new_folder_outlined,
                    option: createBoth,
                    current: match.resolution,
                  ),
                ),
                if (match.options.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        l10n.csvImportAccountUseExisting,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                SliverList.builder(
                  itemCount: match.options.length,
                  itemBuilder: (context, i) {
                    final account = match.options[i];
                    return _OptionTile(
                      key: ValueKey('csvImportSheetAccount:${account.id}'),
                      label: _accountLabel(account, l10n),
                      icon: Icons.account_balance_wallet_outlined,
                      option: AccountResolution.existing(account.id),
                      current: match.resolution,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _accountLabel(Account account, AppLocalizations l10n) =>
    account.isArchived
    ? l10n.csvImportAccountArchived(account.name)
    : account.name;

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.option,
    required this.current,
  });

  final String label;
  final IconData icon;
  final AccountResolution option;
  final AccountResolution? current;

  @override
  Widget build(BuildContext context) {
    final selected = option == current;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () => Navigator.of(context).pop(option),
    );
  }
}
