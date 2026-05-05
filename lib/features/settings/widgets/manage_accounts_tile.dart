// Manage accounts tile — Settings list row.
//
// Replacement for DefaultAccountTile. Shows "Manage accounts" with a
// count-aware subtitle using accountsControllerProvider for account rows
// and settingsControllerProvider only for defaultAccountId.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../settings_controller.dart';
import '../../accounts/accounts_controller.dart';
import '../../accounts/accounts_state.dart';
import '../settings_state.dart';
import 'manage_accounts_sheet.dart';

class ManageAccountsTile extends ConsumerWidget {
  const ManageAccountsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountsControllerProvider);
    final defaultAccountId = ref
        .watch(settingsControllerProvider)
        .maybeWhen(
          data: (SettingsState state) => switch (state) {
            SettingsData(:final defaultAccountId) => defaultAccountId,
            _ => null,
          },
          orElse: () => null,
        );

    final subtitle = accountsAsync.maybeWhen(
      data: (state) {
        final data = state;
        if (data is! AccountsData) return '';
        if (data.active.isEmpty) return l10n.manageAccountsTileSubtitleAddCta;
        if (data.active.length == 1) return data.active.first.account.name;
        final defaultMatches = data.active.where(
          (r) => r.account.id == defaultAccountId,
        );
        final defaultName = defaultMatches.isNotEmpty
            ? defaultMatches.first.account.name
            : data.active.first.account.name;
        return '$defaultName${l10n.manageAccountsTileSubtitleMore(data.active.length - 1)}';
      },
      orElse: () => '',
    );

    return ListTile(
      key: const ValueKey('settingsManageAccountsTile'),
      title: Text(l10n.manageAccountsTitle),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showManageAccountsSheet(context),
    );
  }
}
