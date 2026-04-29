// SettingsController unit tests (plan §3.3).
//
// Covers:
//   - State transitions: loading → data on joint first emit of all
//     eight preference streams.
//   - Each command writes through the repository with the expected value.
//   - State re-emits on upstream stream updates (write → read loop).
//   - Empty / whitespace-only free-text writes normalize to the
//     seed defaults (so the UI renders the localized placeholder instead
//     of an empty override echo).
//   - Upstream stream error surfaces as `SettingsState.error`.
//
// Repository is mocked via `mocktail`; no live DB.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/settings/settings_controller.dart';
import 'package:ledgerly/features/settings/settings_state.dart';

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ThemeMode.light);
    registerFallbackValue(const Locale('en'));
    registerFallbackValue(DateTime(2000));
  });

  group('SettingsController', () {
    late _MockUserPreferencesRepository repo;
    late StreamController<ThemeMode> themeCtrl;
    late StreamController<Locale?> localeCtrl;
    late StreamController<String> defaultCurrencyCtrl;
    late StreamController<int?> defaultAccountCtrl;
    late StreamController<bool> splashEnabledCtrl;
    late StreamController<DateTime?> splashStartDateCtrl;
    late StreamController<String> splashDisplayTextCtrl;
    late StreamController<String> splashButtonLabelCtrl;

    setUp(() {
      repo = _MockUserPreferencesRepository();
      themeCtrl = StreamController<ThemeMode>.broadcast();
      localeCtrl = StreamController<Locale?>.broadcast();
      defaultCurrencyCtrl = StreamController<String>.broadcast();
      defaultAccountCtrl = StreamController<int?>.broadcast();
      splashEnabledCtrl = StreamController<bool>.broadcast();
      splashStartDateCtrl = StreamController<DateTime?>.broadcast();
      splashDisplayTextCtrl = StreamController<String>.broadcast();
      splashButtonLabelCtrl = StreamController<String>.broadcast();

      when(() => repo.watchThemeMode()).thenAnswer((_) => themeCtrl.stream);
      when(() => repo.watchLocale()).thenAnswer((_) => localeCtrl.stream);
      when(
        () => repo.watchDefaultCurrency(),
      ).thenAnswer((_) => defaultCurrencyCtrl.stream);
      when(
        () => repo.watchDefaultAccountId(),
      ).thenAnswer((_) => defaultAccountCtrl.stream);
      when(
        () => repo.watchSplashEnabled(),
      ).thenAnswer((_) => splashEnabledCtrl.stream);
      when(
        () => repo.watchSplashStartDate(),
      ).thenAnswer((_) => splashStartDateCtrl.stream);
      when(
        () => repo.watchSplashDisplayText(),
      ).thenAnswer((_) => splashDisplayTextCtrl.stream);
      when(
        () => repo.watchSplashButtonLabel(),
      ).thenAnswer((_) => splashButtonLabelCtrl.stream);
    });

    tearDown(() async {
      await themeCtrl.close();
      await localeCtrl.close();
      await defaultCurrencyCtrl.close();
      await defaultAccountCtrl.close();
      await splashEnabledCtrl.close();
      await splashStartDateCtrl.close();
      await splashDisplayTextCtrl.close();
      await splashButtonLabelCtrl.close();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [userPreferencesRepositoryProvider.overrideWithValue(repo)],
      );
    }

    Future<void> pushAllInitial() async {
      themeCtrl.add(ThemeMode.light);
      localeCtrl.add(null);
      defaultCurrencyCtrl.add('USD');
      defaultAccountCtrl.add(null);
      splashEnabledCtrl.add(true);
      splashStartDateCtrl.add(null);
      splashDisplayTextCtrl.add(kDefaultSplashDisplayText);
      splashButtonLabelCtrl.add(kDefaultSplashButtonLabel);
      await Future<void>.delayed(Duration.zero);
    }

    Future<SettingsState> waitForData(ProviderContainer c) async {
      for (var i = 0; i < 200; i++) {
        final s = c.read(settingsControllerProvider);
        if (s is AsyncData<SettingsState> && s.value is SettingsData) {
          return s.value;
        }
        await Future<void>.delayed(Duration.zero);
      }
      throw StateError('SettingsController never produced data');
    }

    test(
      'SC01: starts loading, transitions to data on joint first emit',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(settingsControllerProvider, (_, _) {});

        expect(
          container.read(settingsControllerProvider),
          isA<AsyncLoading<SettingsState>>(),
        );

        await pushAllInitial();
        final state = await waitForData(container) as SettingsData;
        expect(state.themeMode, ThemeMode.light);
        expect(state.locale, isNull);
        expect(state.defaultCurrency, 'USD');
        expect(state.defaultAccountId, isNull);
        expect(state.splashEnabled, isTrue);
        expect(state.splashStartDate, isNull);
        expect(state.splashDisplayText, isNull); // default normalized away
        expect(state.splashButtonLabel, isNull);
      },
    );

    test('SC02: setThemeMode writes through repo', () async {
      when(() => repo.setThemeMode(ThemeMode.dark)).thenAnswer((_) async {});
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(settingsControllerProvider, (_, _) {});
      await pushAllInitial();
      await waitForData(container);

      await container
          .read(settingsControllerProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      verify(() => repo.setThemeMode(ThemeMode.dark)).called(1);
    });

    test('SC03: setLocale writes through repo', () async {
      when(
        () => repo.setLocale(const Locale('zh', 'TW')),
      ).thenAnswer((_) async {});
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(settingsControllerProvider, (_, _) {});
      await pushAllInitial();
      await waitForData(container);

      await container
          .read(settingsControllerProvider.notifier)
          .setLocale(const Locale('zh', 'TW'));
      verify(() => repo.setLocale(const Locale('zh', 'TW'))).called(1);
    });

    test('SC04: setDefaultCurrency writes through repo', () async {
      when(() => repo.setDefaultCurrency('JPY')).thenAnswer((_) async {});
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(settingsControllerProvider, (_, _) {});
      await pushAllInitial();
      await waitForData(container);

      await container
          .read(settingsControllerProvider.notifier)
          .setDefaultCurrency('JPY');
      verify(() => repo.setDefaultCurrency('JPY')).called(1);
    });

    test('SC05: setDefaultAccountId writes through repo', () async {
      when(() => repo.setDefaultAccountId(42)).thenAnswer((_) async {});
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(settingsControllerProvider, (_, _) {});
      await pushAllInitial();
      await waitForData(container);

      await container
          .read(settingsControllerProvider.notifier)
          .setDefaultAccountId(42);
      verify(() => repo.setDefaultAccountId(42)).called(1);
    });

    test('SC06: setSplashEnabled writes through repo', () async {
      when(() => repo.setSplashEnabled(false)).thenAnswer((_) async {});
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(settingsControllerProvider, (_, _) {});
      await pushAllInitial();
      await waitForData(container);

      await container
          .read(settingsControllerProvider.notifier)
          .setSplashEnabled(false);
      verify(() => repo.setSplashEnabled(false)).called(1);
    });

    test('SC07: setSplashStartDate writes through repo', () async {
      final d = DateTime(2024, 1, 15);
      when(() => repo.setSplashStartDate(d)).thenAnswer((_) async {});
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(settingsControllerProvider, (_, _) {});
      await pushAllInitial();
      await waitForData(container);

      await container
          .read(settingsControllerProvider.notifier)
          .setSplashStartDate(d);
      verify(() => repo.setSplashStartDate(d)).called(1);
    });

    test('SC08: setSplashDisplayText writes non-empty value as-is', () async {
      when(
        () => repo.setSplashDisplayText('Day {days}'),
      ).thenAnswer((_) async {});
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(settingsControllerProvider, (_, _) {});
      await pushAllInitial();
      await waitForData(container);

      await container
          .read(settingsControllerProvider.notifier)
          .setSplashDisplayText('Day {days}');
      verify(() => repo.setSplashDisplayText('Day {days}')).called(1);
    });

    test(
      'SC09: setSplashDisplayText normalizes empty to seed default',
      () async {
        when(
          () => repo.setSplashDisplayText(kDefaultSplashDisplayText),
        ).thenAnswer((_) async {});
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(settingsControllerProvider, (_, _) {});
        await pushAllInitial();
        await waitForData(container);

        await container
            .read(settingsControllerProvider.notifier)
            .setSplashDisplayText('   ');
        verify(
          () => repo.setSplashDisplayText(kDefaultSplashDisplayText),
        ).called(1);
      },
    );

    test('SC10: setSplashButtonLabel writes non-empty value as-is', () async {
      when(() => repo.setSplashButtonLabel('Go!')).thenAnswer((_) async {});
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(settingsControllerProvider, (_, _) {});
      await pushAllInitial();
      await waitForData(container);

      await container
          .read(settingsControllerProvider.notifier)
          .setSplashButtonLabel('Go!');
      verify(() => repo.setSplashButtonLabel('Go!')).called(1);
    });

    test(
      'SC11: setSplashButtonLabel normalizes empty to seed default',
      () async {
        when(
          () => repo.setSplashButtonLabel(kDefaultSplashButtonLabel),
        ).thenAnswer((_) async {});
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(settingsControllerProvider, (_, _) {});
        await pushAllInitial();
        await waitForData(container);

        await container
            .read(settingsControllerProvider.notifier)
            .setSplashButtonLabel('');
        verify(
          () => repo.setSplashButtonLabel(kDefaultSplashButtonLabel),
        ).called(1);
      },
    );

    test('SC12: state re-emits when upstream streams update', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(settingsControllerProvider, (_, _) {});
      await pushAllInitial();
      final first = await waitForData(container) as SettingsData;
      expect(first.themeMode, ThemeMode.light);

      themeCtrl.add(ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);
      final second =
          container.read(settingsControllerProvider).value! as SettingsData;
      expect(second.themeMode, ThemeMode.dark);

      defaultAccountCtrl.add(7);
      await Future<void>.delayed(Duration.zero);
      final third =
          container.read(settingsControllerProvider).value! as SettingsData;
      expect(third.defaultAccountId, 7);
    });

    test('SC13: upstream error surfaces as SettingsState.error', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(settingsControllerProvider, (_, _) {});
      await pushAllInitial();
      await waitForData(container);

      themeCtrl.addError(
        PreferenceDecodeException('theme_mode', '"purple"', 'bad value'),
      );
      // AsyncValue from a broadcast error surfaces as AsyncError.
      for (var i = 0; i < 200; i++) {
        final s = container.read(settingsControllerProvider);
        if (s is AsyncError<SettingsState>) {
          expect(s.error, isA<PreferenceDecodeException>());
          return;
        }
        if (s is AsyncData<SettingsState> && s.value is SettingsError) {
          return;
        }
        await Future<void>.delayed(Duration.zero);
      }
      fail('SettingsController did not surface an error');
    });
  });
}
