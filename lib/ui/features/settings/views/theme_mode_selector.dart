// Theme-mode selector (plan §3.1, §5).
//
// A segmented control over `ThemeMode.{light, dark}`. Writes via
// `SettingsController.setThemeMode`; the M4 `themeModeProvider` re-emits
// through the repository stream and `MaterialApp.themeMode` rebuilds —
// no direct `MaterialApp.theme` tweak from this slice (plan §13 risk #1).

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../l10n/app_localizations.dart';
import '../view_models/settings_controller.dart';
import '../view_models/settings_state.dart';

@Dependencies([SettingsController])
class const ThemeModeSelector({super.key, required final ThemeMode value})
    extends ConsumerWidget {
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
            ],
            selected: {value},
            onSelectionChanged: (selection) async {
              final messenger = ScaffoldMessenger.of(context);
              final outcome = await ref
                  .read(settingsControllerProvider.notifier)
                  .setThemeMode(selection.first);
              switch (outcome) {
                case SettingsWriteOk():
                  break;
                case SettingsWriteFailed():
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.errorSnackbarGeneric)),
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}
