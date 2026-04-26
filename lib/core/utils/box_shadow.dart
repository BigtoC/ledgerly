import 'package:flutter/material.dart';

import 'color_palette.dart';

BoxShadow buildBoxShadow(double blurRadius) {
  final int colorIndex = DateTime.now().day % kCategoryColorPalette.length;
  final Color color = kCategoryColorPalette[colorIndex];
  return BoxShadow(
    color: color.withAlpha(31),
    blurRadius: blurRadius,
    offset: const Offset(0, 8),
  );
}
