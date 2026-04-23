import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';

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
                      icon: const Icon(Symbols.home),
                      label: Text(l10n.navHome),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Symbols.account_balance_wallet),
                      label: Text(l10n.navAccounts),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Symbols.settings),
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
                icon: const Icon(Symbols.home),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Symbols.account_balance_wallet),
                label: l10n.navAccounts,
              ),
              NavigationDestination(
                icon: const Icon(Symbols.settings),
                label: l10n.navSettings,
              ),
            ],
          ),
        );
      },
    );
  }
}
