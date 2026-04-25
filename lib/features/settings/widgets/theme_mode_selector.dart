// Theme-mode selector (plan §3.1, §5).
//
// A segmented control over `ThemeMode.{light, dark, system}`. Writes via
// `SettingsController.setThemeMode`; the M4 `themeModeProvider` re-emits
// through the repository stream and `MaterialApp.themeMode` rebuilds —
// no direct `MaterialApp.theme` tweak from this slice (plan §13 risk #1).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../settings_controller.dart';

class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key, required this.value});

  final ThemeMode value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              l10n.settingsThemeLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.dark_mode),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.settingsThemeSystem),
                icon: const Icon(Icons.brightness_auto),
              ),
            ],
            selected: {value},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              ref
                  .read(settingsControllerProvider.notifier)
                  .setThemeMode(selection.first);
            },
          ),
        ],
      ),
    );
  }
}
