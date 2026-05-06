---
title: Analysis and Manage Accounts review follow-ups
date: 2026-05-05
category: test-failures
module: Analysis and Settings account-management refactor
problem_type: test_failure
component: testing_framework
symptoms:
  - Code review found missing coverage for new fallback and adaptive account-management paths
  - The new multi-account subtitle test failed because `ManageAccountsTile` used the wrong default-account source
  - A new narrow-layout sheet test exposed a header overflow in the Manage accounts surface
root_cause: test_isolation
resolution_type: test_fix
severity: medium
tags: [flutter, go-router, settings, accounts, adaptive-layout, widget-tests, l10n]
---

# Analysis and Manage Accounts review follow-ups

## Problem

The Accounts-to-Analysis refactor mostly landed correctly, but review surfaced three gaps: missing test coverage for the new `/settings` fallback paths, missing adaptive coverage for the Settings-owned Manage accounts surface, and stale `/accounts*` route metadata/comments that still conflicted with the new router contract.

## Symptoms

- Review identified missing widget coverage for `AccountFormScreen` no-stack fallbacks and the `ManageAccountsSheet` tablet dialog path.
- A new multi-account subtitle test failed because `ManageAccountsTile` preferred `settingsControllerProvider.defaultAccountId` instead of `AccountsData.defaultAccountId`.
- A new narrow-sheet test hit a `RenderFlex overflowed by 0.250 pixels on the right` exception in the Manage accounts header row.

## What Didn't Work

- Asserting the phone branch via `findsNothing` on `Dialog` was brittle in this router-backed harness. The test environment still surfaced a `Dialog` widget even when the phone path was being exercised, so negative matching on `Dialog` was not a reliable signal.
- Driving adaptive coverage only with `tester.binding.setSurfaceSize(...)` was not enough for this helper. The existing adaptive picker tests in the repo use an explicit `MediaQuery(size: ...)` wrapper, and matching that pattern made the account-management tests deterministic.

## Solution

The fix had four parts:

1. Add the missing fallback coverage to `test/widget/features/accounts/account_form_screen_test.dart`.
2. Add explicit phone/tablet adaptive coverage to `test/widget/features/accounts/manage_accounts_sheet_test.dart` using a `MediaQuery(size: ...)` wrapper in the test host.
3. Fix `ManageAccountsTile` so its multi-account subtitle derives the default account from `AccountsData.defaultAccountId`, which is the same source used by the actual Manage accounts surface.
4. Update stale `/accounts*` metadata/comments in `account_form_screen.dart`, `transaction_form_controller.dart`, `shopping_list_screen_test.dart`, and `l10n/app_en.arb`, then regenerate `lib/l10n/app_localizations.dart`.

Key implementation change:

```dart
final subtitle = accountsAsync.maybeWhen(
  data: (state) {
    final data = state;
    if (data is! AccountsData) return '';
    if (data.active.isEmpty) return l10n.manageAccountsTileSubtitleAddCta;
    if (data.active.length == 1) return data.active.first.account.name;
    final defaultMatches = data.active.where(
      (r) => r.account.id == data.defaultAccountId,
    );
    final defaultName = defaultMatches.isNotEmpty
        ? defaultMatches.first.account.name
        : data.active.first.account.name;
    return '$defaultName${l10n.manageAccountsTileSubtitleMore(data.active.length - 1)}';
  },
  orElse: () => '',
);
```

And the adaptive test host pattern that made the sheet tests stable:

```dart
Widget _wrapWithOpener({
  required ProviderContainer container,
  Size size = const Size(400, 800),
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp.router(
        // ...
      ),
    ),
  );
}
```

## Why This Works

The review findings were partly real behavior bugs and partly test-harness blind spots.

- `ManageAccountsTile` is conceptually a projection of the accounts slice, so reading the default account from a second controller created avoidable divergence. Using `AccountsData.defaultAccountId` removes that split-brain state.
- The header overflow was a real UI bug on narrow widths; wrapping the title in `Expanded` with ellipsis made the phone sheet resilient.
- The adaptive tests became stable once they followed the same explicit `MediaQuery(size: ...)` pattern already used by the repo's adaptive picker tests.
- Regenerating l10n output after updating ARB descriptions keeps generated comments aligned with the live route contract, so future grep-based release checks do not keep failing on stale route text.

## Prevention

- When a widget already gets a value from a feature state object like `AccountsData`, do not re-read the same concept from a second controller unless there is a concrete need.
- For adaptive sheet/dialog tests in this repo, prefer an explicit `MediaQueryData(size: ...)` wrapper in the host widget instead of relying only on test-window sizing.
- If a refactor renames routes, update both handwritten docs/comments and ARB descriptions in the same change, then regenerate `lib/l10n/app_localizations*.dart` before running release-gate greps.
- For review follow-ups that add new tests, keep one failing test tied to one behavioral claim. That made it obvious that the subtitle source bug was real, while the first phone-sheet assertion was only a brittle test assumption.

## Related Issues

- `docs/solutions/logic-errors/transaction-form-workflow-integrity-2026-04-25.md`
- `docs/solutions/best-practices/reactive-feature-flow-ownership-2026-04-25.md`
