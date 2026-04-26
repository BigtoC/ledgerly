---
title: "feat: M6 Integration & Polish"
type: feat
status: active
date: 2026-04-26
---

# feat: M6 Integration & Polish

## Overview

M6 is the final milestone before a release candidate. All six M5 feature slices (Splash, Categories, Accounts, Settings, Transactions, Home) and the Wave 4 integration pass are merged. M6 delivers the remaining integration test suite covering every PRD flow, an accessibility hardening pass, native splash finalization, and a clean release-build sweep. No new product features ship in M6.

## Problem Frame

M5 delivered six isolated slices with controller tests (mocked providers) and widget tests. The integration layer (`test/integration/`) has only three scenarios: first-run bootstrap → splash → Home, splash-disabled launch, and live splash-toggle. The PRD's full integration-flow set — first-launch add-transaction, subsequent splash-enabled launch, duplicate, multi-currency summary, archive, and edit + delete — is not yet covered. The accessibility audit (Semantics, 2× text scale, 48dp targets) has not been done. Native splash runs on a placeholder gradient. These gaps must close before a signed release build is meaningful.

## Requirements Trace

- **R1.** Integration tests cover every PRD flow: first-launch + add-transaction + DB verification, subsequent splash-enabled launch, duplicate flow, multi-currency grouped summary, archive flow (hidden from pickers / visible in management), edit + delete.
- **R2.** Accessibility: `Semantics` labels on every icon-only button (FAB, day-nav chevrons, swipe-delete action, duplicate/delete overflow items); 2× text scale passes on Home, Add/Edit Transaction, and Category picker; 48dp minimum tap targets audited.
- **R3.** `flutter analyze` clean across the full tree; pre-merge double-`double` grep (`double.*(amount|balance|rate)` → zero hits outside `money_formatter`).
- **R4.** Migration harness runs the v1 snapshot upgrade path on both empty and seeded DB. Already green from M3; M6 confirms no regression.
- **R5.** `flutter_native_splash` regenerated for Android (API < 12 + API 12+) and iOS with the final sun-background asset.
- **R6.** A11y audit doc committed to `docs/`.
- **R7.** Release build produced and smoke-tested on the device matrix: Android phone + Android tablet + iOS phone + iOS tablet.

## Scope Boundaries

- No new product features.
- Phase 2 items (charts, wallet sync, recurring transactions, pending-transaction screen) are out of scope.
- Device matrix and signed-build testing are human-run operator steps, not automatable tests.
- Store listing copy and screenshot assets are operator work, not code work.

## Context & Research

### Relevant Code and Patterns

- **Integration test harness**: `test/support/test_app.dart` — `newTestAppDatabase()`, `runTestSeed()`, `makeTestContainer()`, `buildTestApp()`. All integration tests follow this pattern. `tester.runAsync` is required for Drift real-timer calls; interaction-triggered writes are fire-and-forget via `tester.tap` + `pump`.
- **Existing integration tests**: `test/integration/bootstrap_to_home_test.dart` (3 tests). First-run splash flow stops at `HomeScreen` — does not tap FAB or add a transaction.
- **Widget test patterns**: `test/widget/features/home/home_screen_test.dart` (673 lines) and `test/widget/features/transactions/transaction_form_screen_test.dart` (439 lines) use mocked `ProviderContainer` overrides. Integration tests bypass mocking entirely.
- **Repository layer**: all aggregate methods from Wave 3 (`watchDailyNetByCurrency`, `watchDailyTotalsByType`, `watchMonthNetByCurrency`) exist and are tested in `test/unit/repositories/transaction_repository_test.dart`.
- **ARB audit**: `test/unit/l10n/arb_audit_test.dart` must stay green after any ARB additions.
- **Semantics**: `features/splash/widgets/splash_day_count.dart` clamps `textScaler` at 1.5× — the established pattern for fixed-height regions.
- **Sun splash asset**: `assets/splash/sun-splash.png` now exists but `flutter_native_splash` has not been rerun since M0. The `pubspec.yaml` `flutter_native_splash:` section still uses placeholder light/dark `#FFFFFF`/`#121212` colors and does not yet point at the shipped asset. The runtime Flutter splash widget still references the older placeholder filename.
- **About screen**: `lib/features/settings/about_screen.dart` exists on the current branch (`feature/display-version-number`); a version-display feature is in progress. M6 plan acknowledges but does not block on it.

### Institutional Learnings

- **`tester.runAsync` is required for Drift calls in integration tests** — direct repo writes must run inside `tester.runAsync` because Drift uses real timers that `FakeAsync` does not advance. (`test-failures/`, `logic-errors/m4-app-shell-first-frame-hydration-2026-04-23.md`)
- **Reactive feature flow ownership**: Home pins the selected day by calling `controller.pinDay(savedTx.date)` after receiving the `Transaction` returned from `context.push`. Integration tests must await the push result and pump to let streams settle. (`docs/solutions/best-practices/reactive-feature-flow-ownership-2026-04-25.md`)
- **Home delete-undo timer**: `HomeController` is `@Riverpod(keepAlive: true)`; the 4-second undo timer survives navigation. Integration tests for delete must advance the timer with `tester.pump(const Duration(seconds: 5))` to commit the delete, or call `pumpAndSettle` and verify the undo window snackbar. (`docs/solutions/logic-errors/home-delete-undo-stream-coordination-2026-04-26.md`)
- **Account–transaction currency invariant**: `TransactionRepository.save` throws `TransactionAccountCurrencyMismatchException` when `tx.currency != account.currency`. Integration tests that build transactions manually must copy `account.currency`. (`docs/solutions/logic-errors/account-transaction-currency-invariant-2026-04-25.md`)

## Key Technical Decisions

- **Integration tests use the real in-memory Drift DB, no mocking**: follows the established `bootstrap_to_home_test.dart` pattern. This is the only way to verify the full data pipeline: form save → repository → Drift → stream re-emit → Home re-render.
- **One test file per flow group**: keeps individual files under ~200 lines and failure output readable. Files: `first_launch_flow_test.dart`, `duplicate_flow_test.dart`, `multi_currency_flow_test.dart`, `archive_flow_test.dart`, `edit_delete_flow_test.dart`.
- **Accessibility widget tests, not golden tests**: golden tests are brittle across devices; widget tests using `find.bySemanticsLabel()` and `tester.getSemantics()` are portable. The audit doc captures pass/fail per screen rather than a golden image.
- **2× text scale via `MediaQuery` override in widget tests**: wrap the pumped widget with `MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(2.0)), ...)`. Integration tests do not carry 2× scale — they verify functional flows at default scale.
- **Sun asset regen is a checked-in local generation step**: `dart run flutter_native_splash:create` must run after the asset lands, and the regenerated Android/iOS files ship in the same PR. Current CI does not run splash regeneration, so the diff itself is the source of truth.
- **No new ARB keys in M6**: all localization is stable from M5. If any key is found missing during integration test authoring, add it following the existing `app_en + app_zh_TW + app_zh_CN + arb_audit_test` pattern (four-file update).

## Open Questions

### Resolved During Planning

- **Do integration tests need the webview/About screen?** No — `about_screen.dart` uses `webview_flutter` which is not under test in MVP. Integration tests skip Settings → About navigation.
- **Can duplicate-flow integration test reuse the existing `runTestSeed` helper?** Yes — seed already creates the `Cash` account and seeded categories, providing a complete fixture for add/duplicate.
- **Is the migration harness already green?** The v1 snapshot exists in `drift_schemas/drift_schema_v1.json` and `migration_test.dart` is green from M3. M6 just re-confirms no regression from M5 work.

### Deferred to Implementation

- **Exact widget finders for integration tests**: finders are discovered during implementation by running the tests against the live screen tree. Document surprising finders in test comments.
- **Undo-window pump duration in delete integration test**: 4 seconds is the controller constant; verify the exact `pump(Duration(...))` needed to advance FakeAsync past the timer in a live-DB context.
- **Whether `flutter_native_splash` config needs a separate YAML file**: currently inline in `pubspec.yaml`. Follow the existing structure; do not split unless `pub get` complains.

## High-Level Technical Design

> *This illustrates the intended approach and is directional guidance for review, not implementation specification. The implementing agent should treat it as context, not code to reproduce.*

```
test/integration/
  bootstrap_to_home_test.dart     ← already exists (3 tests) — keep unchanged
  first_launch_flow_test.dart     ← NEW: extends the first-run test to reach FAB → add tx → DB verify
  duplicate_flow_test.dart        ← NEW: add tx → duplicate → edit → save → 2 rows in DB
  multi_currency_flow_test.dart   ← NEW: add 2nd account (JPY) → add tx each → verify Home summary groups
  archive_flow_test.dart          ← NEW: archive used category/account → picker/management parity
  edit_delete_flow_test.dart      ← NEW: edit (verify updated row), delete + undo window

test/support/
  test_app.dart                   ← already exists — may add tx/account shortcut helpers

test/widget/features/
  home/                           ← add 2× text scale test
  transactions/                   ← add 2× text scale + keyboard-cover test
  categories/                     ← add 2× text scale test

docs/
  a11y-audit-m6.md                ← NEW: per-screen a11y checklist (Semantics, tap targets, 2× scale)
```

Integration test anatomy (repeats the established pattern):

```
1. newTestAppDatabase()           → in-memory Drift DB
2. runTestSeed(db)                → currencies + categories + account types + Cash account
   (inside tester.runAsync)
3. makeTestContainer(db: db)      → ProviderContainer with DB override
4. buildTestApp(container: ...)   → full App widget
5. tester.pumpWidget + pump       → first frame + stream settle
6. interact (tester.tap, etc.)    → trigger user actions
7. tester.pumpAndSettle           → streams + animations settle
8. assertions (find.*, db query)  → verify widget state + DB row
```

## Implementation Units

---

- [ ] **Unit 1: Integration test helpers extension**

**Goal:** Add reusable shortcut helpers to `test/support/test_app.dart` so individual flow tests remain concise and don't repeat boilerplate for transaction insertion, currency resolution, and account creation.

**Requirements:** R1 (enables R1 flow tests to be written cleanly)

**Dependencies:** None — additive to existing harness

**Files:**
- Modify: `test/support/test_app.dart`

**Approach:**
- Add a `insertTestTransaction(AppDatabase db, {required int accountId, required int categoryId, required int amountMinorUnits, ...})` helper that calls `DriftTransactionRepository(db).save(...)` directly, returning the persisted `Transaction`. Callers wrap in `tester.runAsync`.
- Add a `createTestAccount(AppDatabase db, {required String name, required String currency, ...})` helper wrapping `DriftAccountRepository.save(...)`.
- Keep helpers minimal: only parameters actually used across integration tests. No defaulting of currency without an explicit parameter — the currency invariant is too important.
- Do not add Mocktail or provider-override helpers here; this file is for real-DB test support only.

**Patterns to follow:**
- `test/support/test_app.dart` existing `runTestSeed` and `newTestAppDatabase` style
- `test/unit/repositories/transaction_repository_test.dart` for how `DriftTransactionRepository` is constructed in test context

**Test scenarios:**
- Test expectation: none — these are test helpers, not feature code

**Verification:**
- Subsequent integration tests build without repeating `DriftTransactionRepository(db).save(...)` boilerplate inline

---

- [ ] **Unit 2: Integration test — complete first-launch add-transaction flow**

**Goal:** Extend the first-run scenario to cover the full PRD first-launch flow: splash → Home → FAB → form → save → DB row verification + Home day pin.

**Requirements:** R1

**Dependencies:** Unit 1

**Files:**
- Create: `test/integration/first_launch_flow_test.dart`

**Approach:**
- Start from the same seeded empty DB as `bootstrap_to_home_test.dart` test 1.
- After reaching `HomeScreen`, tap the FAB (`find.bySemanticsLabel('Add transaction')` or the button finder).
- In the Add form: enter an amount via the keypad (tap `1`, `0`, `0`), select the first expense category via `showCategoryPicker` (find the picker's first tile), confirm, tap Save.
- After `context.pop(savedTx)`, verify:
  - Home is visible.
  - The selected day in the controller matches `savedTx.date` (today).
  - One transaction row is visible in the sliver list.
  - The DB has exactly one transaction via `db.select(db.transactions).get()`.
- The existing `bootstrap_to_home_test.dart` first-run test is kept intact and unchanged.

**Patterns to follow:**
- `test/integration/bootstrap_to_home_test.dart` test 1 structure (tester.runAsync, pump cadence)
- PRD → Primary User Flow

**Test scenarios:**
- Happy path: first launch → splash date set → Enter → Home empty → FAB → amount + category → Save → 1 row in DB, Home shows transaction tile for today
- Edge: no category seeded (seed failed) → Save button disabled, no DB write
- Integration: `savedTx.date == DateTime.now().toLocal()` (today), Home's selected day matches

**Verification:**
- `flutter test test/integration/first_launch_flow_test.dart` passes
- `db.select(db.transactions).get()` returns exactly 1 row after save

---

- [ ] **Unit 3: Integration test — subsequent splash-enabled launch**

**Goal:** Verify that a subsequent launch with `splash_enabled = true` and a configured `splash_start_date` shows the day counter (not the date picker) and Enter → Home works.

**Requirements:** R1

**Dependencies:** Unit 1

**Files:**
- Create: `test/integration/first_launch_flow_test.dart` (second `group` in the same file as Unit 2, or a separate file — place in same file for cohesion)

**Approach:**
- Seed the DB, then write `splash_enabled = true` and `splash_start_date = DateTime.now().subtract(const Duration(days: 30)).toIso8601String()` via `DriftUserPreferencesRepository` inside `tester.runAsync`.
- Boot through the normal app shell with no `splashGateSnapshotProvider` override so the test exercises bootstrap preference reads, router redirect wiring, and the splash screen's configured-date path end to end.
- Assert the day counter text is visible (e.g. `find.text('30')` or a broader `find.byType(SplashScreen)`).
- Tap Enter → assert `HomeScreen`.

**Patterns to follow:**
- `test/support/test_app.dart` `buildBootstrappedTestApp(...)` for real bootstrap-order coverage without provider shortcuts
- PRD → Launch Flow (subsequent launch with splash enabled)

**Test scenarios:**
- Happy path: splash_enabled + start_date set → day counter visible → Enter → HomeScreen
- Integration: splash screen does not redirect to date picker when start_date is already set

**Verification:**
- `flutter test` passes; `SplashScreen` renders with day counter, not the date-picker prompt

---

- [ ] **Unit 4: Integration test — duplicate flow**

**Goal:** Test the full duplicate flow: add a transaction, then duplicate it from Home's overflow menu, edit the amount, save, and verify two distinct rows in the DB with the second pinned to today.

**Requirements:** R1

**Dependencies:** Unit 1

**Files:**
- Create: `test/integration/duplicate_flow_test.dart`

**Approach:**
- Use `insertTestTransaction` helper from Unit 1 to create the source transaction (e.g. `amountMinorUnits: 500`, USD, expense category).
- Navigate to Home. Verify the source row appears.
- Long-press or tap the overflow menu on the transaction tile to trigger Duplicate (`find.text('Duplicate')` or `find.byIcon(...)`).
- In the Add form (opened with `duplicateSourceId`): verify the amount is pre-filled (500 minor units rendered as `5.00`). Enter a new amount (`2`, `0`, `0` → 200), tap Save.
- After pop: verify Home shows the duplicate tile. Query `db.select(db.transactions).get()` → 2 rows, second row `amountMinorUnits == 200`.
- PRD quick-repeat flow states "date defaults to today" in duplicate — assert `savedTx.date.day == DateTime.now().day`.

**Patterns to follow:**
- Wave 0 §2.3 duplicate handoff: Home pushes `/home/add` with `{'duplicateSourceId': id}` as `GoRouterState.extra`
- PRD → Quick Repeat Flow

**Test scenarios:**
- Happy path: duplicate → prefill visible → edit amount → Save → 2 rows in DB
- Edge: duplicate source's date is overridden to today (not source tx date)
- Edge: category from source is preserved in duplicate (same category ID in the DB)
- Integration: `context.pop(savedTx)` from form → Home receives `savedTx` and pins day to `savedTx.date`

**Verification:**
- 2 rows in DB; second row has edited amount and today's date
- Home day pinned to today after duplicate save

---

- [ ] **Unit 5: Integration test — multi-currency seeded-state rendering**

**Goal:** Verify Home's summary strip groups totals by currency when the app boots with mixed-currency data already present.

**Requirements:** R1

**Dependencies:** Unit 1

**Files:**
- Create: `test/integration/multi_currency_flow_test.dart`

**Approach:**
- Seed the DB (USD Cash account already exists from seed).
- Create a second account (JPY, Investment type) via `createTestAccount(db, name: 'Yen Account', currency: 'JPY')`.
- Insert one USD expense (1000 minor units = $10.00) and one JPY expense (500 minor units = ¥500) via helpers.
- Navigate to Home (skip splash via `splashGateSnapshotProvider` override).
- Assert the summary strip renders two currency groups via the rendered formatted amounts/symbols (for example `$1.00` / `-$1.00` and `¥500` / `-¥500`) rather than raw `USD` / `JPY` code headers.
- Do not add repository-stream assertions here; repository aggregation behavior remains covered by `test/unit/repositories/transaction_repository_test.dart`.

**Patterns to follow:**
- `test/unit/repositories/transaction_repository_test.dart` multi-currency group test structure
- PRD → MVP Currency Policy: no auto-conversion in MVP, grouped by original currency

**Test scenarios:**
- Happy path: seeded USD + JPY expenses → Home summary strip has two currency groups
- Edge: all transactions in same currency → strip has one currency group only
- Integration: mixed-currency seeded state rehydrates through the real app shell and renders grouped summary output correctly

**Verification:**
- Home summary strip renders two distinct currency groups
- `flutter test test/integration/multi_currency_flow_test.dart` passes

---

- [ ] **Unit 6: Integration test — archived-state rendering**

**Goal:** Verify that already-archived categories and accounts are hidden from pickers while remaining visible in management screens and historical transaction records.

**Requirements:** R1

**Dependencies:** Unit 1

**Files:**
- Create: `test/integration/archive_flow_test.dart`

**Approach:**
- Seed DB. Insert one transaction referencing the seeded `Food` expense category and the seeded `Cash` account.
- Archive the `Food` category via `DriftCategoryRepository(db).archive(foodId)` inside `tester.runAsync`.
- Archive the `Cash` account via `DriftAccountRepository(db).archive(cashAccountId)`.
- Navigate to the category picker (open Add Transaction → tap category chip). Assert `Food` is not visible in the picker grid.
- Navigate to Settings → Manage Categories. Assert `Food` appears in the archived section (is visible in management).
- Navigate to Home. Assert the historical transaction tile still renders the `Food` category name/icon (archived metadata still shows in history).
- Repeat the account-picker check: open Add Transaction → tap account selector → assert `Cash` is not in the account picker list.

**Patterns to follow:**
- PRD → Management Rules: "Archived accounts and categories are hidden from pickers but remain visible in management screens and historical records"
- `test/unit/repositories/category_repository_test.dart` archive-instead-of-delete tests

**Test scenarios:**
- Happy path — archived category state: picker hides `Food`, Categories screen shows it in archived section, Home history tile still renders it
- Happy path — archived account state: account picker hides `Cash`, Accounts screen shows it in archived section
- Edge: attempting to hard-delete an archived category with transactions — repository throws; not tested here (repository-level test already covers this)

**Verification:**
- Picker does not find the archived category/account
- Management screen finds the archived row
- Historical Home tile renders archived category metadata

---

- [ ] **Unit 7: Integration test — edit and delete flows**

**Goal:** Verify that editing a transaction updates the DB row correctly, and that deleting commits after the undo window (and undo within the window restores the row).

**Requirements:** R1

**Dependencies:** Unit 1

**Files:**
- Create: `test/integration/edit_delete_flow_test.dart`

**Approach:**

*Edit flow:*
- Insert a transaction (amount 500 minor units). Navigate to Home. Tap the transaction tile (or overflow → Edit). In the form, change the amount to 999, save. After `context.pop(savedTx)`, query DB: assert `amountMinorUnits == 999` and `createdAt` is unchanged, `updatedAt > createdAt`.

*Delete + commit:*
- Insert a transaction. Navigate to Home. Swipe-delete the row (via `flutter_slidable`'s action). Assert undo snackbar appears. Do not tap Undo. Advance time with `tester.pump(const Duration(seconds: 5))`. Assert DB has 0 transactions and tile is gone from the sliver list.

*Delete + undo:*
- Insert a transaction. Swipe-delete. Assert snackbar. Tap "Undo" in the snackbar before timer expires. Assert DB still has 1 transaction. Assert tile re-appears in the sliver list.

**Patterns to follow:**
- `test/unit/controllers/home_controller_test.dart` delete-undo timer tests (adapt to integration context)
- PRD → Screen States → Home: "undo snackbar after delete"
- PRD → Delete (Edit mode only) save flow semantics

**Test scenarios:**
- Edit happy path: form hydrates existing tx, amount edit, save → DB row updated, `createdAt` preserved, `updatedAt` refreshed, Home day pinned to `savedTx.date`
- Delete + commit: tile gone from UI immediately (visual delete), DB row absent after 5-second pump
- Delete + undo: tile reappears after Undo tap, DB row untouched
- Edge: rapid double swipe-delete — second swipe commits first delete and starts undo for second (per Wave 3 plan §8)

**Verification:**
- `flutter test test/integration/edit_delete_flow_test.dart` passes
- DB row count matches expected after each scenario

---

- [ ] **Unit 8: Accessibility hardening**

**Goal:** Add `Semantics` labels on all icon-only interactive buttons (FAB, day-nav chevrons, swipe actions, overflow items); write 2× text scale widget tests for Home, Add/Edit Transaction, and Category picker; document tap-target compliance.

**Requirements:** R2

**Dependencies:** None (independent of integration tests)

**Files:**
- Verify or modify only if needed: `lib/features/home/home_screen.dart` (FAB semantics)
- Verify or modify only if needed: `lib/features/home/widgets/day_navigation_header.dart` (prev/next chevron semantics)
- Modify: `lib/features/home/widgets/transaction_tile.dart` (overflow and swipe-action semantics)
- Modify: `lib/features/transactions/widgets/calculator_keypad.dart` (backspace/clear semantics)
- Verify or extend: `test/widget/features/home/home_screen_test.dart` (2× text scale coverage)
- Modify: `test/widget/features/transactions/transaction_form_screen_test.dart` (add 2× scale + keyboard-cover test)
- Verify or extend: `test/widget/features/categories/categories_screen_test.dart` (management-screen 2× scale coverage)
- Verify or extend: `test/widget/features/categories/category_picker_test.dart` (picker 2× scale coverage)
- Create: `docs/a11y-audit-m6.md`

**Approach:**
- Confirm the existing FAB and day-nav tooltip/semantics coverage is sufficient before adding wrappers; only change these widgets if the current semantics tree fails the new tests.
- Swipe actions (delete via `flutter_slidable`): use `SlidableAction.autoClose` with `label` set to the ARB key. Verify `find.bySemanticsLabel(deleteLabel)` finds it.
- Overflow menu items (Edit, Duplicate, Delete on `TransactionTile`): these are `PopupMenuEntry` with text labels — already accessible. Verify via test.
- Calculator keypad backspace and clear buttons: use the existing localized keypad labels (`txKeypadBackspace`, `txKeypadClear`) for semantics/tooltip coverage rather than adding hard-coded English strings.
- **2× text scale widget tests**: follow the `splash_long_text_2x.png` golden's approach — wrap the widget under test with `MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(2.0)), ...)`. Assert no overflow errors (`tester.takeException()` is null) and key text is still visible (`find.text(...)` finds headings).
- **48dp tap target audit**: check `ConstrainedBox`/`SizedBox` or `InkWell`/`IconButton` sizing. `IconButton` defaults to 48dp — verify no overrides shrink it. Document findings in `docs/a11y-audit-m6.md`.
- `docs/a11y-audit-m6.md` is a markdown checklist: one row per screen × concern (Semantics, 2× scale, 48dp target) marked pass/fail with notes.

**Patterns to follow:**
- `lib/features/splash/widgets/splash_day_count.dart` 1.5× `textScaler` clamp for fixed-height widgets
- PRD → Accessibility: "Semantics labels on icon-only buttons (FAB, duplicate, delete, undo snackbar action)"
- PRD → Accessibility: "Minimum 48×48dp tap targets for FAB, swipe actions, category tiles, keypad keys"

**Test scenarios:**
- Semantics — FAB: `find.bySemanticsLabel(S.of(context).homeFabLabel)` returns one widget
- Semantics — prev chevron: `find.bySemanticsLabel(S.of(context).homeDayNavPrevLabel)` returns one widget
- 2× scale — Home: pump at 2× scale, `tester.takeException()` is null, summary strip text is visible
- 2× scale — Add/Edit form: pump at 2× scale, keypad renders without overflow
- 2× scale — Category picker: picker grid renders without overflow at 2×
- Keyboard cover — Add/Edit: `tester.showKeyboard(memoField)` then assert keypad vertical position is unchanged (existing test may already cover this; confirm and mark as covered)

**Verification:**
- `flutter test test/widget/features/home/ test/widget/features/transactions/ test/widget/features/categories/` passes including new 2× tests
- `docs/a11y-audit-m6.md` committed with all items marked

---

- [ ] **Unit 9: Native splash finalization**

**Goal:** Place the final sun-background asset and regenerate `flutter_native_splash` for all platforms so the native splash frame matches the app's visual design.

**Requirements:** R5

**Dependencies:** None (asset work, independent of tests)

**Files:**
- Modify or replace: `assets/splash/sun-splash.png` (final asset)
- Modify: `pubspec.yaml` `flutter_native_splash:` section — add `background_image` for supported platforms and Android 12-specific fallback `color` + `image` settings
- Regenerated by tooling (not hand-edited): `android/`, `ios/` platform splash files

**Approach:**
- Review `assets/splash/README.md` spec for required dimensions and format: 1:1 aspect ratio, 288×288dp native design, PNG.
- Update `pubspec.yaml` `flutter_native_splash:` to use platform-specific `background_image_*` keys for iOS and pre-Android-12 native backgrounds. Because Android 12+ does not support a background image, keep `android_12.color` / `color_dark` as solid fallback colors there and retain the default launcher icon rather than forcing the full photo into the platform's circular crop.
- Update the runtime Flutter splash widget to load `assets/splash/sun-splash.png` so the native frame and Flutter splash reference the same shipped asset.
- Run `dart run flutter_native_splash:create` as a required checked-in local generation step.
- Verify the native splash appears correctly on an Android API 29 device, an Android API 33 device (tests the `android_12:` stanza), and an iOS simulator.
- Commit the regenerated platform files alongside the asset and `pubspec.yaml` change.

**Patterns to follow:**
- `pubspec.yaml` existing `flutter_native_splash:` stanza
- `assets/splash/README.md` M6 follow-up spec

**Test scenarios:**
- Test expectation: none — this is asset + platform codegen work, not behavioral code

**Verification:**
- `dart run flutter_native_splash:create` exits 0
- Native splash is visible on device cold start before Flutter frame renders
- `flutter analyze` clean after regen (generated files must not produce new lint warnings)

---

- [ ] **Unit 10: Release prep sweep**

**Goal:** Confirm `flutter analyze` is clean, the migration harness is green, the a11y audit doc is complete, and a release build is produced and smoke-tested on the device matrix.

**Requirements:** R3, R4, R6, R7

**Dependencies:** Units 1–9 all merged

**Files:**
- Verify: `test/unit/repositories/migration_test.dart` — no regressions
- Verify: `test/unit/l10n/arb_audit_test.dart` — no missing keys
- Confirm: `docs/a11y-audit-m6.md` — fully populated
- Operator step: signed APK/IPA build + device matrix smoke

**Approach:**
- Run `flutter analyze` across the full tree. Resolve any warnings introduced by M5 or M6 work. Common sources: unused imports in generated files (acceptable if `// ignore:` is the established pattern), deprecated API warnings.
- Run `grep -r 'double.*\(amount\|balance\|rate\|price\)' lib/` and confirm zero hits outside `core/utils/money_formatter.dart`.
- Run `flutter test` (all unit + widget + integration). All must pass.
- Device matrix (operator-run): cold launch on Android phone + Android tablet + iOS phone + iOS tablet. Manual smoke checklist from Wave 4 plan §3.5 as the baseline.
- Version display in About screen: if the `feature/display-version-number` branch is merged before M6, confirm `package_info_plus` (or equivalent) surfaces the version string in `lib/features/settings/about_screen.dart`. If not merged, note as follow-up — it does not block the release build.
- Native splash is RC-blocking for M6. Android 12+ verification must explicitly account for the platform limitation that only a solid background plus centered splash image is supported, not a full-screen background image.

**Patterns to follow:**
- `implementation-plan.md` → M6 → Deliverables + Exit Criteria
- `implementation-plan.md` → Clean-Code Guardrails G1–G12

**Test scenarios:**
- Test expectation: none — this is a sweep/validation unit, not a feature unit

**Verification:**
- `flutter analyze` exits 0 with no warnings
- `flutter test` exits 0 (all tests pass)
- `grep` for `double.*amount|double.*balance` returns 0 hits outside `money_formatter`
- Device matrix smoke passes (documented by operator in `docs/a11y-audit-m6.md` device section)

---

## System-Wide Impact

- **Interaction graph:** Integration tests exercise the full app shell — `bootstrap.dart`, `router.dart`, all six feature controllers, all repositories, and Drift. Any latent cross-slice wiring bug will surface here.
- **Error propagation:** Integration tests assert `tester.takeException() == null` after each flow. Any unhandled `Future`, widget overflow, or Dart exception fails the test explicitly.
- **State lifecycle risks:** `HomeController` is `@Riverpod(keepAlive: true)` — the delete-undo timer persists across test steps. `addTearDown(container.dispose)` must run after every test to flush pending timers.
- **API surface parity:** Adding `Semantics` labels to buttons must not change the visible UI or break existing widget tests that use `find.byType(IconButton)` or similar structural finders. Use additive wrappers.
- **Unchanged invariants:** Repository contracts, Drift schema v1, domain models, and ARB keys are frozen. M6 does not modify any of these.
- **Integration coverage:** Units 2–7 are the scenarios that unit tests and widget tests (with mocked providers) cannot prove — they verify that the full data pipeline from UI interaction through repository → Drift → stream re-emit → widget re-render produces correct end-state DB rows and visible UI updates.

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Integration test for Add-Transaction form requires complex widget interaction (keypad, category picker, save) that may be fragile to widget-tree changes | Use semantic labels (`find.bySemanticsLabel(...)`) and key-based finders where possible; add keys to FAB and Save button if not already present |
| Undo-window timer behavior in integration tests is non-deterministic under FakeAsync | Use `tester.runAsync` for the timer advance, or `tester.pump(const Duration(seconds: 5))` to skip past the 4s window; cross-check with `home_controller_test.dart` existing approach |
| `flutter_native_splash` regen may produce merge conflicts with existing generated platform files | Run regen on a clean branch; commit the full diff in one PR so the before/after is clear |
| Android 12+ cannot show a full-screen native background image | Use `background_image` for iOS and pre-Android-12, but verify Android 12+ with solid `color` + centered `image` and document the platform constraint in the audit / release notes |
| 2× text scale tests may reveal layout overflows introduced in M5 that require widget fixes | Fix overflow at the widget level (e.g. add `Flexible`/`FittedBox` or extend the existing `textScaler` clamp pattern from `SplashDayCount`); do not suppress the test |
| About screen (webview) cannot be integration-tested without a real network | Integration tests skip Settings → About navigation. The About screen is tested manually on device. |

## Sources & References

- **Origin documents:** `docs/plans/implementation-plan.md` → M6; `PRD.md` → Testing Strategy → Integration Tests, Accessibility, Splash Screen
- **Wave plans:** `docs/plans/m5-ui-feature-slices/wave-2-transactions-plan.md`, `wave-3-home-plan.md`, `wave-4-integration-plan.md`
- Related code: `test/integration/bootstrap_to_home_test.dart`, `test/support/test_app.dart`
- Related code: `lib/features/home/home_controller.dart`, `lib/features/transactions/transaction_form_controller.dart`
- Related code: `lib/data/repositories/transaction_repository.dart` (aggregate methods)
- Institutional learnings: `docs/solutions/logic-errors/home-delete-undo-stream-coordination-2026-04-26.md`, `docs/solutions/best-practices/reactive-feature-flow-ownership-2026-04-25.md`
