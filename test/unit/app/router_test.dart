// M4 §7.7 — Router redirect state machine tests.
//
// Uses `testWidgets` with an explicit `ProviderContainer` override so the
// `routerProvider` reads a pre-seeded `SplashGateSnapshot` whose state is
// controlled by each test case. No live DB interaction required.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ledgerly/app/router.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/features/accounts/account_form_screen.dart';
import 'package:ledgerly/features/analysis/analysis_screen.dart';
import 'package:ledgerly/features/home/home_screen.dart';
import 'package:ledgerly/features/shopping_list/shopping_list_screen.dart';
import 'package:ledgerly/features/splash/splash_screen.dart';

import '../../support/test_app.dart';

void main() {
  group('router redirect', () {
    testWidgets('splashEnabled=true: / → /splash', (tester) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: true, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('splashEnabled=false: / → /home (G10)', (tester) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('splashEnabled=false: /splash → /home', (tester) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      addTearDown(router.dispose);
      router.go('/splash');

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('/home/add uses a root modal route', (tester) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      addTearDown(router.dispose);
      router.go('/home/add');

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      final leaf = router.routerDelegate.currentConfiguration.last;
      expect(leaf.matchedLocation, '/home/add');
      expect(leaf.route, isA<GoRoute>());
      expect(leaf.route.parentNavigatorKey, isNotNull);
    });

    testWidgets('/home/add renders inside a dialog on >=600dp', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final db = newTestAppDatabase();
      addTearDown(db.close);
      await tester.runAsync(() => runTestSeed(db));
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      addTearDown(router.dispose);
      router.go('/home/add');

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('/home/add stays full-screen below 600dp', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final db = newTestAppDatabase();
      addTearDown(db.close);
      await tester.runAsync(() => runTestSeed(db));
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      addTearDown(router.dispose);
      router.go('/home/add');

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets(
      '/settings/manage-accounts/new uses a root modal route and renders the form',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() => runTestSeed(db));
        final container = makeTestContainer(
          db: db,
          extraOverrides: [
            splashGateSnapshotProvider.overrideWithValue(
              SplashGateSnapshot.withInitial(enabled: false, startDate: null),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(routerProvider);
        addTearDown(router.dispose);
        router.go('/settings/manage-accounts/new');

        await tester.pumpWidget(buildTestApp(container: container));
        await tester.pumpAndSettle();

        final leaf = router.routerDelegate.currentConfiguration.last;
        expect(leaf.matchedLocation, '/settings/manage-accounts/new');
        expect(leaf.route.parentNavigatorKey, isNotNull);
        expect(find.byType(AccountFormScreen), findsOneWidget);
        expect(find.byType(AnalysisScreen), findsNothing);
      },
    );

    testWidgets('/home/edit/:id rejects invalid ids safely', (tester) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      addTearDown(router.dispose);
      router.go('/home/edit/not-a-number');

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '/settings/manage-accounts/not-a-number rejects invalid ids safely',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() => runTestSeed(db));
        final container = makeTestContainer(
          db: db,
          extraOverrides: [
            splashGateSnapshotProvider.overrideWithValue(
              SplashGateSnapshot.withInitial(enabled: false, startDate: null),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(routerProvider);
        addTearDown(router.dispose);
        router.go('/settings/manage-accounts/not-a-number');

        await tester.pumpWidget(buildTestApp(container: container));
        await tester.pumpAndSettle();

        final leaf = router.routerDelegate.currentConfiguration.last;
        expect(leaf.matchedLocation, '/settings');
        expect(find.byType(AnalysisScreen), findsNothing);
        expect(find.byType(AccountFormScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    // RT01 — /home/shopping-list renders ShoppingListScreen
    testWidgets('RT01: /home/shopping-list renders ShoppingListScreen', (
      tester,
    ) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await tester.runAsync(() => runTestSeed(db));
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      addTearDown(router.dispose);
      router.go('/home/shopping-list');

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      final leaf = router.routerDelegate.currentConfiguration.last;
      expect(leaf.matchedLocation, '/home/shopping-list');
      expect(find.byType(ShoppingListScreen), findsOneWidget);
      expect(find.byType(AccountFormScreen), findsNothing);
    });

    // RT02 — /home/shopping-list/:id routes to the form (root navigator)
    // We pump the widget first (so the router initialises), then navigate to
    // the route, then pump once to apply the navigation — but before
    // pumpAndSettle so the async draft-not-found pop hasn't fired yet.
    testWidgets('RT02: /home/shopping-list/123 uses root navigator', (
      tester,
    ) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      addTearDown(router.dispose);

      // Build the widget first so the router is initialised.
      await tester.pumpWidget(buildTestApp(container: container));
      // Navigate after the router is live.
      router.go('/home/shopping-list/123');
      // One pump to apply the navigation frame.
      await tester.pump();

      final leaf = router.routerDelegate.currentConfiguration.last;
      expect(leaf.matchedLocation, '/home/shopping-list/123');
      expect(leaf.route.parentNavigatorKey, isNotNull);
    });

    // RT03 — /home/shopping-list/abc (non-parsable) redirects
    testWidgets(
      'RT03: /home/shopping-list/abc redirects to /home/shopping-list',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await tester.runAsync(() => runTestSeed(db));
        final container = makeTestContainer(
          db: db,
          extraOverrides: [
            splashGateSnapshotProvider.overrideWithValue(
              SplashGateSnapshot.withInitial(enabled: false, startDate: null),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(routerProvider);
        addTearDown(router.dispose);
        router.go('/home/shopping-list/abc');

        await tester.pumpWidget(buildTestApp(container: container));
        await tester.pumpAndSettle();

        final leaf = router.routerDelegate.currentConfiguration.last;
        expect(leaf.matchedLocation, '/home/shopping-list');
        expect(find.byType(ShoppingListScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    // RT04 — collapsed into RT02 (same route, different literal id; all
    // three assertions are already covered by RT02).

    testWidgets('/analysis renders AnalysisScreen', (tester) async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await tester.runAsync(() => runTestSeed(db));
      final container = makeTestContainer(
        db: db,
        extraOverrides: [
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: false, startDate: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      addTearDown(router.dispose);
      router.go('/analysis');

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.byType(AnalysisScreen), findsOneWidget);
    });

    testWidgets(
      'splashEnabled=true with startDate set: /splash shows Enter CTA',
      (tester) async {
        final db = newTestAppDatabase();
        addTearDown(db.close);

        final container = makeTestContainer(
          db: db,
          extraOverrides: [
            splashGateSnapshotProvider.overrideWithValue(
              SplashGateSnapshot.withInitial(
                enabled: true,
                startDate: DateTime(2025, 1, 1),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(buildTestApp(container: container));
        await tester.pumpAndSettle();

        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.text('Enter'), findsOneWidget);
        expect(find.text('Set start date'), findsNothing);
      },
    );
  });
}
