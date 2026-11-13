import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_update_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Adaptive navigation shell. Renders a [NavigationBar] below 600dp and a
/// [NavigationRail] at 600dp and above. This is the main 600dp switch; the
/// form-route wrapper in `router.dart`, the picker and sheet helpers and the
/// recurring rules screen switch at the same width. See
/// `docs/architecture/ui-and-layout.md` for the full list.
class const AdaptiveShell({
  super.key,
  required final int currentIndex,
  required final void Function(int) onDestinationSelected,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (icon: const Icon(Icons.home), label: l10n.navHome),
      (icon: const Icon(Icons.analytics_outlined), label: l10n.navAnalysis),
      (icon: const _SettingsNavIcon(), label: l10n.navSettings),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final i in items)
                      NavigationRailDestination(
                        icon: i.icon,
                        label: Text(i.label),
                      ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: [
              for (final i in items)
                NavigationDestination(icon: i.icon, label: i.label),
            ],
          ),
        );
      },
    );
  }
}

/// Settings destination icon with a small primary-color dot when a newer
/// release is available. Only this icon rebuilds when the update appears.
class _SettingsNavIcon extends ConsumerWidget {
  const _SettingsNavIcon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUpdate = ref.watch(
      availableAppUpdateProvider.select((update) => update != null),
    );
    // No label, so the badge renders as a small dot at the top end. The dot
    // is visual only, so screen readers get the badge text instead.
    return Semantics(
      label: hasUpdate
          ? AppLocalizations.of(context).settingsNewVersionBadge
          : null,
      child: Badge(
        key: const ValueKey('settingsUpdateDot'),
        isLabelVisible: hasUpdate,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.settings),
      ),
    );
  }
}
