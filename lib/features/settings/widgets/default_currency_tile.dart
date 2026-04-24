// Default-currency tile (plan §3.1, §5, §8).
//
// Renders "Default currency" with the current ISO code as the subtitle;
// tap opens the picker sheet. Writes via `SettingsController` when the
// user picks a row.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../settings_controller.dart';
import 'default_currency_picker_sheet.dart';

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
        await ref
            .read(settingsControllerProvider.notifier)
            .setDefaultCurrency(picked);
      },
    );
  }
}
