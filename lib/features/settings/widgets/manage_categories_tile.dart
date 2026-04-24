// Manage-Categories entry tile (plan §3.1, §5, Wave 0 §2.3).
//
// Pure navigation tile. Categories owns the management screen; this tile
// only renders the entry point per the cross-slice ownership contract.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

class ManageCategoriesTile extends StatelessWidget {
  const ManageCategoriesTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      key: const ValueKey('settingsManageCategoriesTile'),
      title: Text(l10n.settingsManageCategories),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/settings/categories'),
    );
  }
}
