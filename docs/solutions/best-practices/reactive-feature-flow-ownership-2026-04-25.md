---
title: Reactive feature-flow ownership for M5 UI slices
date: 2026-04-25
category: best-practices
module: m5-wave-1-feature-flows
problem_type: best_practice
component: development_workflow
severity: medium
applies_when:
  - Adding modal create and edit routes in feature slices
  - Showing derived settings or account UI from repository-backed state
  - Enforcing destructive-account guards tied to live references
  - Collecting first-run input before persisting preferences
tags:
  - flutter
  - riverpod
  - go-router
  - drift
  - reactive-state
  - feature-slices
  - accounts
  - settings
---

# Reactive feature-flow ownership for M5 UI slices

## Context

M5 Wave 1 hardening exposed the same structural mistake in several places: important feature-flow rules were living too close to widgets, or were modeled as one-shot reads instead of reactive contracts. That showed up as unreachable modal routes, stale settings UI, unsafe archive behavior, and a splash first-run flow that persisted a placeholder value instead of waiting for explicit user input.

The fixes converged on one reusable pattern: router owns navigation semantics, repositories and controllers own live correctness rules, feature-scoped providers and actions own orchestration, and widgets stay focused on rendering and dispatching user intent.

## Guidance

Model modal navigation semantics at the router layer.

If a screen must behave like a root modal from anywhere in the app shell, declare it that way in `lib/app/router.dart` instead of trying to recreate modal behavior inside the originating screen.

```dart
GoRoute(
  path: '/accounts',
  builder: (_, _) => const AccountsScreen(),
  routes: [
    GoRoute(
      path: 'new',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (ctx, state) => _modalPage(
        state,
        const AccountFormScreen(),
        fullscreenDialog: true,
      ),
    ),
    GoRoute(
      path: ':id',
      redirect: (_, state) =>
          int.tryParse(state.pathParameters['id'] ?? '') == null
          ? '/accounts'
          : null,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (ctx, state) => _modalPage(
        state,
        AccountFormScreen(
          accountId: int.parse(state.pathParameters['id']!),
        ),
        fullscreenDialog: true,
      ),
    ),
  ],
)
```

Treat invalid route parameters as router concerns, not widget-state concerns. Redirect out before a broken edit flow is constructed.

Put destructive safety rules in repositories and controllers, backed by live data.

The account list could not reliably decide archive vs delete affordances from widget-local heuristics. The fix added a reactive reference signal in the data layer and used the controller as the last application-layer guard before the write.

```dart
Stream<bool> watchIsReferenced(int id) {
  return _txDao.watchCountByAccount(id).map((count) => count > 0);
}
```

The controller also became the correct place to block archiving the current default account before the repository write runs:

```dart
Future<void> archive(int accountId) async {
  final prefs = ref.read(userPreferencesRepositoryProvider);
  final currentDefault = state.value is AccountsData
      ? (state.value! as AccountsData).defaultAccountId
      : await prefs.getDefaultAccountId();
  if (currentDefault == accountId) {
    throw const AccountsOperationException(
      AccountsOperationError.defaultAccount,
    );
  }
  ...
  await repo.archive(accountId);
}
```

Keep widgets on feature-facing providers and actions instead of direct repository orchestration.

When a widget needs derived state or a feature command, add a feature-scoped provider or action wrapper rather than having the widget reach straight into data-layer details. This keeps the repository boundary intact while removing ad hoc one-off wiring from leaf widgets.

```dart
final settingsDefaultAccountProvider = StreamProvider.autoDispose
    .family<Account?, int>((ref, id) {
      final repo = ref.watch(accountRepositoryProvider);
      return repo.watchById(id);
    });
```

```dart
final subtitle = id == null
    ? l10n.settingsDefaultAccountEmpty
    : ref
          .watch(settingsDefaultAccountProvider(id))
          .maybeWhen(
            data: (a) => a?.name ?? l10n.settingsDefaultAccountEmpty,
            orElse: () => '',
          );
```

```dart
final id = await ref.read(accountFormActionsProvider).save(draft);
if (mounted) context.pop(id);
```

Use explicit user input flows before persisting first-run state.

If a preference is supposed to come from the user, do not silently persist a default placeholder during the first interaction. The splash fix replaced an immediate write with an explicit `showDatePicker(...)` flow.

```dart
onPressed: () async {
  final initial = clock();
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(1900),
    lastDate: DateTime(9999, 12, 31),
  );
  if (picked == null) return;
  if (!context.mounted) return;
  await ref
      .read(splashControllerProvider.notifier)
      .setStartDate(picked);
},
```

## Why This Matters

This pattern prevents the same class of bug from reappearing under different UI symptoms.

- Router-defined modal pages keep deep links, shell navigation, and edit flows consistent.
- Repository-backed reactive signals stop destructive affordances from drifting away from live data.
- Feature-scoped providers keep widgets small without letting them collapse into data-layer glue code.
- Stream-backed lookups stop settings and account surfaces from going stale after cross-screen edits.
- Explicit first-run input capture avoids persisting the wrong data just because a screen needed to move forward.

## When to Apply

- A form or edit screen should open as a modal from inside a shell route.
- A route parameter can be stale, malformed, or missing.
- A destructive action depends on global app state or referential integrity.
- Multiple screens can change the same default, selected, or current entity.
- A widget starts reaching into repository providers to fill a reactive gap.
- A first-run or onboarding flow currently persists a guessed value instead of waiting for explicit confirmation.

## Examples

- Modal edit/create flows: root-modal routes plus redirect-based invalid-id recovery in `lib/app/router.dart`
- Destructive account actions: reactive reference tracking in `lib/data/repositories/account_repository.dart` plus default-account guard in `lib/features/accounts/accounts_controller.dart`
- First-run splash input: `lib/features/splash/splash_screen.dart` waits for explicit `showDatePicker(...)` selection before persisting the start date
- Cross-screen derived state: `lib/features/settings/settings_providers.dart` and `lib/features/accounts/accounts_providers.dart` expose stream-backed lookups and feature-facing actions so widgets stay render-and-dispatch only

## Related

- `docs/solutions/logic-errors/m4-app-shell-first-frame-hydration-2026-04-23.md` — first-frame splash/bootstrap synchronization and route gating background
- `docs/solutions/logic-errors/account-transaction-currency-invariant-2026-04-25.md` — same principle applied to repository-owned correctness rules for balances and write paths
- `test/widget/smoke_test.dart` and `test/integration/bootstrap_to_home_test.dart` — regression proof points for first-run splash behavior
