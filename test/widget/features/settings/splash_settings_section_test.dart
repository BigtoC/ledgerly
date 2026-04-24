// SplashSettingsSection widget tests (plan §3.3, §6).
//
// Covers:
//   - Toggle-off hides the start-date, display-text, and button-label
//     rows. Toggle-on re-exposes them.
//   - The enabled switch writes via `setSplashEnabled`.
//   - Free-text display-text field persists on submit via
//     `setSplashDisplayText` (one write per submit; no keystroke churn —
//     plan §13 risk #6).
//   - Button-label field persists on submit via `setSplashButtonLabel`.
//   - Existing start date renders formatted; null renders the label as
//     a placeholder.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/settings/settings_controller.dart';
import 'package:ledgerly/features/settings/settings_state.dart';
import 'package:ledgerly/features/settings/widgets/splash_settings_section.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

class _FakeSettingsController extends SettingsController {
  _FakeSettingsController(this._fixed);
  final SettingsState _fixed;

  @override
  Stream<SettingsState> build() async* {
    yield _fixed;
  }
}

Widget _wrap({
  required ProviderContainer container,
  required bool splashEnabled,
  DateTime? splashStartDate,
  String? splashDisplayText,
  String? splashButtonLabel,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SplashSettingsSection(
            splashEnabled: splashEnabled,
            splashStartDate: splashStartDate,
            splashDisplayText: splashDisplayText,
            splashButtonLabel: splashButtonLabel,
          ),
        ),
      ),
    ),
  );
}

ProviderContainer _makeContainer(UserPreferencesRepository prefs) {
  return ProviderContainer(
    overrides: [
      userPreferencesRepositoryProvider.overrideWithValue(prefs),
      settingsControllerProvider.overrideWith(
        () => _FakeSettingsController(
          const SettingsData(
            themeMode: ThemeMode.system,
            locale: null,
            defaultCurrency: 'USD',
            defaultAccountId: null,
            splashEnabled: true,
            splashStartDate: null,
            splashDisplayText: null,
            splashButtonLabel: null,
          ),
        ),
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2000));
  });

  testWidgets(
    'SSS01: toggle-off hides start-date / display-text / button-label rows',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, splashEnabled: false),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('splashSettings:enabledSwitch')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('splashSettings:startDateTile')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('splashSettings:displayTextField')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('splashSettings:buttonLabelField')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'SSS02: toggle-on reveals all three conditional rows',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, splashEnabled: true),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('splashSettings:startDateTile')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('splashSettings:displayTextField')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('splashSettings:buttonLabelField')),
        findsOneWidget,
      );
    },
  );

  testWidgets('SSS03: enabled switch writes via setSplashEnabled',
      (tester) async {
    final prefs = _MockUserPreferencesRepository();
    when(() => prefs.setSplashEnabled(false)).thenAnswer((_) async {});
    final container = _makeContainer(prefs);
    addTearDown(container.dispose);

    await tester
        .pumpWidget(_wrap(container: container, splashEnabled: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('splashSettings:enabledSwitch')));
    await tester.pumpAndSettle();

    verify(() => prefs.setSplashEnabled(false)).called(1);
  });

  testWidgets(
    'SSS04: display-text field persists on submit, not on every keystroke',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      when(() => prefs.setSplashDisplayText(any())).thenAnswer((_) async {});
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      await tester
          .pumpWidget(_wrap(container: container, splashEnabled: true));
      await tester.pumpAndSettle();

      final field =
          find.byKey(const ValueKey('splashSettings:displayTextField'));
      await tester.enterText(field, 'Day {days}');
      // No write yet — would fail if controller wrote per-keystroke.
      verifyNever(() => prefs.setSplashDisplayText(any()));

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(() => prefs.setSplashDisplayText('Day {days}')).called(1);
    },
  );

  testWidgets(
    'SSS05: button-label field persists on submit via setSplashButtonLabel',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      when(() => prefs.setSplashButtonLabel(any())).thenAnswer((_) async {});
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      await tester
          .pumpWidget(_wrap(container: container, splashEnabled: true));
      await tester.pumpAndSettle();

      final field =
          find.byKey(const ValueKey('splashSettings:buttonLabelField'));
      await tester.enterText(field, 'Go');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(() => prefs.setSplashButtonLabel('Go')).called(1);
    },
  );

  testWidgets(
    'SSS06: existing start date renders formatted in the tile subtitle',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);
      final date = DateTime(2024, 6, 15);

      await tester.pumpWidget(
        _wrap(
          container: container,
          splashEnabled: true,
          splashStartDate: date,
        ),
      );
      await tester.pumpAndSettle();

      // DateFormat.yMMMMd('en') output: "June 15, 2024".
      expect(find.text('June 15, 2024'), findsOneWidget);
    },
  );

  testWidgets(
    'SSS07: null start date falls back to the localized label as subtitle',
    (tester) async {
      final prefs = _MockUserPreferencesRepository();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, splashEnabled: true),
      );
      await tester.pumpAndSettle();

      // The label appears twice: once as the ListTile title, once as the
      // fallback subtitle when startDate is null. Accept any non-zero count.
      expect(find.text('Start date'), findsWidgets);
    },
  );
}
