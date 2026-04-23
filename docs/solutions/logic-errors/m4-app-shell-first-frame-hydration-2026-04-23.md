---
title: M4 app shell first-frame hydration and splash gating
date: 2026-04-23
category: logic-errors
module: app-shell
problem_type: logic_error
component: frontend_stimulus
symptoms:
  - Persisted splash/theme/locale state only applied after async streams emitted
  - Disabling splash while already on `/splash` did not redirect to `/home`
root_cause: async_timing
resolution_type: code_fix
severity: high
tags: [flutter, riverpod, go-router, bootstrap, first-frame, splash]
---

# M4 app shell first-frame hydration and splash gating

## Problem

The M4 app shell loaded persisted preferences through reactive streams only, which meant the first rendered frame could use fallback state instead of the saved user state. That showed up most clearly in splash routing and splash UI, but the same pattern also affected theme and locale hydration.

## Symptoms

- A saved `splash_start_date` could still render the `Set start date` prompt briefly on cold launch.
- Toggling `splash_enabled` off while already on `/splash` did not reroute to `/home`.
- Persisted theme and locale were only applied after stream delivery instead of on the first frame.

## What Didn't Work

- Relying on `watchSplashStartDate()`, `watchThemeMode()`, and `watchLocale()` alone. The streams are correct for steady-state reactivity, but they do not guarantee the first build sees persisted values.
- Testing only settled end states. That let the app look correct after pumps while missing the first-frame contract from the plan.

## Solution

Bootstrap now eagerly reads the persisted theme mode, locale, splash-enabled flag, and splash start date before `runApp`, then injects those values as initial providers/overrides for the first frame.

Key changes:

```dart
final initialThemeMode = await getThemeModeFn(preferencesRepo);
final initialLocale = await getLocaleFn(preferencesRepo);
final splashEnabled = await getSplashEnabledFn(preferencesRepo);
final splashStartDate = await getSplashStartDateFn(preferencesRepo);
```

```dart
overrides: [
  appDatabaseProvider.overrideWithValue(db),
  initialThemeModeProvider.overrideWithValue(initialThemeMode),
  initialPreferredLocaleProvider.overrideWithValue(initialLocale),
  splashGateSnapshotProvider.overrideWith((ref) {
    final notifier = SplashGateSnapshot.withInitial(
      enabled: splashEnabled,
      startDate: splashStartDate,
    );
    ...
  }),
]
```

The reactive providers now fall back to those eager values until the streams emit:

```dart
ThemeMode themeMode(Ref ref) {
  final initial = ref.watch(initialThemeModeProvider) ?? ThemeMode.system;
  return ref.watch(themeModeStreamProvider).value ?? initial;
}
```

```dart
Locale? userLocalePreference(Ref ref) =>
    ref.watch(userLocalePreferenceStreamProvider).value ??
    ref.watch(initialPreferredLocaleProvider);
```

Splash routing and splash UI were aligned to the same first-frame source of truth:

```dart
if (!gate.splashEnabled) {
  if (state.matchedLocation == '/' || state.matchedLocation == '/splash') {
    return '/home';
  }
}
```

```dart
final initialStartDate = ref.read(splashGateSnapshotProvider).splashStartDate;
final startDate =
    ref.watch(splashStartDateProvider).valueOrNull ?? initialStartDate;
```

The bootstrap test was expanded with injectable hooks so it proves the intended startup order instead of only `openDatabase -> runApp`.

## Why This Works

The bug was not that the streams were wrong; it was that the app depended on asynchronous stream delivery to satisfy first-frame requirements. Reading persisted values eagerly in bootstrap and feeding them into synchronous providers bridges that timing gap. The app still stays reactive afterward because the same stream providers continue to drive updates after startup.

## Prevention

- When a route or UI must be correct on the first frame, do not rely on async stream delivery alone. Seed an initial synchronous value during bootstrap.
- Keep routing state and screen state aligned to the same bootstrapped source of truth.
- Test first-frame behavior explicitly, not only final settled trees.
- For bootstrap-order tests, inject hooks around each required startup step so the test can prove the real sequence.

## Related Issues

- `docs/plans/m4-app-shell/plan.md`
- `docs/solutions/database-issues/drift-schema-v1-snapshot-drift-2026-04-23.md`
