// Icon picker — scrollable grid over `iconRegistry.entries` (plan §3.1,
// §6). Selection only; creation of new icon keys is out of scope (plan
// §12 risk #4).
//
// Opens as an in-screen modal sheet via `showCategoryIconPicker`.

import 'package:flutter/material.dart';

import '../../../core/utils/icon_registry.dart';

Future<String?> showCategoryIconPicker(
  BuildContext context, {
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.7,
      child: _CategoryIconPickerSheet(selected: selected),
    ),
  );
}

class _CategoryIconPickerSheet extends StatelessWidget {
  const _CategoryIconPickerSheet({this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final keys = kIconRegistry.keys.toList(growable: false);
    return SafeArea(
      top: false,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 64,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: keys.length,
        itemBuilder: (context, i) {
          final key = keys[i];
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
              child: Icon(iconForKey(key)),
            ),
          );
        },
      ),
    );
  }
}
