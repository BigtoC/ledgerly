---
title: Transaction form workflow integrity across recovery, mutation, and adaptive routing
date: 2026-04-25
category: logic-errors
module: transactions
problem_type: logic_error
component: frontend_stimulus
symptoms:
  - Draft transaction state could be lost when category management was opened from an empty-category path.
  - Duplicate hydration could carry a stale amount into a fallback account with a different currency.
  - Back navigation could dismiss the form while save or delete was still in flight.
  - The adaptive add-transaction route was only covered for wide screens, leaving phone presentation unproved.
root_cause: logic_error
resolution_type: code_fix
severity: high
related_components:
  - app_router
  - transaction_form_controller
  - transaction_form_screen
  - category_management
tags:
  - flutter
  - go-router
  - riverpod
  - transaction-form
  - draft-state
  - adaptive-dialog
  - in-flight-guard
  - regression-test
---

# Transaction form workflow integrity across recovery, mutation, and adaptive routing

## Problem

The Wave 2 transaction form had several workflow-integrity gaps across routing, recovery, and async mutation windows. Individually they looked small, but together they allowed users to lose draft state, carry invalid duplicated amounts across currencies, or escape the form while save/delete work was still running.

## Symptoms

- Opening category management from an empty-category flow could leave the transaction draft unrecoverable if navigation replaced the form route.
- Duplicating a transaction whose source account no longer existed could prefill the old amount onto a fallback account that used a different currency.
- Pressing Back during `save()` or `deleteExisting()` could pop the route before the operation finished, skipping the normal success/failure handling path.
- `/home/add` had a wide-screen dialog regression test but no corresponding narrow-screen assertion.

## What Didn't Work

- Relying on `IgnorePointer` alone was not enough. It blocked taps inside the form body, but it did not stop route-level back navigation while `save()` or `deleteExisting()` was awaiting.
- Treating `isSaving` as "not dirty" in `PopScope.canPop` accidentally reopened the route during the exact mutation window that should have been most locked down.
- Preserving duplicate prefill blindly across fallback-account resolution was unsafe because `amount_minor_units` only makes sense in the source currency.
- The earlier router coverage proved the `>=600dp` dialog path only, so the primary mobile presentation remained vulnerable to regressions.

## Solution

The fix tightened the transaction-form workflow at the points where routing, async mutation, and draft recovery crossed.

1. Preserve the draft form route when category management is opened from an empty-category path.

`lib/features/transactions/transaction_form_screen.dart`

```dart
if (categories.isEmpty) {
  await context.push('/settings/categories');
  return;
}
```

Using `push` instead of `go` keeps the in-progress form on the navigation stack so returning from category management restores the draft.

2. Clear duplicated amount when fallback-account currency differs from the source currency.

`lib/features/transactions/transaction_form_controller.dart`

```dart
final preservesAmount = source.currency.code == account.currency.code;
final amountMinorUnits = preservesAmount ? source.amountMinorUnits : 0;
_keypad = preservesAmount
    ? _keypadFromAmount(
        source.amountMinorUnits,
        decimals: account.currency.decimals,
      )
    : const KeypadState.initial();
```

That keeps duplicate hydration from silently reinterpreting minor units in the wrong currency.

3. Block route pop during save/delete, not just body interaction.

`lib/features/transactions/transaction_form_screen.dart`

```dart
return PopScope(
  canPop: _canPop(state),
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;
    if (_blocksPopDuringMutation(state)) return;
    final shouldDiscard = await _confirmDiscard(context, l10n);
    if (shouldDiscard && context.mounted) {
      context.pop();
    }
  },
  child: Scaffold(...),
);
```

```dart
bool _blocksPopDuringMutation(TransactionFormState state) {
  return state is TransactionFormData && (state.isSaving || state.isDeleting);
}

bool _canPop(TransactionFormState state) {
  if (_blocksPopDuringMutation(state)) return false;
  return !_isDirty(state);
}
```

This closes the gap where the screen could disappear while the controller was still awaiting repository work.

4. Keep the rest of the in-flight guardrails aligned with the same flags.

- `TransactionFormState.canSave` already requires `!isSaving && !isDeleting`.
- Controller mutation commands already early-return while save/delete is in flight.
- The screen wraps the form body in `IgnorePointer(ignoring: controlsLocked)`.

The pop-lock fix makes route navigation follow the same mutation contract.

5. Add regressions for the broken workflow edges.

- `WS08`: empty-category recovery preserves draft memo
- `WS10`: back-nav is blocked while save is in flight
- `WS11`: back-nav is blocked while delete is in flight
- `/home/add stays full-screen below 600dp`
- `TC22`: duplicate fallback to different-currency account clears amount
- `TC23`: retry hydration preserves duplicate mode after recovery

## Why This Works

- Draft preservation depends on stack semantics, not just controller state. If the route is replaced, the form is gone no matter how correct the controller is.
- Duplicate amounts are only valid when the selected account currency matches the source currency, so clearing on mismatch is safer than guessing at a conversion.
- Async mutation safety must be enforced at every escape hatch: controller commands, widget interaction, and route pop behavior. Leaving one path open breaks the whole contract.
- Adaptive routes need both sides of the breakpoint covered; testing only the dialog path does not protect the mobile-first path most users see.

## Prevention

- When a form must survive a detour flow (`/settings/categories`, `/accounts/new`, etc.), prefer `push` unless replacing the form is explicitly intended.
- Treat `isSaving` and `isDeleting` as navigation locks as well as input locks.
- If fallback hydration crosses a currency boundary, never reuse stored minor units unless the currencies are identical.
- Cover adaptive route behavior on both sides of the breakpoint, not just the new branch.
- Add regression tests for route-pop behavior during async mutations; body-level `IgnorePointer` is not enough.

Verification that passed for this fix:

- `dart run build_runner build --delete-conflicting-outputs`
- `dart run import_lint`
- `flutter analyze`
- `flutter test`

## Related Issues

- `docs/solutions/best-practices/reactive-feature-flow-ownership-2026-04-25.md` — broader guidance on router-owned modal behavior and feature-flow ownership.
- `docs/solutions/logic-errors/account-transaction-currency-invariant-2026-04-25.md` — related currency-integrity background for transaction/account interactions.
- `docs/solutions/logic-errors/m4-app-shell-first-frame-hydration-2026-04-23.md` — adjacent hydration/recovery pattern, but not the same transaction-form workflow problem.
