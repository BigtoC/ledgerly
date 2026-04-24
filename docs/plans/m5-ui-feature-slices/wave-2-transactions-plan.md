# M5 Wave 2 — Transactions Slice

**Source of truth:** [`PRD.md`](../../../PRD.md) → *MVP Screens → Add/Edit Transaction*, *Add/Edit Interaction Rules*, *Screen States → Add/Edit*, *Primary User Flow*, *Quick Repeat Flow*, *Layout Primitives → Add/Edit Transaction*. Contracts inherited from [`wave-0-contracts-plan.md`](wave-0-contracts-plan.md). Category-picker consumption follows the frozen Wave 0 §2.1 signature, implemented by Wave 1 Categories.

Transactions owns the Add/Edit transaction surface at `/home/add` and `/home/edit/:id`: full-screen modal on `<600dp`, constrained dialog on `>=600dp`, with the same internal form body in both containers. It includes the calculator keypad, expense/income toggle, category picker, account selector, memo, date, save/delete, and duplicate-flow prefill as the consumer side of Wave 0 §2.3.

---

## 1. Goal

Replace the M4 placeholder at `lib/features/transactions/transaction_form_screen.dart` with the real modal form. Every domain rule (category type lock, memo text is free-form, amount stored as integer minor units, currency inherited from the selected account) is already enforced by the repositories; this slice is UI + coordination only.

**Entry criterion:** Wave 1 Categories + Accounts merged. Specifically: `showCategoryPicker` is a real implementation (not `UnimplementedError`), and `userPreferences.defaultAccountId` is writable from Settings / Accounts.

---

## 2. Inputs

| Dependency                                  | Purpose                                                                                           | Import path                                        |
|---------------------------------------------|---------------------------------------------------------------------------------------------------|----------------------------------------------------|
| `transactionRepositoryProvider`             | `save`, `delete`, `getById`                                                                       | `app/providers/repository_providers.dart`          |
| `categoryRepositoryProvider`                | `getById` (for Edit-mode hydration); `watchAll` not needed — picker owns its own data source      | `app/providers/repository_providers.dart`          |
| `accountRepositoryProvider`                 | `watchAll(includeArchived: false)` for account selector; `getById` for default-account resolution | `app/providers/repository_providers.dart`          |
| `currencyRepositoryProvider`                | Resolve `account.currency` → `Currency` (for `decimals` used by the keypad)                       | `app/providers/repository_providers.dart`          |
| `userPreferencesRepositoryProvider`         | Read `defaultAccountId`, `defaultCurrency` (fallback chain per §6)                                | `app/providers/repository_providers.dart`          |
| `showCategoryPicker` (Categories)           | Wave 0 §2.1 frozen API — **cross-slice import allowed** per Wave 0 §2.5                           | `features/categories/widgets/category_picker.dart` |
| `money_formatter.dart`                      | Live-render the amount display during keypad entry                                                | `core/utils/money_formatter.dart`                  |
| `date_helpers.dart`                         | Format displayed date in the date field                                                           | `core/utils/date_helpers.dart`                     |
| `icon_registry.dart` / `color_palette.dart` | Render category chip after selection                                                              | `core/utils/*.dart`                                |

This slice does **not** import from Home. The Home → form navigation is driven by `go_router` route extras only.

---

## 3. Repository contract observations

`TransactionRepository` already exposes `save`, `delete`, and `getById`. The form uses `getById(sourceId)` to hydrate a duplicate prefill and then calls `save(newTx)` on confirmation — the user may edit amount/date before committing, per PRD's quick-repeat flow.

### 3.1 Remove `TransactionRepository.duplicate(int)` in this slice's contracts step

The existing `duplicate()` method saves a new row immediately, which is incompatible with the PRD quick-repeat flow ("user adjusts amount or date if needed → tap Save"). Leaving it on the surface unused is a footgun — a future agent may wire it up to the duplicate menu item thinking it returns a draft.

**Action for Wave 2 agent:**
- Delete the `duplicate` method from `lib/data/repositories/transaction_repository.dart` and any corresponding test.
- Add a short class-level doc comment on `TransactionRepository` explaining **why** the repository does not expose a duplicate convenience: the quick-repeat flow is driven from the UI via `getById` → prefill → user edit → `save`, so repository-level duplicate-save would bypass the edit step. Keep the comment to 2–3 lines — enough to steer a future reader away from re-adding it.
- Verify no callers exist (`rg 'transactionRepository.*duplicate|\.duplicate\('`) before removal.

### 3.2 Add `AccountRepository.getLastUsedActiveAccount()`

Wave 2 needs one small repository contract addition to preserve the PRD's Add Transaction fallback order when `default_account_id` is unset:

```dart
// lib/data/repositories/account_repository.dart
Future<Account?> getLastUsedActiveAccount();
```

Contract:
- Returns the most recently used non-archived account based on the newest transaction (`date DESC, id DESC`).
- **Archive filter applies in the SQL, not in Dart.** The query must `JOIN` / `WHERE` on the account-archive discriminator (`accounts.archived_at IS NULL` or the repo's equivalent) so archived rows never leave the DAO. Do not fetch the newest transaction first and then filter archived accounts in application code — that approach returns `null` when the newest transaction belongs to an archived account, which is the wrong answer.
- Returns `null` when no transaction exists for any active account.
- One-shot read only; no stream needed.

Required tests:
- No transactions -> returns `null`.
- Newest transaction belongs to active account -> returns that account.
- Newest transaction belongs to archived account but an older active account exists -> returns the most recent active account.
- All historical accounts archived -> returns `null`.

---

## 4. Deliverables

### 4.1 Files (under `lib/features/transactions/`)

- `transaction_form_screen.dart` — replaces the M4 placeholder.
- `transaction_form_controller.dart` — `@riverpod class TransactionFormController extends _$TransactionFormController`. Commands: `appendDigit`, `appendDecimal`, `backspace`, `clear`, `selectCategory`, `selectAccount`, `setDate`, `setMemo`, `save`, `deleteExisting`. Hydration entrypoints: `hydrateForAdd()`, `hydrateForDuplicate(sourceId)`, `hydrateForEdit(id)`.
- `transaction_form_state.dart` — Freezed sealed union (see §5).
- `widgets/calculator_keypad.dart` — fixed-height keypad. Respects the active currency's `decimals`.
- `widgets/amount_display.dart` — large-format amount shown above the keypad; re-renders on every digit press.
- `widgets/transaction_type_segmented_control.dart` — expense/income segmented control. Before category selection it edits `pendingType`; after selection it still allows a type change, but only through the confirm-then-clear flow that removes the incompatible category first.
- `widgets/category_chip.dart` — shows the selected category (icon + name); tap re-opens the picker.
- `widgets/account_selector_tile.dart` — shows selected account + currency code; tap opens an account picker sheet.
- `widgets/account_picker_sheet.dart` — modal sheet listing non-archived accounts.
- `widgets/memo_field.dart` — multi-line text field.
- `widgets/date_field.dart` — tile that opens `showDatePicker`.

Widget classes only used inside the slice stay library-private.

### 4.2 ARB keys

Prefix: `tx*` (Wave 0 §2.2). `transactionType*` keys already reserved in M4 (`transactionTypeExpense`, `transactionTypeIncome`).

Minimum new keys: `txAddTitle`, `txEditTitle`, `txCategoryLabel`, `txCategoryEmpty`, `txAccountLabel`, `txAccountEmpty`, `txDateLabel`, `txMemoLabel`, `txSaveFailedSnackbar`, `txDeleteConfirmTitle`, `txDeleteConfirmBody`, `txDiscardConfirmTitle`, `txDiscardConfirmBody`, `txKeypadClear`, `txKeypadBackspace`. Full list discovered during implementation; `app_en.arb`, `app_zh_TW.arb`, and `app_zh_CN.arb` are updated in the same commit while `app_zh.arb` stays fallback-only.

### 4.3 Tests

- `test/unit/controllers/transaction_form_controller_test.dart` — keypad digit math per currency decimals; type derivation from selected category; default-account fallback chain; save success + save failure error surfacing; delete in Edit mode; duplicate prefill from a source id.
- `test/unit/utils/keypad_decimal_math_test.dart` — pure helper that translates digit sequences to minor-unit integers for each currency (`decimals = 0`, `2`, `18`). Lands under utils since it's pure arithmetic, not controller-specific.
- `test/widget/features/transactions/transaction_form_screen_test.dart` — Add mode renders with defaults, save disabled until valid, save enables after amount+category+account present, confirm-discard dialog on back with unsaved changes, Edit mode hydrates from `getById`, duplicate mode prefills from source.
- `test/widget/features/transactions/calculator_keypad_test.dart` — decimal-point disabled for JPY (decimals=0), decimal-point enabled for USD (decimals=2), digit overflow after max decimals reached.

---

## 5. State machine

```dart
@freezed
sealed class TransactionFormState with _$TransactionFormState {
  const factory TransactionFormState.loading() = _Loading;
  const factory TransactionFormState.empty() = _Empty;
  const factory TransactionFormState.data({
    required int amountMinorUnits,       // keypad-accumulated integer
    required Account? selectedAccount,
    required Currency? displayCurrency,  // derived from selectedAccount
    required Category? selectedCategory,
    required CategoryType pendingType,   // drives picker before category lock-in
    required DateTime date,
    required String memo,
    required bool isDirty,               // any field touched since hydration
    required bool isSaving,
    required bool isDeleting,
    required int? editingId,             // non-null in Edit mode
    required int? duplicateSourceId,     // non-null when opened via duplicate
  }) = _Data;
  const factory TransactionFormState.error(Object error, StackTrace stack) = _Error;
}
```

- `empty()` is reserved for recoverable no-account / not-found states where the form cannot proceed until the user fixes the missing dependency. Save/delete side-effects still trigger navigation via `context.pop(result)`.
- `canSave` is a derived computed getter on `_Data`: `amountMinorUnits > 0 && selectedAccount != null && selectedCategory != null`. Implemented as a Freezed `@late` or an extension method.
- Transaction type (expense/income) is **derived** from `selectedCategory.type` once a category is chosen. Before category selection, the segmented control edits `pendingType`, which is controller-owned state used by the category picker filter — see §7.
- `isSaving` / `isDeleting` serialize async commands. AppBar actions and destructive controls read them to disable re-entry; rapid double-taps must produce one repository write.

---

## 6. Default-account fallback chain (PRD → Add/Edit Interaction Rules)

On Add mode entry, `selectedAccount` defaults to the first resolvable of:
1. `userPreferences.defaultAccountId` (if set and the account is non-archived).
2. The most recently used non-archived account via `accountRepositoryProvider.getLastUsedActiveAccount()`.
3. The first non-archived account by `sortOrder`, then id.

On Edit mode entry, `selectedAccount = Account.fromId(existing.accountId)`. No fallback chain applies.

`displayCurrency` is `selectedAccount.currency` when an account is selected. When `selectedAccount == null`, the amount display shows a neutral currency resolved from `userPreferences.defaultCurrency`, but saving is blocked.

If all accounts are archived and no active account exists, hydration enters `TransactionFormState.empty()` and the screen renders the PRD-required `Create account` CTA. That CTA navigates to `/accounts/new`; on return, the form re-runs add-mode hydration.

---

## 7. Category selection flow

Tap the category chip → `final picked = await showCategoryPicker(context, type: pendingType)`.
- `pendingType` defaults to `expense` on Add entry (PRD → Add/Edit Interaction Rules: "Expense is the default selection when opening from Home").
- User can toggle the segmented control **before** selecting a category to change `pendingType` — this only affects the picker's filter.
- Once a category is selected, the segmented control remains available. If the user switches to the opposite type, show a confirm-then-clear dialog. Confirming clears the incompatible category, updates `pendingType`, and returns the chip to its empty state. Cancelling keeps the current category and type.
- Re-opening the picker with an already-selected category passes `type: selectedCategory.type` until the user explicitly changes type via the confirmation flow above.

If the picker resolves with `null` because the user dismissed it, state does not change.

If the picker resolves with `null` from its empty-state CTA path, Transactions owns the next step per Wave 0 §2.3:
1. route to category management / creation,
2. when the user returns, re-open `showCategoryPicker(context, type: pendingType)`,
3. require explicit selection from the reopened picker rather than auto-selecting.

---

## 8. Calculator keypad

Internal form-body layout per PRD → Layout Primitives:

```text
Scaffold(resizeToAvoidBottomInset: false)
  └─ SafeArea
      └─ Column
          ├─ Expanded → SingleChildScrollView (type segmented, amount display, category chip, account tile, date field, memo)
          └─ CalculatorKeypad (fixed height)
```

Keypad grid:
- `7 8 9 ⌫`
- `4 5 6 .`
- `1 2 3  `
- `0 00 C  ` — `00` pastes two zeros, `C` clears the amount.
- Save button lives in the AppBar (not the keypad) per PRD to keep the keypad numeric-focused.

Digit math (`test/unit/utils/keypad_decimal_math_test.dart`):
- Each digit press multiplies `amountMinorUnits` by 10 and adds the digit, **clamped** so total decimal positions after `.` never exceed the currency's `decimals`.
- Decimal point press sets an internal "fractional mode"; subsequent digits accumulate into the fractional part.
- For `decimals = 0` (JPY), the decimal point is **disabled** (greyed out). Widget test covers this.
- Backspace divides and decrements in reverse.
- Implementation: a pure helper `KeypadState(amountMinorUnits, fractionalDigitsEntered)` with `.push(digit)`, `.pop()`, `.clear()`, `.pushDecimal()` methods.

The keypad must never be covered by the soft keyboard. `resizeToAvoidBottomInset: false` on the `Scaffold`; memo field opens keyboard, form scrolls above the keypad. Widget test: `tester.showKeyboard(memoField)` then assert keypad rect is unchanged.

Adaptive container contract:
- `<600dp`: full-screen modal push as wired by the router.
- `>=600dp`: constrained dialog (max 560dp wide) containing the same internal form body.
- The account picker mirrors the shell adaptation rule: bottom sheet on phone, constrained dialog on `>=600dp` so the form does not stack an unbounded phone sheet inside the tablet dialog.

---

## 9. Save flow

1. Controller validates (`canSave == true`).
2. Construct a `Transaction` domain model:
   - Add / duplicate: `id = 0`.
   - Edit: `id = editingId`.
   - `amountMinorUnits`, `currency: selectedAccount.currency`, `categoryId: selectedCategory.id`, `accountId: selectedAccount.id`, `memo` (may be empty string), `date`.
   - Add / duplicate pass placeholder timestamps from hydration time; `TransactionRepository.save(...)` overwrites them on insert.
   - Edit reuses the hydrated transaction's `createdAt`; `TransactionRepository.save(...)` preserves it and refreshes `updatedAt`.
3. Call `transactionRepositoryProvider.save(tx)`.
4. On success: return the **persisted** `Transaction` from `save(tx)`. The widget calls `context.pop(savedTx)` so Home (Wave 3) can pin the day to `savedTx.date` and scroll the new row into view. Home depends on the route result's persisted `id` and `date`; returning the full persisted model keeps the contract aligned with the current repository API.
5. On failure during save: keep the screen in `.data`, clear `isSaving`, and surface the failure to the widget as a command error so it can show `txSaveFailedSnackbar`. Reserve `TransactionFormState.error(...)` for hydration/load failures (`hydrateForEdit`, `hydrateForDuplicate`, or irrecoverable delete failures), not normal save-action errors.

Delete (Edit mode only):
- Confirmation dialog (`txDeleteConfirm*`).
- `transactionRepositoryProvider.delete(id)`.
- If delete returns `true`, `context.pop(null)` on success; Home re-renders.
- If delete returns `false` because the row is already gone, move to a recoverable not-found path rather than silently succeeding.

Discard-with-unsaved-changes:
- If `state.isDirty == true` on back/close, show confirm dialog (`txDiscardConfirm*`).
- Widget test: back arrow with dirty state surfaces dialog; clean state pops immediately.

Inline validation:
- Save stays disabled until the form is valid, per PRD.
- After the first invalid save attempt or when the user touches a required field and leaves it empty, show inline guidance on the amount display, category row, and account row for whichever requirement is missing.
- Inline guidance clears immediately when the missing requirement is satisfied.

---

## 10. Route arguments (driven by M4 router, not this slice)

| Route                     | Mode      | Arguments (via `GoRouterState.extra`)                                                  |
|---------------------------|-----------|----------------------------------------------------------------------------------------|
| `/home/add`               | Add       | none                                                                                   |
| `/home/add` + `duplicate` | Duplicate | `{'duplicateSourceId': <int>}` — transaction-id-only handoff via `GoRouterState.extra` |
| `/home/edit/:id`          | Edit      | path param `id: int`                                                                   |

On route entry, the screen reads `extra` once and invokes `controller.hydrateForAdd()` / `hydrateForDuplicate(sourceId)` / `hydrateForEdit(id)`. Hydration populates `_Data` and is a one-shot — subsequent user edits mutate state via commands.

Hydration failure behavior:
- `hydrateForEdit(id)` / `hydrateForDuplicate(sourceId)` use `transactionRepository.getById(...)`.
- If the row is missing, enter `TransactionFormState.empty()` and show a recoverable not-found state with a snackbar + pop back to Home, rather than leaving the widget to guess how to recover from `null`.

**Do not add new routes in this slice.** Router changes land in Wave 4 Integration.

---

## 11. Cross-slice contract adherence (Wave 0)

- §2.1 — `showCategoryPicker` is called exactly as frozen. No extra positional params. No drive-by edits to the picker's signature or file.
- §2.3 — Duplicate flow: Home owns the swipe/overflow affordance and route navigation; Transactions owns form prefill + save. The contract between them is the `duplicateSourceId` extra.
- §2.3 — Account currency indicator in the form: this slice owns rendering. Accounts slice is unaffected.
- §2.3 — Default account: this slice **reads** `userPreferences.defaultAccountId`; Settings writes it.
- §2.4 — Do not edit `router.dart`, `repository_providers.dart`, any repository, or Drift tables. See §3 for why `duplicate()` is not called.
- §2.5 — All widgets under `lib/features/transactions/widgets/`. Cross-slice import of `showCategoryPicker` from `features/categories/widgets/category_picker.dart` is allowed (slice-to-slice widget imports are permitted; only layer boundaries are enforced).

---

## 12. Out of scope (defer)

- **Transfers** between accounts — Phase 2. No UI for "transfer" type; no third type value exists (PRD explicitly rejects one).
- **Recurring transactions** / pending approval — Phase 2.
- **Attachments / receipts** — not in MVP.
- **Tax / exemption flags** — not in MVP.
- **CSV import prefill** — Phase 2.

---

## 13. Exit criteria

- `transaction_form_screen.dart` renders Add / Edit / Duplicate modes correctly.
- Keypad respects currency decimals (verified by unit test on `KeypadState` and by widget test on JPY vs USD).
- Category picker integration: opens with the current `pendingType`, returns selection, re-opens pre-filtered to `selectedCategory.type` after first pick.
- Switching type after a category is selected triggers the confirm-then-clear flow and clears the chip on confirmation.
- Empty-category flow returns from category creation and re-opens the picker; the user then explicitly selects a category.
- Save creates a new row in Add mode; updates in Edit mode; preserves `createdAt` in Edit mode; refreshes `updatedAt`.
- Save pops with the persisted `Transaction` returned by the repository, including populated `id` and timestamps.
- Discard dialog fires on dirty back-navigation; does not fire on clean back.
- Soft keyboard does not cover the keypad (verified by widget test with `tester.showKeyboard`).
- No-active-account state renders `Create account` CTA and blocks save until an active account exists.
- `>=600dp` form rendering works inside the constrained dialog container without overflow.
- 2× text scale passes on the form; keypad reflows or clamps per PRD Constraint rule.
- `flutter analyze` clean; `flutter test` green, including all tests from §4.3.

---

## 14. Sequencing

Single agent, single PR. Entry: Wave 1 merged.

1. Implement `KeypadState` + `test/unit/utils/keypad_decimal_math_test.dart`. (Pure helper first — it is the riskiest piece.)
2. Implement `transaction_form_state.dart` + `transaction_form_controller.dart` with all commands and the three hydration entry points (Add / Duplicate / Edit).
3. Implement `widgets/calculator_keypad.dart` + `widgets/amount_display.dart`.
4. Implement `widgets/category_chip.dart`, `widgets/account_selector_tile.dart`, `widgets/account_picker_sheet.dart`, `widgets/memo_field.dart`, `widgets/date_field.dart`, `widgets/transaction_type_segmented_control.dart`.
5. Assemble `transaction_form_screen.dart`.
6. Add ARB keys (§4.2) across `app_en.arb`, `app_zh_TW.arb`, and `app_zh_CN.arb` in the same commit.
7. Write controller + widget tests.
8. Run `dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test`.
9. Open PR titled `feat(m5): transactions slice`.

---

## 15. Risks

1. **Keypad decimal overflow.** Entering more digits than `currency.decimals` silently drops them. The `KeypadState.push` method must clamp; widget and unit tests both cover this.
2. **Calling `repo.duplicate()` by mistake.** An agent familiar with the repo surface might invoke it thinking it produces a prefill. It does not — it saves. Reviewer check: grep for `duplicate(` in `features/transactions/` — only call sites should be `selectedCategory.type.duplicate` (no such thing) or none. Expect zero hits.
3. **Type derivation race.** If the user picks an income category, toggles the type control to expense, then picks a new category — the new category filter uses the wrong type. Fix: picker filter uses `pendingType` only until a category is selected; once selected, toggling is disabled.
4. **`resizeToAvoidBottomInset` accidentally left at default (`true`).** Keypad gets pushed off-screen by the keyboard. Widget test asserts keypad rect is stable with keyboard open.
5. **Account selector showing archived accounts.** Filter by `includeArchived: false`. Test: archived account not present in picker sheet.
6. **Save race on rapid double-tap.** Widget test: simulate two rapid save taps; repository should see one save, not two (debounce or button `enabled: !saving`).
7. **Duplicate-prefill carries stale `date`.** PRD says "date defaults to today" in the duplicate flow. Controller's `hydrateForDuplicate` must overwrite `date` to `DateTime.now()` after copying other fields.
8. **Editing a transaction whose category was archived.** Chip still renders (user sees historical category) and unchanged archived categories remain valid for save. Re-opening the picker hides archived categories; only a replacement selection must be active. Widget test.
9. **Currency change on account swap.** Currency changes do not mutate any already-saved record; they only affect the new or in-progress edit record. If the user switches to an account with a different currency after entering a non-zero amount, show a confirmation that switching currencies clears the entered amount for this in-progress record. On confirm: clear amount + update display currency. On cancel: keep the current account + amount.
