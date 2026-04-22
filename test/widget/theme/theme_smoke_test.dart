// Smoke test for the M2 Stream C MD3 theme constants.
//
// Scope: confirms `lightTheme` / `darkTheme` plug into `MaterialApp` without
// throwing and expose the MD3 structural facts the rest of the app relies
// on (`useMaterial3: true`; colorScheme brightness matches; derived from
// the seeded `ColorScheme.fromSeed` pair). Does NOT pin specific color
// values — those are derived and may shift with future Flutter upgrades;
// the splash-screen golden is an M5 concern.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/theme/app_theme.dart';
import 'package:ledgerly/core/theme/color_schemes.dart';

void main() {
  group('M2 theme smoke', () {
    testWidgets('lightTheme + darkTheme wire into MaterialApp with MD3 on',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const Scaffold(),
        ),
      );

      final materialApp =
          tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);

      expect(materialApp.theme!.useMaterial3, isTrue);
      expect(materialApp.darkTheme!.useMaterial3, isTrue);

      expect(
        materialApp.theme!.colorScheme.brightness,
        Brightness.light,
      );
      expect(
        materialApp.darkTheme!.colorScheme.brightness,
        Brightness.dark,
      );

      // The themes must consume the exported seeded schemes — catches any
      // future drift where someone swaps a local `ColorScheme.fromSeed()`
      // in without updating `color_schemes.dart`.
      expect(materialApp.theme!.colorScheme, same(lightColorScheme));
      expect(materialApp.darkTheme!.colorScheme, same(darkColorScheme));

      expect(tester.takeException(), isNull);
    });
  });
}
