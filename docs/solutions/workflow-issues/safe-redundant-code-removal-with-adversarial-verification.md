---
title: Removing redundant code safely with independent behaviour and project-rules verification
date: 2026-11-04
category: workflow-issues
module: codebase-wide (lib/ and test/)
problem_type: workflow_issue
component: development_workflow
severity: medium
applies_when:
  - "Removing dead, duplicated, test-only or redundant code across many files or feature slices in one branch"
  - "A finding says a symbol is unused in lib/ or called only from tests, while PRD.md or a plan may name it as a planned seam"
  - "Collapsing near-identical code where a subtle API difference could change behaviour, such as Drift Value.absent() vs Value(null) or Riverpod dispose ordering"
  - "Running a multi-agent find, verify and implement pipeline where every commit must pass codegen, analyze and the full suite on its own"
  - "Commits are SSH-signed through 1Password and signing can fail mid-run while subagents are committing"
symptoms:
  - "Four copies of the chart aggregate SQL, five identical Drift-to-domain Currency mappers, and seven copies of the Undo snackbar and six of the Cancel/confirm dialog"
  - "Finders reported 'unused' or 'identical' claims that were false, or that would delete seams PRD.md keeps on purpose (26 of 131 rejected)"
  - "1Password locked mid-run (failed to fill whole buffer); the first implementer stopped and the script aborted every later area"
root_cause: missing_workflow_step
resolution_type: workflow_improvement
related_components:
  - "PRD.md"
  - "AGENTS.md"
  - "lib/ui/core/widgets/"
  - "test/unit/architecture/"
tags: [redundant-code, dead-code, refactor-cleanup, adversarial-verification, behavior-preservation, prd-seams, bisectable-commits, 1password-commit-signing]
---

# Removing redundant code safely with independent behaviour and project-rules verification

## Context

The MVP and most of Phase 2 shipped as many feature slices written over several months. Along the way, each slice picked up its own copies of sheets, dialogs, mappers, COUNT queries and state wrappers. Some APIs existed only so tests could reach them, and some guards protected against states that cannot happen. PR #135 (merged to `main` as `d588748`) cleaned this up across the whole codebase in a multi-agent run. Its bar was no behaviour change, and every change had to make the code shorter.

| Measure | Value |
|---|---|
| Commits / files | 102 signed commits, 241 files |
| Whole diff | +3,443 / −6,274 (net −2,831) |
| Hand-written `lib/` (no `*.g.dart`, `*.freezed.dart`, `lib/l10n/`) | +1,619 / −3,233 (net −1,614) |
| `test/` | +1,503 / −2,313 |
| Tests | 2,233 → 2,241, all green. The new tests cover the three new shared widgets. |

Every commit shrank `lib/`. A final reviewer found no regressions. Of 131 deduplicated findings, 26 were **rejected**. The rejections teach as much as the deletions: in this repo, a lot of code that looks redundant is either a documented seam or depends on library behaviour that the library's own docs describe wrongly.

## Guidance

### 1. Bloat patterns that held up (105 confirmed findings)

| Pattern | Count | Ledgerly examples |
|---|---|---|
| **N copies of the same code**: mapper, SQL builder, sheet or dialog shell, snackbar, exception boilerplate | 31 | Five `drift.Currency → Currency` mappers became one `currencyFromRow`. Seven clear-then-show Undo snackbars became `showUndoSnackBar`, six Cancel/confirm `AlertDialog`s became `showConfirmDialog`, and three Dialog-vs-sheet presenters became `showAdaptiveSheet`, all in `lib/ui/core/widgets/`. Four chart-aggregate SQL builders became one private helper. Repository exceptions now `extend RepositoryException` instead of re-implementing `message`/`toString`. |
| **Single-field wrappers, single-use indirection** | 12 | `CategorySearchPendingDelete`, `ShoppingListPendingDelete` and `PendingSkipScheduled` each wrapped one value and became `Transaction?` / `int?`. The `RecurringFormError` hierarchy became a `String`. Single-use throw helpers were inlined. |
| **Impossible-state guards, read-back checks, trace logs** | 12 | "Disappeared after write" read-back throws. The `_ranFirstFrameCallback` re-entry guard. An unreachable Cash-account dedupe in the seed. `FirstRunSeedException` and its impossible null check. A duplicate `isClosed` check. `developer.log` calls that printed row ids from a financial-data stream. |
| **Re-implementing SDK, Drift or Flutter behaviour** | 9 | Hand-rolled `selectOnly + id.count()` became `table.count(where:)`. `_scale`/`pow10` loops became `math.pow`. A manual December rollover became `DateTime(y, m + 1)`. Substring date parsing became `DateTime.parse`. Removed `ThemeData` arguments that equal the defaults, and `_localeTag` became `Locale.toString()`. Dropped `keypadRevision`, which `KeypadState` equality already covered. |
| **Test-only APIs kept in `lib/`** | 8 | `ExchangeRateRepository.getRate` and its snapshot subscription. `getByL10nKey`. `TransactionRepository.watchForAccount`/`watchForCategory` and their DAO methods. `TransactionSearchRow`'s `deleteMode`/FX parameters (−95 lines). `SettingsData.defaultAccountId`. |
| **Single-value parameters, constants threaded through helpers** | 8 | `ChartsSection._frame`/`_inCard` received identical arguments at every call. Parameters were passed that equalled the widget's own fields. Freezed flags got defaults, so call sites stopped listing `false`/`null`. |
| **Never-constructed or never-read symbols** | 7 | `CategoriesState.loading/.error` and `SettingsState.loading`, plus their dead `switch` arms (the outer `AsyncValue` already covers them). `TimeBucketGranularity.hour`. `SelectedSlice.category.currencyCode`. Three unused ARB keys. |
| **Stored state that can be derived** | 6 | `CsvLoadResult.duplicateCount` (= `validRows.length − rowsToImport.length`). `_lastRequestedMode`, which always equalled `_formMode`. Draft archived flags, now read off the selected account and category. A keypad mirror. Seed `sortOrder` equal to the list index. |
| **Duplicate DAO/provider query pairs** | 4 | `CategoryDao.watchByType` folded into `watchAll(type:)`. `AccountTypeDao.watchActive` folded into `watchAll(includeArchived:)`. One `Selectable` now backs both `get…` and `watch…`. A provider re-filtered tokens the repository already excluded. |
| **Test-suite duplication** | 8 | 25 inline 2× `MediaQuery` copies became `textScaleBuilder`. Shared fixtures replaced copy-pasted fakes. Per-version migration checks became a loop. Duplicate test files were merged. |

Every finding had to clear the same bar: shorter and at least as clear, with identical behaviour. "Every commit shrinks `lib/`" is a checkable invariant. A change that only moves lines around fails it.

### 2. What looked redundant but had to stay (26 rejected, plus implementer skips)

- **PRD-documented seams with no caller in `lib/`.** Search `PRD.md` and `docs/` for the symbol or feature before calling it dead.
  - The Duplicate transaction flow has no UI entry point, but PRD.md lists "Quick repeat / duplicate existing transaction" and documents the `duplicateSourceId` extra. Deleting it removes a feature, which is a product decision. It went to #134, and the owner then removed it in a separate PR.
  - `CurrencyRepository.updateCustomName` and the AccountType archive/delete/rename methods back PRD rules for features not built yet.
  - `RecurringGenerationOutcome` backs the PRD's 12-period generation cap.
  - `json_serializable` is kept on purpose.
- **PRD's named state shape.** `HomeState.loading` and `PendingState.loading/.empty` are never constructed, but PRD.md names `HomeState.loading | .empty | .data | .error` as the canonical shape, so they stay. The same kind of variant *was* deleted from Categories and Settings, where no doc names it.
- **Recorded design decisions.**
  - CategoryType wire mappers stay explicit, so a new variant forces a schema review.
  - The search detail's trim/empty guard is in its spec.
  - Exhaustive `switch` over a sealed outcome must not become `is` chains ([controller-command-outcomes…](../architecture-patterns/controller-command-outcomes-and-snackbar-actions-outliving-widgets.md)).
- **Library behaviour that contradicts its own docs.** "`x == null ? Value.absent() : Value(x)` is just `Value(x)`" is false. In drift 2.35.3, `UpdateStatement.replace` leaves an absent default-less column out of `SET`, so the stored value is **kept**, while `Value(null)` writes `NULL`. The verifier read the pinned source, not the doc comment. See also [keypad-formula-replay-verified-persistence §6](../design-patterns/keypad-formula-replay-verified-persistence.md).
- **False premise about runtime state.** "Route Home's jump-to-today through the date picker's jump path" assumed today is never before the selected day. Home can show a *future* day: the form allows dates up to year 9999, and Home pins the saved day. The verifier disproved it with a counterexample ([home-calendar-day-navigation](../logic-errors/home-calendar-day-navigation-2026-04-29.md)).
- **Concurrent teardown.** "Hold `SettingsComposer`'s eight nullable subscriptions in one list" breaks because Riverpod's `runOnDispose` synchronously fires the broadcast controller's `onCancel: _stop`, so `_stop` runs twice, overlapping itself. The nullable fields tolerate that.
- **Provider lifetime.** Reusing `analysisCategoriesByIdProvider` from Home would change lifetime, because it is `keepAlive`, and would need extra `@Dependencies`.
- **Consolidation that adds lines or a public API for one call site.** Apply it to a scratch copy, run `dart format`, and count.
  - The router redirect helper saved 2 lines.
  - Removing the `CsvExportUseCase.getDateBounds` pass-through netted **+1** hand-written and +3 generated lines, so it was reverted.
  - A `destructive` flag on `showConfirmDialog` would serve one call site.
  - A shared form-error banner would add a public widget and was not a pure move.
- **A removal that breaks tests of unchanged code.** `if (results.isEmpty) return;` looked redundant because the real DAO guards too, but controller tests use a mocked DAO without that guard. Run the full suite.
- **Copies whose behaviour differs.** `manage_accounts_sheet.dart` keeps its own non-dismissible copy of the 600dp switch instead of using `showAdaptiveSheet`.
- **User UX decisions** (auto memory [claude]). Search Level 2 rows stay a dedicated `TransactionSearchRow`, never folded into Home's `TransactionTile`. Mockup typography (mixed sizes, symbol/number gaps) is reproduced exactly; it is not duplication.

### 3. The process that made it safe

1. **Find (read-only, in parallel).** Nine per-area finders, plus a cross-feature duplication finder, a systematic dead-symbol scan and a test-suite finder. Each finding carries file:line evidence, the grep output, the proposed change, estimated lines saved, and a risk level.
2. **Dedup.** One agent merged overlapping findings (148 → 131).
3. **Verify through two independent lenses; both must pass.**
   - Lens A, behaviour preservation: re-run the searches, construct a counterexample, and read the pinned library source.
   - Lens B, project rules and net value: search PRD, `docs/architecture/`, specs and `docs/solutions/`, and count real line savings. The default when unsure is "refuted".
4. **Implement serially, one agent per area.**
   - Re-check each finding against the *current* tree, since earlier commits may already have done it or changed it.
   - Make one commit per concern.
   - Per commit, run `build_runner` (riverpod_generator hashes provider source), `dart format`, `dart analyze --fatal-infos` and the full `flutter test`.
   - If a change turns out not to shorten the code, revert it and record the skip.
5. **Final review.** Check codegen staleness, formatting, analyze, the layer-boundary test and the full suite. Then hunt for regressions over the whole diff, giving most attention to places where one helper replaced several copies (rounding, locale, null handling, day boundaries, sort order).

**Check these dynamic references before calling anything dead.** grep cannot see them:

- Generated Riverpod names (`fooProvider` from `foo`, the `FooController` class) and `@Dependencies([...])` lists.
- Drift generated accessors (`db.categoryDao`, table getters, `readsFrom:` sets, companion fields).
- `l10n_key` strings stored in seed data and the DB (`category.investment`): a key can be unused in Dart and still be live data.
- Icon and colour registry keys persisted in DB rows.
- Route path strings and `extra` payload keys (`initialDate`).
- ARB keys: generated getters, all locale files, and `arb_audit_test`.
- PRD, docs and spec references: a symbol named there is a seam.

### 4. When commit signing locks mid-run: queue tree snapshots, replay them signed

Commits here are SSH-signed through 1Password's `op-ssh-sign`, which locks during long runs (`error: 1Password: failed to fill whole buffer`). In the first run, the no-bypass rule was not passed to subagents, which don't see auto memory, and the stop condition was "stop on signing failure". The run aborted all 11 remaining areas.

Brief every committing subagent with this procedure instead:

- **Queue (implementer, while locked):**
  1. Stage exactly that commit's files.
  2. Run `T=$(git write-tree)`.
  3. Write the message to a file.
  4. Append `NN $T msgfile` to `queue.txt`.
  5. Keep the changes staged; the next commit stages on top of them, because the snapshots are cumulative.
  6. If the queue is non-empty, later implementers queue directly instead of trying `git commit`.
- **Replay (orchestrator, after unlock):**
  1. Check that `git write-tree` equals the last queued tree.
  2. Replay each entry in order:

     ```sh
     parent=$(git rev-parse HEAD)
     while read num tree msg; do
       c=$(git commit-tree -S "$tree" -p "$parent" -F "$msg") || break
       parent=$c
     done < queue.txt
     git reset --soft "$parent"   # moves HEAD only; a running agent's staged work stays intact
     ```

  3. Trim the replayed lines from the queue.
- **Verify** with `git cat-file -p <sha> | grep '^gpgsig'`. Locally `%G?` shows `N` only because `gpg.ssh.allowedSignersFile` is not configured.
- **Never** use `--no-gpg-sign` or `-c commit.gpgsign=false`, and never change signing config.

55 commits were replayed this way across two lock episodes.

## Why This Matters

- Each of the 31 "N copies" findings was a place where a fix had to be made N times. The clear-before-show rule for Undo snackbars now lives in one function instead of seven.
- Test-only APIs widen the surface that reviewers and agents must keep consistent, and they make tests check a path production never takes.
- Impossible-state guards suggest failure modes that don't exist. The removed trace logs went against the "don't log financial data" rule.
- **The ~20% rejection rate is the warning.** Findings with correct grep evidence were often still wrong. Without the second lens and a source-level check, the run would have deleted a PRD feature, silently changed nullable-column writes, and added a teardown race.
- Running the full checks on every commit kept the branch bisectable and caught stale `.g.dart` hashes on provider edits.

## When to Apply

- Before any sweeping cleanup, dead-code pass or "simplify" task across several slices, especially one run by agents.
- When reviewing a claim of the form "nothing calls X", "X is just Y" or "these N blocks are identical". Run the dynamic-reference checklist and the PRD/docs search first.
- When a change touches Drift companions, Riverpod lifetimes (`keepAlive`, `@Dependencies`) or stream teardown. Read the pinned library source.
- When a consolidation would add a shared widget or public API. Count the formatted lines and the call sites; it needs at least two call sites and a net reduction. Update PRD, `docs/architecture/` and AGENTS.md in the same change.
- Whenever agents commit in a repo with 1Password-backed signing.

## Examples

**Re-implemented Drift → `table.count()`** (`shopping_list_dao.dart`)

```dart
// before
Future<int> countByAccount(int accountId) async {
  final countExp = shoppingListItems.id.count();
  final row = await (selectOnly(shoppingListItems)
        ..addColumns([countExp])
        ..where(shoppingListItems.accountId.equals(accountId)))
      .getSingle();
  return row.read(countExp) ?? 0;
}
// after
Future<int> countByAccount(int accountId) => shoppingListItems
    .count(where: (t) => t.accountId.equals(accountId))
    .getSingle();
```

**Re-implemented SDK → `DateTime` normalisation** (`recurring_rules_repository.dart`)

```dart
// before
final nextMonth = current.month == 12 ? 1 : current.month + 1;
final nextYear = current.month == 12 ? current.year + 1 : current.year;
return _clampDay(nextYear, nextMonth, rule.dayOfMonth!);
// after: DateTime treats month 13 as January of the next year
return _clampDay(current.year, current.month + 1, rule.dayOfMonth!);
```

**Exception boilerplate → existing base class**

```dart
// before
class RecurringRulesRepositoryException implements Exception {
  const RecurringRulesRepositoryException(this.message);
  final String message;
  @override
  String toString() => 'RecurringRulesRepositoryException: $message';
}
// after
class RecurringRulesRepositoryException extends RepositoryException {
  const RecurringRulesRepositoryException(super.message);
}
// toString() now prints the runtime subclass name (e.g. ArchivedReferenceException: …);
// debug text only, no user-visible change.
```

**Impossible read-back guard** (`shopping_list_repository.dart`)

```dart
// before
final inserted = await _shoppingListDao.findById(id);
if (inserted == null) {
  throw const ShoppingListRepositoryException(
      'Inserted shopping-list item disappeared before read-back');
}
return _toDomain(inserted);
// after
return _toDomain((await _shoppingListDao.findById(id))!);
```

**Seven call sites → one helper** (`recurring_rules_screen.dart`, now calling `lib/ui/core/widgets/undo_snack_bar.dart`)

```dart
// before (one of seven near-identical copies)
ScaffoldMessenger.of(ctx)
  ..clearSnackBars()
  ..showSnackBar(SnackBar(
    content: Text(l10n.recurringDeletedSnack),
    action: SnackBarAction(
        label: l10n.commonUndo, onPressed: () => controller.undoDelete(rule.id)),
    duration: kUndoWindow));
// after
ScaffoldMessenger.of(ctx).showUndoSnackBar(
  message: l10n.recurringDeletedSnack,
  undoLabel: l10n.commonUndo,
  onUndo: () => controller.undoDelete(rule.id),
);
```

**The trap that must stay** (drift 2.35.3, `UpdateStatement.replace`)

```dart
// Defaults apply only to absent fields; an absent default-less column is
// left out of SET, so the stored value is KEPT.
if (column.defaultValue != null && !_updatedFields.containsKey(column.$name)) {
  _updatedFields[column.$name] = column.defaultValue!;
}
// => Value.absent() keeps the old value; Value(null) writes NULL.
```

## Related

- PR #135 (this cleanup). Issue #134: the Duplicate transaction flow, deferred as a product decision and later removed once the owner decided against it.
- [flutter-lib-relayout-with-transitional-layer-boundary-rules](../architecture-patterns/flutter-lib-relayout-with-transitional-layer-boundary-rules.md): an earlier no-behaviour-change refactor with the same per-commit gate.
- [flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes](../performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md): the same audit-then-fix shape, and the source of the `keepAlive` rule.
- [controller-command-outcomes-and-snackbar-actions-outliving-widgets](../architecture-patterns/controller-command-outcomes-and-snackbar-actions-outliving-widgets.md): the clear-before-show snackbar rule that `showUndoSnackBar` now holds, and the exhaustive-switch rule.
- [keypad-formula-replay-verified-persistence](../design-patterns/keypad-formula-replay-verified-persistence.md): the earlier record of the `Value.absent()` vs `Value(null)` trap, and "prove equivalence before removing duplicated state".
- [home-calendar-day-navigation-2026-04-29](../logic-errors/home-calendar-day-navigation-2026-04-29.md): the jump-to-today path a rejected finding tried to merge.
