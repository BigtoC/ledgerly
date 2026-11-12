---
title: Controller commands return sealed outcomes, widgets switch on them, and snackbar actions outlive the widget
date: 2026-11-01
last_updated: 2026-11-12
category: architecture-patterns
module: feature-slice controllers and widgets
problem_type: architecture_pattern
component: frontend_stimulus
severity: high
applies_when:
  - "Adding a controller command (save, archive, delete, pause, reorder, preference write) whose failure the user must see"
  - "A widget would wrap a controller call in try/catch, or start a command Future without awaiting it"
  - "A SnackBar action such as Undo, or another callback, can run after the widget that showed it has unmounted"
  - "An auto-dispose notifier writes state or starts a timer after an await, or before its try, while the screen may already be closed"
  - "A command makes a write plus a follow-up step that must not turn a committed write into a retryable failure"
symptoms:
  - "Commands started bare (Settings onChanged: (v) => ref.read(...).setThemeMode(v)) failed as uncaught zone errors and the user saw nothing"
  - "Tapping Undo after leaving the shopping list or categories screen, or after archiving the bottom Active account, threw StateError (Using ref when a widget is about to or has been unmounted is unsafe)"
  - "Closing the transaction form mid-hydration, or a form or sheet mid-save, threw UnmountedRefException or setState-after-dispose from the catch block"
  - "A recurring rule whose post-insert generation threw kept the form open so retrying inserted a duplicate; a mid-loop reorder failure left categories half reordered"
  - "A snackbar queued behind the persistent Undo snackbar (a SnackBar with an action persists in Flutter 3.47) and never appeared"
root_cause: async_timing
resolution_type: code_fix
related_components:
  - accounts_controller
  - categories_controller
  - transaction_form_controller
  - recurring_rule_form_controller
  - recurring_rules_controller
  - settings_controller
  - category_repository
  - testing_framework
tags:
  - flutter
  - riverpod
  - freezed
  - command-outcomes
  - error-handling
  - snackbar-undo
  - unmounted-ref
  - widget-lifecycle
---

# Controller commands return sealed outcomes, widgets switch on them, and snackbar actions outlive the widget

## Context

Issue #86 ("Problem: Command failures are caught in widgets or escape as unhandled errors"). Controller commands reported failure three different ways:
- They threw `*OperationException`s or repository exceptions, which 12 widget try/catch blocks caught.
- They fired effects.
- They failed from Futures that widgets started without awaiting, such as `onChanged: (v) => ref.read(...).setThemeMode(v)`. Those became uncaught zone errors that the user never saw.

Moving failure handling into the controllers exposed four lifecycle bugs, each proved by a failing test first:

- **A widget's `ref` was used after it unmounted.** A SnackBar with an action persists in Flutter 3.47 (`persist = action != null`) and lives on the root `ScaffoldMessenger`, so Undo can be tapped after its widget is gone. Undo then read that widget's `ref` and threw StateError:
  - after leaving the shopping list (`SLS07b`)
  - after leaving the categories screen (`S13`)
  - after archiving the bottom row of the accounts Active card (`MAB08`). The card is an unkeyed `Column`, so that row's tile unmounts when the row moves to Archived.
- **State was written after dispose.** Riverpod 3 throws `UnmountedRefException` on `state =` once a notifier is disposed. Closing the transaction form mid-hydration made the catch block's own `state = error(...)` throw (`TC05`, `TC12`, `TC05c`). Forms and sheets called `setState` after closing mid-save (`AF07`, `AF08`, `S12`).
- **A failure after the commit looked retryable.** Recurring generation threw after the rule was inserted, the form stayed open, and retrying inserted a duplicate. Category reorder looped separate saves and left a half-applied order.
- **Snackbars queued behind Undo.** A plain `showSnackBar` waits for the persistent Undo snackbar to be dismissed, so a failed reorder's message (`S16b`) or a set-default confirmation (`MAB12`) never appeared.

## Guidance

The rule is in `PRD.md` → *Error Handling Pattern* and `docs/architecture/layers.md`. This doc adds the details and gotchas.

### (a) A controller command never throws

```dart
Future<ArchiveAccountOutcome> archive(int accountId) async {
  try {
    final repo = ref.read(accountRepositoryProvider); // before the first await
    // ... isDefault / lastActive guards return early ...
    await repo.archive(accountId);
    return const ArchiveAccountOutcome.ok();
  } on AccountHasRecurringRuleException {
    return const ArchiveAccountOutcome.hasActiveRecurringRule();
  } catch (e) {
    debugPrint('[AccountsController] archive failed: ${e.runtimeType}');
    return const ArchiveAccountOutcome.failed();
  }
}
```

- **Put every `ref.read` inside the `try`.** Read dependencies before the first `await`, because `ref.read` on a disposed notifier throws.
- **Map the exceptions the user must see.** A typed repository exception that needs its own message gets an `on X` clause and a variant.
- **Catch everything else.** A bare `catch` logs `${e.runtimeType}` only, never amounts or memos, and returns `.failed`.
- **Post-commit steps go in their own `try`.** See (f).
- **Commands that behave alike can share a boundary.** `SettingsController._write(command, write)` wraps all seven `set*` methods.

### (b) Declare the outcome union in `*_state.dart`

```dart
/// Result of [AccountsController.archive].
@freezed
sealed class ArchiveAccountOutcome with _$ArchiveAccountOutcome {
  /// Archived. The widget shows the Undo snackbar.
  const factory ArchiveAccountOutcome.ok() = ArchiveAccountOk;

  /// An active recurring rule uses the account. The widget shows
  /// `accountsArchiveRecurringRuleError`.
  const factory ArchiveAccountOutcome.hasActiveRecurringRule() =
      ArchiveAccountHasActiveRecurringRule;

  /// Anything else went wrong. The widget shows `errorSnackbarGeneric`.
  const factory ArchiveAccountOutcome.failed() = ArchiveAccountFailed;

  // ...plus isDefault and lastActive.
}
```

- **Why `*_state.dart`.** The layer rule `widgets_forbid_data_internals` stops state files from importing repositories. An outcome therefore cannot carry a repository exception type, and the controller translates.
- **Naming.** The union is `<Verb><Noun>Outcome` and each subclass is `<Verb><Noun><Variant>`. Each variant's doc comment says what the widget does.
- **Data rides in the success variant,** for example `SaveAccountOutcome.ok(int accountId)`.
- **Add a variant only when the widget acts differently.** Delete variants that cannot be reached. The categories `typeLocked` variant and its string were removed because the type toggle is disabled in edit mode.
- **One union may serve commands the widget handles the same way:** `SettingsWriteOutcome`, `DraftSubmissionOutcome`.

### (c) Widget: await, check `mounted`, switch exhaustively

```dart
final outcome = await ref.read(accountFormActionsProvider).save(draft);
if (!mounted) return;
switch (outcome) {
  case SaveAccountOk(:final accountId):
    context.pop(accountId);
  case SaveAccountCurrencyLocked():
    setState(() {
      _saving = false;
      _errorMessage =
          AppLocalizations.of(context).accountFormCurrencyLockedError;
    });
  case SaveAccountFailed(): // same, with errorSnackbarGeneric
    // ...
}
```

- **No `try` blocks in widgets.** Command failures arrive as outcomes, never as exceptions.
- **Use an exhaustive `switch` over the generated subclasses, never `is` chains.** A new variant then fails to compile in every widget that does not handle it.
- **Check `mounted` after every `await`.** Use `mounted`, or `context.mounted` in a stateless widget, before touching `setState`, `context` or the widget's `ref`. That includes awaits on picker sheets.
- **Capture before awaiting.** Take `ScaffoldMessenger.of(context)` and `AppLocalizations` before the `await`; the captured messenger is safe to use afterwards.
- **No unhandled Futures.** Every Future is either awaited with its outcome handled, or wrapped in `unawaited(...)` on a command that cannot throw, for example `unawaited(controller.hydrate(widget.mode))`.

### (d) Write SnackBar actions that can outlive the widget

Never use the widget's `ref` inside an action. Use one of two shapes:

- **Work still matters after the widget is gone.** Capture `ProviderScope.containerOf(context, listen: false)` and the messenger while mounted, and read the notifier through the container when the action is tapped (Example 1).
- **Doing nothing is correct after the widget is gone.** Return early. In the shopping list, the auto-dispose controller's `onDispose` has already dropped the pending delete:

  ```dart
  onUndo: () {
    if (!mounted) return;
    ref.read(shoppingListControllerProvider.notifier).undoDelete();
  },
  ```

When an action reads an auto-dispose controller through the container, it may build a fresh controller just for that call, so the undo command must read its repository before its first `await`.

An Undo whose row no longer exists is a no-op: `unarchive` and `undoArchive` return `ok` when `getById` is null (`MAB07`). Pending-delete windows key Undo by id, so a stale snackbar cannot cancel a newer delete. `undoDelete(int id)` returns early when the id does not match (`RRS12`).

### (e) On a screen that shows Undo, clear before every snackbar

An action snackbar stays until it is dismissed. Even its `duration:` cannot end it, because the messenger's timer returns early when `snackBar.persist` is true. Clear before every `showSnackBar`, the Undo snackbar included:

```dart
messenger
  ..clearSnackBars()
  ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
```

Since #135 the Undo snackbar itself goes through `messenger.showUndoSnackBar(message:, undoLabel:, onUndo:)` in `lib/ui/core/widgets/undo_snack_bar.dart`, which calls `clearSnackBars()` first. The helper also passes `persist: false`, so Undo now hides after `kUndoWindow` instead of staying. Keep clearing before other snackbars on these screens, as above: without it, a message still waits behind the visible Undo for up to 4 s.

**Exception, pending transactions (PR #149).** Clearing an error removed another row's live Undo, so `PendingSnackBars` queues failure snackbars behind the Undo while `skippingId != null`. The wait stays short because the host closes the Undo when the controller commits: a SnackBar's `duration` starts only after its ~250 ms entrance, so `kUndoWindow` on the snackbar alone left Undo tappable after the 4 s commit. See [`keepalive-effect-listener-host-and-state-driven-undo-snackbar.md`](keepalive-effect-listener-host-and-state-driven-undo-snackbar.md).

The failure only shows up when an Undo snackbar is already on screen. With an empty messenger the test passes either way (`S16b`, `MAB12`).

### (f) Give post-commit steps their own `try`

Once the write has committed, a later failure must not turn the outcome into `failed`, or the user will retry and repeat the write. Report the secondary failure on the success variant instead:
- **Recurring form save.** Returns `saved(savedId, generationFailed)` (Example 3).
- **`resumeRule`.** Returns `ok(null)` when the re-read after `setActive` fails (`RRC05c`).
- **Transaction `save`.** Starts the exchange-rate fetch after its `try` with `unawaited(fetchRate())`. This is safe because `fetchRate` swallows its own errors.

### (g) Async commands that write `state`

Follow Example 2:
- **The initial `state = loading` goes inside the `try`.** It throws when called on an already-closed form (`TC05c`).
- **Add `if (!ref.mounted) return;` after each `await`.**
- **Guard the catch block's `error` write with `ref.mounted`.**
- **Timers follow the same rule.** After an `await`, check `ref.mounted` before starting a `Timer`, because `onDispose` has already run and would never cancel it. In that case `deleteRule` returns `notStarted()` (`RRC09b`).

### (h) Channel details the PRD leaves implicit

- **A command can return an outcome and still fire an effect later.** `deleteRule` returns `pending | notStarted`. A failed commit when the undo window closes arrives afterwards as `RecurringRulesDeleteFailedEffect`. When the controller outlives the screen during the window (`keepAlive`, or a `KeepAliveLink`), the effect can fire after the screen is gone. Bind a listener that captures only the messenger and the message, and don't clear it in `dispose`: `CategorySearchDetailScreen` and `SelectedSliceItemsList` (#150).
- **When form state already shows the reason, the outcome only stops the widget.** `SaveRecurringRuleOutcome.rejected()` relies on the field error keys and the `formError` banner already in state.
- **Multi-row writes belong in one repository transaction.** Repositories keep throwing because Drift rolls back a `db.transaction` only when an exception escapes. `CategoryRepository.reorder(orderedIds)` writes every `sortOrder` in one transaction, replacing the controller's loop of saves.

## Why This Matters

- **Commands outlive widgets.** Route pops, sheet dismissals and root-messenger snackbars mean the UI that started a command is often gone when it finishes, and `Ref`, `WidgetRef` and `setState` all throw after disposal. Catching in the controller, guarding with `ref.mounted`, and checking `mounted` in widgets make "the user left mid-operation" a no-op instead of a crash.
- **Retries stay safe.** Keeping commit failures apart from post-commit failures prevents duplicate inserts and half-applied writes.

## When to Apply

- A new controller method, triggered by the user, that can fail in a way the user must see.
- A widget that awaits a command, or a callback that starts a Future.
- A SnackBar action, dialog callback, timer or listener that may run after its widget or controller is disposed.
- A command that writes and then runs a secondary step.
- Not for stream reads (use `AsyncValue`), failures after the command returned (use effects), or multi-step flows with their own progress UI (use state variants).

## Examples

### 1. Archive with Undo (`accounts/views/manage_accounts_body.dart`)

Before. The widget branched on exception kinds, and Undo read the tile's `ref`, which threw once the tile had unmounted (`MAB08`):

```dart
try {
  await ref.read(accountsControllerProvider.notifier).archive(id);
} on AccountsOperationException catch (e) {
  // branch on e.kind ... return;
} catch (_) { /* generic snackbar */ return; }
messenger.showSnackBar(SnackBar(
  content: Text(l10n.accountsArchiveUndoSnackbar),
  action: SnackBarAction(
    label: l10n.commonUndo,
    onPressed: () => unawaited(
        ref.read(accountsControllerProvider.notifier).unarchive(id)),
  ),
));
```

After:

```dart
final l10n = AppLocalizations.of(context);
final messenger = ScaffoldMessenger.of(context);
final container = ProviderScope.containerOf(context, listen: false);
final outcome = await ref.read(accountsControllerProvider.notifier).archive(id);
switch (outcome) {
  case ArchiveAccountOk():
    // showUndoSnackBar (lib/ui/core/widgets/undo_snack_bar.dart) clears first.
    messenger.showUndoSnackBar(
      message: l10n.accountsArchiveUndoSnackbar,
      undoLabel: l10n.commonUndo,
      onUndo: () => unawaited(_undoArchive(container, messenger, l10n, id)),
    );
  // isDefault, lastActive, hasActiveRecurringRule: two cases elided
  case ArchiveAccountFailed():
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
}
```

`_undoArchive` is `static` and uses only what was captured. It calls `container.read(accountsControllerProvider.notifier).unarchive(id)` and shows the generic snackbar on `UnarchiveAccountFailed`.

### 2. Transaction form hydration (`transactions/view_models/transaction_form_controller.dart`)

Before:

```dart
state = TransactionFormState.loading(formMode: _formMode); // throws if disposed
try {
  final existing = await txRepo.getById(id);
  // the form may have closed during the await
  final account = await accountRepo.getById(existing.accountId);
  state = TransactionFormState.data(/* ... */);
} catch (e, st) {
  state = TransactionFormState.error(e, st, formMode: _formMode); // throws again
}
```

After:

```dart
try {
  state = TransactionFormState.loading(formMode: _formMode);
  final existing = await txRepo.getById(id);
  if (!ref.mounted) return;
  // ...
  final account = await accountRepo.getById(existing.accountId);
  if (!ref.mounted) return;
  state = TransactionFormState.data(/* ... */);
} catch (e, st) {
  if (ref.mounted) {
    state = TransactionFormState.error(e, st, formMode: _formMode);
  }
}
```

### 3. Recurring rule save (`recurring/view_models/recurring_rule_form_controller.dart`)

Before, a throw from generation escaped `save()` after the insert had committed:

```dart
savedId = await repo.insert(draft);
final useCase = ref.read(recurringGenerationUseCaseProvider); // read after an await
final outcome = await useCase.executeForRule(savedId);        // a throw escapes save()
```

After, the dependencies are read before the first `await`, and generation has its own `try`:

```dart
savedId = await repo.insert(draft);
// The rule is saved from here on, so a generation error must not
// turn into `failed`: the user would retry and insert it twice.
bool generationFailed;
try {
  generationFailed = (await useCase.executeForRule(savedId)).failed;
} catch (e) {
  debugPrint('[RecurringRuleFormController] save generation failed: '
      '${e.runtimeType}');
  generationFailed = true;
}
return SaveRecurringRuleOutcome.saved(savedId, generationFailed);
```

Because the dependencies were read up front, closing the form mid-save still runs generation for the saved rule.

### Testing the pattern

**Controller tests: one test per outcome variant.** Stub with mocktail `thenThrow` and assert with Freezed value equality:

```dart
when(() => accountRepo.archive(2)).thenThrow(StateError('db closed'));
final outcome =
    await container.read(accountsControllerProvider.notifier).archive(2);
expect(outcome, const ArchiveAccountOutcome.failed());
```

**Closing a screen mid-command.** Gate the repository call with a `Completer`, close the route, then complete the gate with an error. Nothing may be thrown (`AF07`, `AF08`, `S12`):

```dart
final saveGate = Completer<int>();
when(() => accountRepo.save(any())).thenAnswer((_) => saveGate.future);
await tester.tap(find.byKey(const ValueKey('accountForm:save')));
await tester.pump();
await tester.tap(find.byTooltip('Back')); // close while the save runs
await tester.pumpAndSettle();
saveGate.completeError(const CurrencyNotFoundException('USD'));
await tester.pumpAndSettle();
expect(tester.takeException(), isNull);
```

**The same test at controller level.** Listen to the provider and start the command. Then run `sub.close(); await c.pump();`, complete the gate, and `await expectLater(command, completes)` (`TC05`).

**A snackbar that outlives its widget.** Show the Undo snackbar, call `router.pop()`, then tap Undo. Assert that `takeException()` is null, and check the expected repository call with `verify` or `verifyNever` (`SLS07b`, `S13`).

**Gotchas:**
- **`pumpAndSettle` times out on a loading spinner.** It never settles while the pushed route shows one. Use `await tester.pump(); await tester.pump(const Duration(seconds: 1));` instead (`SLS07b`).
- **Dragging a reorderable list throws.** A `SliverReorderableList` with no `proxyDecorator` throws "No Material widget found" when dragged in a test. Call `onReorderItem!(1, 0)` directly.

## Related

- `docs/solutions/performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md`: first documented the Flutter 3.47 `persist ?? action != null` rule and the controller-side KeepAliveLink fix for Undo after dispose. This doc covers the widget side.
- `docs/solutions/logic-errors/home-pending-recurring-approval-visibility-and-undo-coordination-2026-05-09.md`: earlier `clearSnackBars()` precedent, and a keepAlive controller that owns an undo timer.
- `docs/solutions/logic-errors/home-delete-undo-stream-coordination-2026-04-26.md`: where the effect channel for failures after the command returned came from. Its code samples predate the removal of Home's undo path.
- `docs/solutions/best-practices/reactive-feature-flow-ownership-2026-04-25.md`: controller-owned guards, updated with outcome snippets.
- `docs/solutions/logic-errors/transaction-form-workflow-integrity-2026-04-25.md`: same transaction form; PopScope during save, and hydration retry.
- `docs/solutions/logic-errors/recurring-generation-and-reference-guards-2026-05-08.md`: the `*HasRecurringRuleException` types that now map to outcome variants.
- `docs/solutions/logic-errors/account-transaction-currency-invariant-2026-04-25.md`: the account currency lock, now `AccountCurrencyLockedException` → `SaveAccountOutcome.currencyLocked()`.
- `docs/solutions/ui-bugs/analysis-legend-auto-scroll-follow-and-remount.md`: the same `pumpAndSettle` trap on a loading spinner.
- GitHub: #86 (this change); #85 and #92 (the layer-boundary rule that keeps outcomes free of repository types).
