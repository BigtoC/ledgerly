// Language selector (plan §3.1, §5).
//
// Renders a dropdown over the four options allowed by the app:
//   null -> follow system
//   en
//   zh_TW
//   zh_CN
//
// Writes via `SettingsController.setLocale`; the M4 `localePreferenceProvider`
// re-emits through the repository stream and `MaterialApp.locale` rebuilds.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../settings_controller.dart';

const _zhTw = Locale('zh', 'TW');
const _zhCn = Locale('zh', 'CN');
const _en = Locale('en');

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key, required this.value});

  /// `null` means "follow system".
  final Locale? value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      title: Text(l10n.settingsLanguageLabel),
      subtitle: Text(_labelFor(value, l10n)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openPicker(context, ref),
    );
  }

  String _labelFor(Locale? v, AppLocalizations l10n) {
    if (v == null) return l10n.settingsLanguageSystem;
    if (v.languageCode == 'en') return l10n.settingsLanguageEnglish;
    if (v.languageCode == 'zh') {
      return v.countryCode == 'CN'
          ? l10n.settingsLanguageZhCn
          : l10n.settingsLanguageZhTw;
    }
    return v.toLanguageTag();
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<_LanguageChoice>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('languageOption:system'),
              title: Text(l10n.settingsLanguageSystem),
              onTap: () =>
                  Navigator.of(ctx).pop(const _LanguageChoice.system()),
            ),
            ListTile(
              key: const ValueKey('languageOption:en'),
              title: Text(l10n.settingsLanguageEnglish),
              onTap: () =>
                  Navigator.of(ctx).pop(const _LanguageChoice(_en)),
            ),
            ListTile(
              key: const ValueKey('languageOption:zh_TW'),
              title: Text(l10n.settingsLanguageZhTw),
              onTap: () =>
                  Navigator.of(ctx).pop(const _LanguageChoice(_zhTw)),
            ),
            ListTile(
              key: const ValueKey('languageOption:zh_CN'),
              title: Text(l10n.settingsLanguageZhCn),
              onTap: () =>
                  Navigator.of(ctx).pop(const _LanguageChoice(_zhCn)),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await ref
        .read(settingsControllerProvider.notifier)
        .setLocale(selected.value);
  }
}

/// Value object used by the picker sheet — `null` is ambiguous with
/// "user dismissed", so we wrap the `Locale?` in an explicit marker.
class _LanguageChoice {
  const _LanguageChoice(this.value);
  const _LanguageChoice.system() : value = null;
  final Locale? value;
}
