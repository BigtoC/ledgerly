# M5 Wave 2 — Transactions Slice

**Source of truth:** [`PRD.md`](../../../PRD.md) → *MVP Screens → Add/Edit Transaction*, *Add/Edit Interaction Rules*, *Screen States → Add/Edit*, *Primary User Flow*, *Quick Repeat Flow*, *Layout Primitives → Add/Edit Transaction*. Contracts inherited from [`wave-0-contracts-plan.md`](wave-0-contracts-plan.md). Category-picker consumption follows the frozen Wave 0 §2.1 signature, implemented by Wave 1 Categories.

Transactions owns the full-screen Add/Edit modal at `/home/add` and `/home/edit/:id`: calculator keypad, expense/income toggle (derived from category), category picker, account selector, memo, date, save/delete. It also owns duplicate-flow prefill as the consumer side of Wave 0 §2.3.

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

## 3. Repository contract observations (no new methods)

`TransactionRepository` already exposes everything this slice needs (`save`, `delete`, `getById`). **Do not call `TransactionRepository.duplicate(int)`.** Its documented behavior — "Copies every field except `id` and timestamps; the duplicate is a brand-new transaction row" — saves immediately, which is incompatible with the PRD quick-repeat flow ("user adjusts amount or date if needed → tap Save"). The form uses `getById(sourceId)` to hydrate a prefill and then calls `save(newTx)` on confirmation. `duplicate()` stays on the repository surface unused; removing it is out of scope for this slice.

No Wave 2 contract additions to any repository. If a genuine new method turns out to be necessary during implementation, raise Platform RFC as a separate PR — do not inline SQL or extend interfaces from this slice.

---

## 4. Deliverables

### 4.1 Files (under `lib/features/transactions/`)

- `transaction_form_screen.dart` — replaces the M4 placeholder.
- `transaction_form_controller.dart` — `@riverpod class TransactionFormController extends _$TransactionFormController`. Commands: `appendDigit`, `appendDecimal`, `backspace`, `clear`, `selectCategory`, `selectAccount`, `setDate`, `setMemo`, `save`, `deleteExisting`.
- `transaction_form_state.dart` — Freezed sealed union (see §5).
- `widgets/calculator_keypad.dart` — fixed-height keypad. Respects the active currency's `decimals`.
- `widgets/amount_display.dart` — large-format amount shown above the keypad; re-renders on every digit press.
- `widgets/transaction_type_segmented_control.dart` — expense/income segmented control. Disabled once a category is selected (the category determines type).
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
  const factory TransactionFormState.data({
    required int amountMinorUnits,       // keypad-accumulated integer
    required Account? selectedAccount,
    required Currency? displayCurrency,  // derived from selectedAccount
    required Category? selectedCategory,
    required DateTime date,
    required String memo,
    required bool isDirty,               // any field touched since hydration
    required int? editingId,             // non-null in Edit mode
    required int? duplicateSourceId,     // non-null when opened via duplicate
  }) = _Data;
  const factory TransactionFormState.error(Object error, StackTrace stack) = _Error;
}
```

- No `Empty` / `Saved` / `Deleted` variants. Save/delete side-effects trigger navigation via `context.pop(result)`; the controller exposes `save()` as `Future<Transaction>` that the widget awaits.
- `canSave` is a derived computed getter on `_Data`: `amountMinorUnits > 0 && selectedAccount != null && selectedCategory != null`. Implemented as a Freezed `@late` or an extension method.
- Transaction type (expense/income) is **derived** from `selectedCategory.type`. The segmented control in the UI reflects this as read-only after category selection. Prior to category selection, the control toggles a `pendingType` hint used by the category picker filter — see §7.

---

## 6. Default-account fallback chain (PRD → Add/Edit Interaction Rules)

On Add mode entry, `selectedAccount` defaults to the first resolvable of:
1. `userPreferences.defaultAccountId` (if set and the account is non-archived).
2. The most recently used non-archived account — **deferred to Phase 2** in MVP, since the repository does not expose a "last used" query and adding one is out of scope. For MVP, step 2 is skipped.
3. The first non-archived account by `sortOrder`, then id.

On Edit mode entry, `selectedAccount = Account.fromId(existing.accountId)`. No fallback chain applies.

`displayCurrency` is always `currencyRepositoryProvider.getByCode(selectedAccount.currency)`. When `selectedAccount == null`, the amount display shows a neutral currency based on `userPreferences.defaultCurrency`, but saving is blocked.

---

## 7. Category selection flow

Tap the category chip → `final picked = await showCategoryPicker(context, type: pendingType)`.
- `pendingType` defaults to `expense` on Add entry (PRD → Add/Edit Interaction Rules: "Expense is the default selection when opening from Home").
- User can toggle the segmented control **before** selecting a category to change `pendingType` — this only affects the picker's filter.
- Once a category is selected, the segmented control becomes read-only and reflects `selectedCategory.type`. Re-opening the picker passes `type: selectedCategory.type` to stay within the locked type.

If the picker resolves with `null` (user dismissed), state does not change.

---

## 8. Calculator keypad

Layout per PRD → Layout Primitives:

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

---

## 9. Save flow

1. Controller validates (`canSave == true`).
2. Construct a `Transaction` domain model:
   - `id`: `editingId` (null → repo assigns).
   - `amountMinorUnits`, `currency: selectedAccount.currency`, `categoryId: selectedCategory.id`, `accountId: selectedAccount.id`, `memo` (may be empty string), `date`.
   - `createdAt` / `updatedAt` are set by the repository — do not populate in the controller.
3. Call `transactionRepositoryProvider.save(tx)`.
4. On success: `return tx;` from the command. The widget calls `context.pop(savedTx)` so Home (Wave 3) can pin the day to `savedTx.date` and scroll the new row into view.
5. On failure: surface via `AsyncError`; widget shows a SnackBar using `txSaveFailedSnackbar`; form stays open; nothing is discarded.

Delete (Edit mode only):
- Confirmation dialog (`txDeleteConfirm*`).
- `transactionRepositoryProvider.delete(id)`.
- `context.pop(null)` on success; Home re-renders.

Discard-with-unsaved-changes:
- If `state.isDirty == true` on back/close, show confirm dialog (`txDiscardConfirm*`).
- Widget test: back arrow with dirty state surfaces dialog; clean state pops immediately.

---

## 10. Route arguments (driven by M4 router, not this slice)

| Route                     | Mode      | Arguments (via `GoRouterState.extra`)                                                  |
|---------------------------|-----------|----------------------------------------------------------------------------------------|
| `/home/add`               | Add       | none                                                                                   |
| `/home/add` + `duplicate` | Duplicate | `{'duplicateSourceId': <int>}` — transaction-id-only handoff via `GoRouterState.extra` |
| `/home/edit/:id`          | Edit      | path param `id: int`                                                                   |

On route entry, the screen reads `extra` once and invokes `controller.hydrateForAdd()` / `hydrateForDuplicate(sourceId)` / `hydrateForEdit(id)`. Hydration populates `_Data` and is a one-shot — subsequent user edits mutate state via commands.

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
- **Last-used account fallback** — §6 step 2. MVP skips it; the default chain is preference → first active.
- **Attachments / receipts** — not in MVP.
- **Tax / exemption flags** — not in MVP.
- **CSV import prefill** — Phase 2.

---

## 13. Exit criteria

- `transaction_form_screen.dart` renders Add / Edit / Duplicate modes correctly.
- Keypad respects currency decimals (verified by unit test on `KeypadState` and by widget test on JPY vs USD).
- Category picker integration: opens with the current `pendingType`, returns selection, re-opens pre-filtered to `selectedCategory.type` after first pick.
- Save creates a new row in Add mode; updates in Edit mode; preserves `createdAt` in Edit mode; refreshes `updatedAt`.
- Discard dialog fires on dirty back-navigation; does not fire on clean back.
- Soft keyboard does not cover the keypad (verified by widget test with `tester.showKeyboard`).
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
8. **Editing a transaction whose category was archived.** Chip still renders (user sees historical category) but re-opening the picker hides archived categories. User must explicitly change category to save. Widget test.
9. **Currency change on account swap.** Switching the account mid-edit to one with a different currency: amount display re-formats; `amountMinorUnits` stays but its meaning changes (e.g., 1234 was $12.34, becomes ¥1234). Decision: on account change, leave `amountMinorUnits` unchanged. Flag in release notes if this surprises users. Phase 2 with auto-conversion handles it properly.
