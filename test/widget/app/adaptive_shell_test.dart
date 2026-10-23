// M4 §7.4 — `AdaptiveShell` adaptive breakpoint test (guardrail G11).
//
// Verifies the shell switches between `NavigationBar` (<600dp) and
// `NavigationRail` (≥600dp) at the shell level, not inside individual
// feature screens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/app_update_provider.dart';
import 'package:ledgerly/app/widgets/adaptive_shell.dart';

import 'package:ledgerly/l10n/app_localizations.dart';

/// Wraps `AdaptiveShell` with the minimum context it requires:
/// `AppLocalizations` delegates (for destination labels), a tight
/// `SizedBox` so `LayoutBuilder` receives a predictable `maxWidth`, and a
/// provider container (disposed with the test) pinning the available update
/// to [update].
Widget _shellAt(double width, {void Function(int)? onSelected, Uri? update}) {
  final container = ProviderContainer.test(
    overrides: [
      availableAppUpdateProvider.overrideWithBuild((ref, notifier) => update),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Center(
        child: SizedBox(
          width: width,
          height: 800,
          child: AdaptiveShell(
            currentIndex: 0,
            onDestinationSelected: onSelected ?? (_) {},
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
}

final _apkUrl = Uri.parse('https://example.com/ledgerly-v0.7.2-arm64-v8a.apk');

Badge _settingsDot(WidgetTester tester) =>
    tester.widget<Badge>(find.byKey(const ValueKey('settingsUpdateDot')));

void main() {
  group('AdaptiveShell breakpoint', () {
    testWidgets('shows NavigationBar at 400dp (narrow)', (tester) async {
      await tester.pumpWidget(_shellAt(400));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('shows NavigationRail at 900dp (wide)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_shellAt(900));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets(
      'shows NavigationBar at exactly 599dp (just below breakpoint)',
      (tester) async {
        await tester.pumpWidget(_shellAt(599));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
      },
    );

    testWidgets('shows NavigationRail at exactly 600dp (at the breakpoint)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_shellAt(600));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets(
      'onDestinationSelected fires with the tapped destination index',
      (tester) async {
        int? received;
        await tester.pumpWidget(_shellAt(400, onSelected: (i) => received = i));
        await tester.pumpAndSettle();

        final navBar = find.byType(NavigationBar);
        expect(navBar, findsOneWidget);

        // Tap the third destination (index 2 — Settings).
        final destinations = find.descendant(
          of: navBar,
          matching: find.byType(NavigationDestination),
        );
        await tester.tap(destinations.at(2));
        await tester.pumpAndSettle();

        expect(received, 2);
      },
    );
  });

  group('AdaptiveShell settings update dot', () {
    for (final width in [400.0, 900.0]) {
      testWidgets('is hidden without an update at ${width}dp', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_shellAt(width));
        await tester.pumpAndSettle();

        expect(_settingsDot(tester).isLabelVisible, isFalse);
      });

      testWidgets('shows in the primary color with an update at ${width}dp', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_shellAt(width, update: _apkUrl));
        await tester.pumpAndSettle();

        final dot = _settingsDot(tester);
        expect(dot.isLabelVisible, isTrue);
        final scheme = Theme.of(
          tester.element(find.byKey(const ValueKey('settingsUpdateDot'))),
        ).colorScheme;
        expect(dot.backgroundColor, scheme.primary);
      });

      testWidgets('is announced to screen readers at ${width}dp', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(_shellAt(width));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(RegExp('new version')), findsNothing);

        await tester.pumpWidget(_shellAt(width, update: _apkUrl));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(RegExp('new version')), findsOneWidget);

        handle.dispose();
      });
    }
  });
}
