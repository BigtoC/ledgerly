// `CategoryChip` — Wave 2 §4.1.
//
// Half-width tile (no chevron; issue #100) that renders the selected
// category (icon, name and type) or an empty-state CTA when no category
// is selected. The form has no type toggle, so the type shown here is the
// only hint that a category is expense or income (two seeded categories
// share the name "Investment"). Tap is delegated to the screen so the
// screen can branch on the picker-vs-management routing rule (Wave 2
// §7.1) before calling `showCategoryPicker`.

import 'package:flutter/material.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/icon_registry.dart';
import '../../../../domain/models/category.dart';
import '../../../../l10n/app_localizations.dart';
import '../../categories/views/category_display.dart';

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
    final Widget leading;
    final Widget subtitle;
    if (cat == null) {
      final errorColor = hasError ? theme.colorScheme.error : null;
      leading = Icon(Icons.category_outlined, color: errorColor);
      subtitle = Text(
        l10n.txCategoryEmpty,
        style: TextStyle(color: errorColor),
      );
    } else {
      final color = colorForIndex(cat.color);
      final typeLabel = cat.type == CategoryType.expense
          ? l10n.transactionTypeExpense
          : l10n.transactionTypeIncome;
      leading = CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(iconForKey(cat.icon), color: color),
      );
      subtitle = Text('${categoryDisplayName(cat, l10n)} · $typeLabel');
    }
    return ListTile(
      leading: leading,
      title: Text(l10n.txCategoryLabel),
      subtitle: subtitle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      horizontalTitleGap: 12,
      visualDensity: VisualDensity.compact,
      onTap: onTap,
      tileColor: hasError ? theme.colorScheme.errorContainer : null,
    );
  }
}
