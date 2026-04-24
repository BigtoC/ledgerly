// Categories management screen row tile (plan §4).
//
// Renders: icon + color badge, display name, and a `flutter_slidable`
// trailing action that is either Archive or Delete per the
// controller-computed affordance. The widget never re-queries the
// repository — the affordance is passed in.
//
// Long-press on the reorder handle is exposed by the parent
// `SliverReorderableList` via `ReorderableDragStartListener`.

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/utils/color_palette.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../l10n/app_localizations.dart';
import '../categories_state.dart';
import 'category_display.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.view,
    required this.index,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  });

  final CategoryRowView view;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cat = view.category;
    final label = categoryDisplayName(cat, l10n);
    final color = colorForIndex(cat.color);

    return Slidable(
      key: ValueKey<int>(cat.id),
      groupTag: 'categories',
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.3,
        children: [
          if (view.affordance == CategoryRowAffordance.archive)
            SlidableAction(
              onPressed: (_) => onArchive(),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              icon: Icons.archive_outlined,
              label: l10n.commonArchive,
            )
          else
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              icon: Icons.delete_outline,
              label: l10n.commonDelete,
            ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(iconForKey(cat.icon), color: color, size: 20),
        ),
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A11y-accessible archive/delete button mirrors the slide
            // action so tests and keyboard users can reach it too.
            if (view.affordance == CategoryRowAffordance.archive)
              IconButton(
                key: ValueKey('categoryTile:${cat.id}:archive'),
                icon: const Icon(Icons.archive_outlined),
                tooltip: l10n.commonArchive,
                onPressed: onArchive,
              )
            else
              IconButton(
                key: ValueKey('categoryTile:${cat.id}:delete'),
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.commonDelete,
                onPressed: onDelete,
              ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_indicator),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
