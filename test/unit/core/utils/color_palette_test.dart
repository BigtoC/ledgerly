import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/color_palette.dart';

void main() {
  group('higherContrastInk', () {
    const dark = Color(0xFF1B1B1B);
    const light = Color(0xFFFFFFFF);

    test('picks the dark ink on Red 60, where white is only 3.17:1', () {
      expect(
        higherContrastInk(const Color(0xFFF55E57), dark: dark, light: light),
        dark,
      );
    });

    test('keeps the light ink on Neutral Variant 50 (4.55:1 vs 3.78:1)', () {
      expect(
        higherContrastInk(const Color(0xFF79747E), dark: dark, light: light),
        light,
      );
    });

    test('defaults to black and white', () {
      expect(
        higherContrastInk(const Color(0xFFFFFFFF)),
        const Color(0xFF000000),
      );
      expect(
        higherContrastInk(const Color(0xFF000000)),
        const Color(0xFFFFFFFF),
      );
    });
  });
}
