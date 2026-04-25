// Splash widget tests (plan §3.4).
//
// Exercises the widget shell directly (no full-app router) using provider
// overrides for the controller state. Route-level redirect coverage stays
// in `test/unit/app/router_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/splash/splash_controller.dart';
import 'package:ledgerly/features/splash/splash_screen.dart';
import 'package:ledgerly/features/splash/splash_state.dart';
import 'package:ledgerly/features/splash/widgets/splash_day_count.dart';
import 'package:ledgerly/features/splash/widgets/splash_enter_button.dart';
import 'package:ledgerly/features/splash/widgets/splash_rainbow_gradient_text.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
    registerFallbackValue(DateTime(2000));
  });

  Widget wrap(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashScreen(),
      ),
    );
  }

  Widget routerWrap(ProviderContainer container) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', redirect: (context, state) => '/splash'),
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('HOME')),
        ),
      ],
    );
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets(
    'W01: startDate null → renders launch-time Set start date prompt',
    (tester) async {
      final repo = _MockUserPreferencesRepository();
      when(() => repo.setSplashStartDate(any())).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          userPreferencesRepositoryProvider.overrideWithValue(repo),
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: true, startDate: null),
          ),
          splashStartDateProvider.overrideWith((ref) => Stream.value(null)),
          splashControllerProvider.overrideWith(
            () => _FakeSplashController(const SplashState.loading()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(wrap(container));
      await tester.pumpAndSettle();

      expect(find.text('Set start date'), findsOneWidget);
      expect(find.byType(SplashEnterButton), findsNothing);
      expect(find.byType(SplashDayCount), findsNothing);
    },
  );

  testWidgets(
    'W02: data state → renders day count, gradient date, Enter button',
    (tester) async {
      final repo = _MockUserPreferencesRepository();
      final startDate = DateTime(2026, 1, 1);

      final container = ProviderContainer(
        overrides: [
          userPreferencesRepositoryProvider.overrideWithValue(repo),
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: true, startDate: startDate),
          ),
          splashStartDateProvider.overrideWith(
            (ref) => Stream.value(startDate),
          ),
          splashControllerProvider.overrideWith(
            () => _FakeSplashController(
              SplashState.data(
                startDate: startDate,
                dayCount: 100,
                formattedStartDate: 'Jan 1, 2026',
                formattedDisplayText: 'Since Jan 1, 2026',
                buttonLabel: 'Enter',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(wrap(container));
      await tester.pumpAndSettle();

      expect(find.byType(SplashDayCount), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.byType(SplashRainbowGradientText), findsOneWidget);
      expect(find.byType(SplashEnterButton), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);
      expect(find.text('Since Jan 1, 2026'), findsOneWidget);
    },
  );

  testWidgets('W03: tapping launch-time prompt writes start date', (
    tester,
  ) async {
    final repo = _MockUserPreferencesRepository();
    when(() => repo.setSplashStartDate(any())).thenAnswer((_) async {});
    final fixedNow = DateTime(2026, 1, 10);

    final container = ProviderContainer(
      overrides: [
        userPreferencesRepositoryProvider.overrideWithValue(repo),
        splashGateSnapshotProvider.overrideWithValue(
          SplashGateSnapshot.withInitial(enabled: true, startDate: null),
        ),
        splashStartDateProvider.overrideWith((ref) => Stream.value(null)),
        splashClockProvider.overrideWithValue(() => fixedNow),
        splashControllerProvider.overrideWith(
          () => _FakeSplashController(const SplashState.loading()),
        ),
      ],
    );
    addTearDown(container.dispose);

      await tester.pumpWidget(wrap(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set start date'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      verifyNever(() => repo.setSplashStartDate(any()));

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      verify(() => repo.setSplashStartDate(fixedNow)).called(1);
    });

  testWidgets('W03b: Enter button navigates to /home', (tester) async {
    final repo = _MockUserPreferencesRepository();
    final startDate = DateTime(2026, 1, 1);

    final container = ProviderContainer(
      overrides: [
        userPreferencesRepositoryProvider.overrideWithValue(repo),
        splashGateSnapshotProvider.overrideWithValue(
          SplashGateSnapshot.withInitial(enabled: true, startDate: startDate),
        ),
        splashStartDateProvider.overrideWith((ref) => Stream.value(startDate)),
        splashControllerProvider.overrideWith(
          () => _FakeSplashController(
            SplashState.data(
              startDate: startDate,
              dayCount: 100,
              formattedStartDate: 'Jan 1, 2026',
              formattedDisplayText: 'Since Jan 1, 2026',
              buttonLabel: 'Enter',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(routerWrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SplashEnterButton));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('W04: day count clamps at 1.5x even at 2x requested scale', (
    tester,
  ) async {
    final repo = _MockUserPreferencesRepository();
    final startDate = DateTime(2026, 1, 1);

    final container = ProviderContainer(
      overrides: [
        userPreferencesRepositoryProvider.overrideWithValue(repo),
        splashGateSnapshotProvider.overrideWithValue(
          SplashGateSnapshot.withInitial(enabled: true, startDate: startDate),
        ),
        splashStartDateProvider.overrideWith((ref) => Stream.value(startDate)),
        splashControllerProvider.overrideWith(
          () => _FakeSplashController(
            SplashState.data(
              startDate: startDate,
              dayCount: 100,
              formattedStartDate: 'Jan 1, 2026',
              formattedDisplayText: 'Since Jan 1, 2026',
              buttonLabel: 'Enter',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find the day-count Text widget — its textScaler should be clamped.
    final dayCountText = tester.widget<Text>(
      find.descendant(
        of: find.byType(SplashDayCount),
        matching: find.text('100'),
      ),
    );
    final effectiveScaler = dayCountText.textScaler!;
    // At requested 2.0, clamp(maxScaleFactor: 1.5) should produce 1.5.
    expect(effectiveScaler.scale(10), lessThanOrEqualTo(15.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('W05: error state renders an error surface', (tester) async {
    final repo = _MockUserPreferencesRepository();
    final stack = StackTrace.current;
    final startDate = DateTime(2026, 1, 1);

    final container = ProviderContainer(
      overrides: [
        userPreferencesRepositoryProvider.overrideWithValue(repo),
        splashGateSnapshotProvider.overrideWithValue(
          SplashGateSnapshot.withInitial(enabled: true, startDate: startDate),
        ),
        splashStartDateProvider.overrideWith((ref) => Stream.value(startDate)),
        splashControllerProvider.overrideWith(
          () => _FakeSplashController(
            SplashState.error(Exception('boom'), stack),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Test double that skips the stream-combine path and yields a fixed state.
class _FakeSplashController extends SplashController {
  _FakeSplashController(this._fixed);
  final SplashState _fixed;

  @override
  Stream<SplashState> build() async* {
    yield _fixed;
  }
}
