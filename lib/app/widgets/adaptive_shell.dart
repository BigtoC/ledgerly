import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/app_update_provider.dart';

/// Adaptive navigation shell. Renders a [NavigationBar] below 600dp and a
/// [NavigationRail] at 600dp and above. The breakpoint is enforced here at
/// the shell level, not inside individual feature screens (guardrail G11).
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int currentIndex;
  final void Function(int) onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    NavigationRailDestination(
                      icon: const Icon(Icons.home),
                      label: Text(l10n.navHome),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.analytics_outlined),
                      label: Text(l10n.navAnalysis),
                    ),
                    NavigationRailDestination(
                      icon: const _SettingsNavIcon(),
                      label: Text(l10n.navSettings),
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
              NavigationDestination(
                icon: const Icon(Icons.home),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.analytics_outlined),
                label: l10n.navAnalysis,
              ),
              NavigationDestination(
                icon: const _SettingsNavIcon(),
                label: l10n.navSettings,
              ),
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
      availableAppUpdateProvider.select((url) => url != null),
    );
    // No label, so the badge renders as a small dot at the top end.
    return Badge(
      key: const ValueKey('settingsUpdateDot'),
      isLabelVisible: hasUpdate,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.settings),
    );
  }
}
