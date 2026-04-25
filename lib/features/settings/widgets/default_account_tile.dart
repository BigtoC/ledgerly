// Default-account tile (plan §3.1, §5, §7).
//
// Renders "Default account" with the current account's name as the
// subtitle, or the localized "Not set" placeholder when
// `defaultAccountId == null`. Tap opens the picker sheet. The name is
// resolved through a one-shot `FutureProvider.family` lookup — the
// widget does not subscribe to the full accounts stream for a single
// name.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../settings_controller.dart';
import '../settings_providers.dart';
import 'default_account_picker_sheet.dart';

class DefaultAccountTile extends ConsumerWidget {
  const DefaultAccountTile({super.key, required this.defaultAccountId});

  final int? defaultAccountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = defaultAccountId;
    final subtitle = id == null
        ? l10n.settingsDefaultAccountEmpty
        : ref
              .watch(settingsDefaultAccountProvider(id))
              .maybeWhen(
                data: (a) => a?.name ?? l10n.settingsDefaultAccountEmpty,
                orElse: () => '',
              );
    return ListTile(
      key: const ValueKey('settingsDefaultAccountTile'),
      title: Text(l10n.settingsDefaultAccountLabel),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showDefaultAccountPickerSheet(context);
        if (picked == null) return;
        await ref
            .read(settingsControllerProvider.notifier)
            .setDefaultAccountId(picked);
      },
    );
  }
}
