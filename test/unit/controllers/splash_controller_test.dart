// SplashController unit tests (plan §3.4, §5).
//
// Covers:
//   - Day-count math (today → 0; 100 days ago → 100; future → negative).
//   - Template substitution integration (`{date}` / `{days}`) into the
//     segmented `displayTextSegments` exposed by `SplashData`.
//   - `setStartDate` writes to the `UserPreferencesRepository`.
//   - Empty / whitespace-only custom display text falls back to the default.
//   - User templates that don't contain `{date}` get the date auto-prepended
//     so the splash never renders without a visible start-date span.
//   - Button label defaults + override.
//
// Repository is mocked via `mocktail`; clock is injected via an override of
// the `splashClockProvider` helper so tests are deterministic.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/locale_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/core/utils/date_helpers.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/splash/splash_controller.dart';
import 'package:ledgerly/features/splash/splash_state.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

@Dependencies([SplashController])
void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('zh_TW', null);
    registerFallbackValue(DateTime(2000));
  });

  group('SplashController', () {
    late _MockUserPreferencesRepository repo;
    late StreamController<DateTime?> dateCtrl;
    late StreamController<String> textCtrl;
    late StreamController<String> buttonCtrl;

    setUp(() {
      repo = _MockUserPreferencesRepository();
      dateCtrl = StreamController<DateTime?>.broadcast();
      textCtrl = StreamController<String>.broadcast();
      buttonCtrl = StreamController<String>.broadcast();

      when(() => repo.watchSplashStartDate())
          .thenAnswer((_) => dateCtrl.stream);
      when(() => repo.watchSplashDisplayText())
          .thenAnswer((_) => textCtrl.stream);
      when(() => repo.watchSplashButtonLabel())
          .thenAnswer((_) => buttonCtrl.stream);
      when(() => repo.setSplashStartDate(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      await dateCtrl.close();
      await textCtrl.close();
      await buttonCtrl.close();
    });

    ProviderContainer makeContainer({required DateTime now, Locale? locale}) {
      return ProviderContainer(
        overrides: [
          userPreferencesRepositoryProvider.overrideWithValue(repo),
          splashClockProvider.overrideWithValue(() => now),
          splashGateSnapshotProvider.overrideWithValue(
            SplashGateSnapshot.withInitial(enabled: true, startDate: null),
          ),
          userLocalePreferenceProvider.overrideWith(
            (ref) => locale ?? const Locale('en'),
          ),
        ],
      );
    }

    @Dependencies([SplashController])
    Future<SplashState> waitForData(ProviderContainer c) async {
      // Pump until we get a non-loading state.
      for (var i = 0; i < 50; i++) {
        final s = c.read(splashControllerProvider);
        if (s is AsyncData<SplashState> && s.value is! SplashLoading) {
          return s.value;
        }
        await Future<void>.delayed(Duration.zero);
      }
      throw StateError('SplashController never left loading');
    }

    test('C01: 100 days ago yields dayCount = 100', () async {
      final container = makeContainer(now: DateTime(2026, 4, 11));
      addTearDown(container.dispose);

      // Kick subscription.
      // ignore: unused_local_variable
      final _ = container.listen(splashControllerProvider, (_, _) {});
      // Let the provider's internal subscriptions attach before we emit
      // into the broadcast controllers (otherwise the events are dropped).
      await Future<void>.delayed(Duration.zero);

      dateCtrl.add(DateTime(2026, 1, 1));
      textCtrl.add('Since {date}');
      buttonCtrl.add('Enter');

      final state = await waitForData(container);
      expect(state, isA<SplashData>());
      final data = state as SplashData;
      expect(data.dayCount, 100);
      expect(data.startDate, DateTime(2026, 1, 1));
    });

    test('C02: start date = today yields dayCount = 0', () async {
      final container = makeContainer(now: DateTime(2026, 4, 21, 14, 30));
      addTearDown(container.dispose);
      container.listen(splashControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      dateCtrl.add(DateTime(2026, 4, 21));
      textCtrl.add('Since {date}');
      buttonCtrl.add('Enter');

      final data = await waitForData(container) as SplashData;
      expect(data.dayCount, 0);
    });

    test(
      'C03: future start date yields negative dayCount (no clamp)',
      () async {
        final container = makeContainer(now: DateTime(2026, 4, 21));
        addTearDown(container.dispose);
        container.listen(splashControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);

        dateCtrl.add(DateTime(2026, 4, 30));
        textCtrl.add('Since {date}');
        buttonCtrl.add('Enter');

        final data = await waitForData(container) as SplashData;
        expect(data.dayCount, -9);
      },
    );

    test('C04: default template "On {date} start using Ledgerly" yields date segment', () async {
      final container = makeContainer(now: DateTime(2026, 4, 11));
      addTearDown(container.dispose);
      container.listen(splashControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      dateCtrl.add(DateTime(2026, 1, 1));
      textCtrl.add(kDefaultSplashDisplayText);
      buttonCtrl.add('Enter');

      final data = await waitForData(container) as SplashData;
      expect(data.displayTextSegments, <SplashTextSegment>[
        (text: 'On ', isDate: false),
        (text: 'Jan 1, 2026', isDate: true),
        (text: ' start using Ledgerly', isDate: false),
      ]);
    });

    test(
      'C05: custom template with {days} but no {date} auto-prepends the date',
      () async {
        final container = makeContainer(now: DateTime(2026, 4, 11));
        addTearDown(container.dispose);
        container.listen(splashControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);

        dateCtrl.add(DateTime(2026, 1, 1));
        textCtrl.add('{days} days strong');
        buttonCtrl.add('Go');

        final data = await waitForData(container) as SplashData;
        // Auto-prepend rule: user's template lacks `{date}`, so the
        // controller injects it at the front to guarantee the start date
        // is always visible on the splash.
        expect(data.displayTextSegments, <SplashTextSegment>[
          (text: 'Jan 1, 2026', isDate: true),
          (text: ' 100 days strong', isDate: false),
        ]);
        expect(data.buttonLabel, 'Go');
      },
    );

    test('C06: empty custom text falls back to default "On {date} start using Ledgerly"', () async {
      final container = makeContainer(now: DateTime(2026, 4, 11));
      addTearDown(container.dispose);
      container.listen(splashControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      dateCtrl.add(DateTime(2026, 1, 1));
      textCtrl.add('');
      buttonCtrl.add('Enter');

      final data = await waitForData(container) as SplashData;
      expect(data.displayTextSegments, <SplashTextSegment>[
        (text: 'On ', isDate: false),
        (text: 'Jan 1, 2026', isDate: true),
        (text: ' start using Ledgerly', isDate: false),
      ]);
    });

    test('C07: whitespace-only text falls back to default', () async {
      final container = makeContainer(now: DateTime(2026, 4, 11));
      addTearDown(container.dispose);
      container.listen(splashControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      dateCtrl.add(DateTime(2026, 1, 1));
      textCtrl.add('   ');
      buttonCtrl.add('Enter');

      final data = await waitForData(container) as SplashData;
      expect(data.displayTextSegments, <SplashTextSegment>[
        (text: 'On ', isDate: false),
        (text: 'Jan 1, 2026', isDate: true),
        (text: ' start using Ledgerly', isDate: false),
      ]);
    });

    test('C08: setStartDate writes to repository', () async {
      final container = makeContainer(now: DateTime(2026, 4, 11));
      addTearDown(container.dispose);
      container.listen(splashControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      dateCtrl.add(null);
      textCtrl.add('Since {date}');
      buttonCtrl.add('Enter');
      await Future<void>.delayed(Duration.zero);

      final picked = DateTime(2026, 1, 1);
      await container
          .read(splashControllerProvider.notifier)
          .setStartDate(picked);

      verify(() => repo.setSplashStartDate(picked)).called(1);
    });

    test('C09: zh_TW locale formats {date} using zh_TW conventions', () async {
      final container = makeContainer(
        now: DateTime(2026, 4, 11),
        locale: const Locale('zh', 'TW'),
      );
      addTearDown(container.dispose);
      container.listen(splashControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      dateCtrl.add(DateTime(2026, 1, 1));
      textCtrl.add('Since {date}');
      buttonCtrl.add('Enter');

      final data = await waitForData(container) as SplashData;
      final dateSeg = data.displayTextSegments.singleWhere((s) => s.isDate);
      expect(dateSeg.text, '2026年1月1日');
    });

    test('C10: user template without {date} or {days} still auto-prepends the date', () async {
      final container = makeContainer(now: DateTime(2026, 4, 11));
      addTearDown(container.dispose);
      container.listen(splashControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      dateCtrl.add(DateTime(2026, 1, 1));
      textCtrl.add('My budget journey');
      buttonCtrl.add('Enter');

      final data = await waitForData(container) as SplashData;
      // The user deleted `{date}` (or never wrote it). The controller
      // injects it at the front so the date never disappears.
      expect(data.displayTextSegments, <SplashTextSegment>[
        (text: 'Jan 1, 2026', isDate: true),
        (text: ' My budget journey', isDate: false),
      ]);
    });

    test(
      'C11: user template that already contains {date} is not auto-prepended',
      () async {
        final container = makeContainer(now: DateTime(2026, 4, 11));
        addTearDown(container.dispose);
        container.listen(splashControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);

        dateCtrl.add(DateTime(2026, 1, 1));
        textCtrl.add('budget started {date}');
        buttonCtrl.add('Enter');

        final data = await waitForData(container) as SplashData;
        // User-positioned `{date}` is preserved — no prefix injected.
        expect(data.displayTextSegments, <SplashTextSegment>[
          (text: 'budget started ', isDate: false),
          (text: 'Jan 1, 2026', isDate: true),
        ]);
      },
    );
  });
}
