// Color picker — grid over `kCategoryColorPalette` indices (plan §3.1,
// §6). Selection only; no palette mutation (plan §12 risk #4).
//
// The palette is append-only; stored as int index so we resolve the
// preview swatch via `colorForIndex` at render time.

import 'package:flutter/material.dart';

import '../../../core/utils/color_palette.dart';

Future<int?> showCategoryColorPicker(
  BuildContext context, {
  int? selectedIndex,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.5,
      child: _CategoryColorPickerSheet(selectedIndex: selectedIndex),
    ),
  );
}

class _CategoryColorPickerSheet extends StatelessWidget {
  const _CategoryColorPickerSheet({this.selectedIndex});

  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 64,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: kCategoryColorPalette.length,
        itemBuilder: (context, i) {
          final color = colorForIndex(i);
          final isSelected = i == selectedIndex;
          return InkWell(
            onTap: () => Navigator.of(context).pop(i),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 3,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
