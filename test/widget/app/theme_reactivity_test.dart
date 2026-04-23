// M4 §7.10 — Theme reactivity test (T7.5).
//
// Uses a controllable provider override so the test proves the app-shell
// theme wiring in CI without depending on Drift timers inside FakeAsync.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/locale_provider.dart';
import 'package:ledgerly/app/providers/theme_provider.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';

import '../../support/test_app.dart';

void main() {
  group('theme reactivity', () {
    testWidgets('initial persisted dark theme is applied on the first frame', (
      tester,
    ) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);

      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.dark),
          themeModeStreamProvider.overrideWith((ref) => const Stream.empty()),
          userLocalePreferenceProvider.overrideWith(
            (ref) => const Locale('en'),
          ),
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pump();

      final brightness = Theme.of(
        tester.element(find.byType(Scaffold).first),
      ).brightness;
      expect(brightness, Brightness.dark);
    });

    testWidgets(
      'theme stream update rebuilds MaterialApp with dark brightness',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        final controller = StreamController<ThemeMode>.broadcast();
        addTearDown(controller.close);

        final container = makeTestContainer(
          db: db,
          extraOverrides: [
            themeModeStreamProvider.overrideWith((ref) => controller.stream),
            userLocalePreferenceProvider.overrideWith(
              (ref) => const Locale('en'),
            ),
            splashGateSnapshotProvider.overrideWithValue(
              SplashGateSnapshot.withInitial(enabled: false, startDate: null),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(buildTestApp(container: container));
        await tester.pump();

        final initialBrightness = Theme.of(
          tester.element(find.byType(Scaffold).first),
        ).brightness;
        expect(initialBrightness, Brightness.light);
        expect(container.read(themeModeProvider), ThemeMode.system);

        controller.add(ThemeMode.dark);
        await container.pump();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(container.read(themeModeProvider), ThemeMode.dark);

        final updatedBrightness = Theme.of(
          tester.element(find.byType(Scaffold).first),
        ).brightness;
        expect(updatedBrightness, Brightness.dark);
      },
    );

    testWidgets('initial preferred locale is applied on the first frame', (
      tester,
    ) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);

      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          initialPreferredLocaleProvider.overrideWithValue(
            const Locale('zh', 'HK'),
          ),
          userLocalePreferenceStreamProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pump();

      final homeContext = tester.element(find.byType(Scaffold).first);
      expect(Localizations.localeOf(homeContext), const Locale('zh', 'TW'));
    });
  });
}
