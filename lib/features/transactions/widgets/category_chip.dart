// `CategoryChip` — Wave 2 §4.1.
//
// Single-row tile that renders the selected category (icon + name) or
// an empty-state CTA when no category is selected. Tap is delegated to
// the screen so the screen can branch on the picker-vs-management
// routing rule (Wave 2 §7.1) before calling `showCategoryPicker`.

import 'package:flutter/material.dart';

import '../../../core/utils/color_palette.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../data/models/category.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/widgets/category_display.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.onTap,
    this.hasError = false,
  });

  /// Selected category, or null when the form has not picked one yet.
  final Category? category;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cat = category;
    final tileColor = hasError ? theme.colorScheme.errorContainer : null;

    if (cat == null) {
      return ListTile(
        leading: Icon(
          Icons.category_outlined,
          color: hasError ? theme.colorScheme.error : null,
        ),
        title: Text(l10n.txCategoryLabel),
        subtitle: Text(
          l10n.txCategoryEmpty,
          style: TextStyle(color: hasError ? theme.colorScheme.error : null),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        tileColor: tileColor,
      );
    }
    final color = colorForIndex(cat.color);
    final icon = iconForKey(cat.icon);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(l10n.txCategoryLabel),
      subtitle: Text(categoryDisplayName(cat, l10n)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      tileColor: tileColor,
    );
  }
}
