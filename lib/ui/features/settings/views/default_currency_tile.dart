// Default-currency tile (plan §3.1, §5, §8).
//
// Renders "Default currency" with the current ISO code as the subtitle;
// tap opens the picker sheet. Writes via `SettingsController` when the
// user picks a row.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../l10n/app_localizations.dart';
import '../view_models/settings_controller.dart';
import '../view_models/settings_state.dart';
import 'default_currency_picker_sheet.dart';

@Dependencies([SettingsController])
class DefaultCurrencyTile extends ConsumerWidget {
  const DefaultCurrencyTile({super.key, required this.defaultCurrency});

  final String defaultCurrency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      key: const ValueKey('settingsDefaultCurrencyTile'),
      title: Text(l10n.settingsDefaultCurrencyLabel),
      subtitle: Text(defaultCurrency),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showDefaultCurrencyPickerSheet(context);
        if (picked == null) return;
        if (!context.mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        final outcome = await ref
            .read(settingsControllerProvider.notifier)
            .setDefaultCurrency(picked);
        switch (outcome) {
          case SettingsWriteOk():
            break;
          case SettingsWriteFailed():
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.errorSnackbarGeneric)),
            );
        }
      },
    );
  }
}
