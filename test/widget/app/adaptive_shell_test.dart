// M4 §7.4 — `AdaptiveShell` adaptive breakpoint test (guardrail G11).
//
// Verifies the shell switches between `NavigationBar` (<600dp) and
// `NavigationRail` (≥600dp) at the shell level, not inside individual
// feature screens.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/widgets/adaptive_shell.dart';

import 'package:ledgerly/l10n/app_localizations.dart';

/// Wraps `AdaptiveShell` with the minimum context it requires:
/// `AppLocalizations` delegates (for destination labels) and a tight
/// `SizedBox` so `LayoutBuilder` receives a predictable `maxWidth`.
Widget _shellAt(
  double width, {
  int currentIndex = 0,
  void Function(int)? onSelected,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Center(
      child: SizedBox(
        width: width,
        height: 800,
        child: AdaptiveShell(
          currentIndex: currentIndex,
          onDestinationSelected: onSelected ?? (_) {},
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

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
}
