// Splash golden tests (plan §3.4, §10 exit criterion).
//
// Three mandatory variants per the plan §3.4 checklist:
//   1. Default text ("Since {date}"), start date = 100 days ago, English.
//   2. Custom display text ("{days} days strong"), zh_TW locale.
//   3. Long custom text at 2× text scale — layout must survive while the
//      fixed-height day count clamps at 1.5×.
//
// Goldens live at `goldens/`. Regenerate via
//   flutter test --update-goldens test/widget/features/splash/splash_screen_golden_test.dart
// and review the diff before committing. The plan §12 risk #1 flags
// cross-platform font rendering as the main flake source — capture
// goldens on the CI runner image when possible; local captures are
// acceptable for an initial commit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/splash/splash_controller.dart';
import 'package:ledgerly/features/splash/splash_screen.dart';
import 'package:ledgerly/features/splash/splash_state.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('zh_TW', null);
    registerFallbackValue(DateTime(2000));
  });

  Widget harness({
    required ProviderContainer container,
    Locale locale = const Locale('en'),
    TextScaler? textScaler,
    Size size = const Size(390, 844), // iPhone 14 portrait
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: textScaler ?? TextScaler.noScaling,
          ),
          child: child!,
        ),
        home: const SplashScreen(),
      ),
    );
  }

  ProviderContainer dataContainer(SplashData data) {
    final repo = _MockUserPreferencesRepository();
    return ProviderContainer(
      overrides: [
        userPreferencesRepositoryProvider.overrideWithValue(repo),
        splashGateSnapshotProvider.overrideWithValue(
          SplashGateSnapshot.withInitial(
            enabled: true,
            startDate: data.startDate,
          ),
        ),
        splashStartDateProvider.overrideWith(
          (ref) => Stream.value(data.startDate),
        ),
        splashControllerProvider.overrideWith(
          () => _FakeSplashController(data),
        ),
      ],
    );
  }

  testWidgets('golden harness ignores ambient safe-area padding', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 32, bottom: 20);
    tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 20);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    final container = dataContainer(
      SplashData(
        startDate: DateTime(2026, 1, 1),
        dayCount: 100,
        formattedStartDate: 'Jan 1, 2026',
        formattedDisplayText: 'Since Jan 1, 2026',
        buttonLabel: 'Enter',
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container: container));

    final mediaQuery = MediaQuery.of(tester.element(find.byType(SplashScreen)));
    expect(mediaQuery.padding, EdgeInsets.zero);
    expect(mediaQuery.viewPadding, EdgeInsets.zero);
  });

  testWidgets('G01: default "Since {date}", 100 days ago, en', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = dataContainer(
      SplashData(
        startDate: DateTime(2026, 1, 1),
        dayCount: 100,
        formattedStartDate: 'Jan 1, 2026',
        formattedDisplayText: 'Since Jan 1, 2026',
        buttonLabel: 'Enter',
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container: container));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash_default_en_100d.png'),
    );
  });

  testWidgets('G02: custom "{days} days strong", zh_TW', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = dataContainer(
      SplashData(
        startDate: DateTime(2026, 1, 1),
        dayCount: 100,
        formattedStartDate: '2026年1月1日',
        formattedDisplayText: '100 days strong',
        buttonLabel: '進入',
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      harness(container: container, locale: const Locale('zh', 'TW')),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash_custom_zhtw.png'),
    );
  });

  testWidgets('G03: long custom text at 2× text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    const long =
        'Every day I am grateful for the journey since the '
        'beginning, reflecting on what we have built together.';

    final container = dataContainer(
      SplashData(
        startDate: DateTime(2026, 1, 1),
        dayCount: 100,
        formattedStartDate: 'Jan 1, 2026',
        formattedDisplayText: long,
        buttonLabel: 'Enter',
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      harness(container: container, textScaler: const TextScaler.linear(2.0)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash_long_text_2x.png'),
    );
  });
}

class _FakeSplashController extends SplashController {
  _FakeSplashController(this._fixed);
  final SplashData _fixed;

  @override
  Stream<SplashState> build() async* {
    yield _fixed;
  }
}
