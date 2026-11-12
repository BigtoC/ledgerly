// Icon picker — one header + grid per `IconGroup`, in `kIconGroups` order
// (issue #103), each icon tinted with its group's seeded category colour.
// Selection only; creation of new icon keys is out of scope
// (plan §12 risk #4).
//
// Opens as an in-screen modal sheet via `showCategoryIconPicker`.

import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/icon_registry.dart';
import '../../../../l10n/app_localizations.dart';

Future<String?> showCategoryIconPicker(
  BuildContext context, {
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.9,
      child: _CategoryIconPickerSheet(selected: selected),
    ),
  );
}

class _CategoryIconPickerSheet extends StatelessWidget {
  const _CategoryIconPickerSheet({this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          for (final MapEntry(key: group, value: keys)
              in kIconGroups.entries) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  _groupLabel(l10n, group),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(indent: 16, endIndent: 16)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 64,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: keys.length,
                itemBuilder: (context, i) => _iconTile(
                  context,
                  keys[i],
                  colorForIndex(kIconGroupColors[group]!),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _iconTile(BuildContext context, String key, Color color) {
    final isSelected = key == selected;
    return InkWell(
      onTap: () => Navigator.of(context).pop(key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(iconForKey(key), color: color),
        ),
      ),
    );
  }
}

// Headers reuse the seeded categories' labels.
String _groupLabel(AppLocalizations l10n, IconGroup group) => switch (group) {
  IconGroup.food => l10n.categoryFood,
  IconGroup.drinks => l10n.categoryDrinks,
  IconGroup.transport => l10n.categoryTransportation,
  IconGroup.shopping => l10n.categoryShopping,
  IconGroup.entertainment => l10n.categoryEntertainment,
  IconGroup.home => l10n.categoryHousing,
  IconGroup.electronics => l10n.categoryThreeC,
  IconGroup.medical => l10n.categoryMedical,
  IconGroup.income => l10n.categoriesSectionIncome,
  IconGroup.other => l10n.categoryOther,
};
