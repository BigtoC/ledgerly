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
import 'package:ledgerly/features/accounts/accounts_screen.dart';
import 'package:ledgerly/features/home/home_screen.dart';
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

    testWidgets('/accounts/new uses a root modal route and renders the form', (
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
      router.go('/accounts/new');

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      final leaf = router.routerDelegate.currentConfiguration.last;
      expect(leaf.matchedLocation, '/accounts/new');
      expect(leaf.route.parentNavigatorKey, isNotNull);
      expect(find.byType(AccountFormScreen), findsOneWidget);
      expect(find.byType(AccountsScreen), findsNothing);
    });

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

    testWidgets('/accounts/:id rejects invalid ids safely', (tester) async {
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
      router.go('/accounts/not-a-number');

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      final leaf = router.routerDelegate.currentConfiguration.last;
      expect(leaf.matchedLocation, '/accounts');
      expect(find.byType(AccountsScreen), findsOneWidget);
      expect(find.byType(AccountFormScreen), findsNothing);
      expect(tester.takeException(), isNull);
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
