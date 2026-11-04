// Transaction-form controller — Wave 2 §4.1 / §5 / §6 / §9 / Task 5.
//
// Owns the form's mutable state plus the keypad accumulator, drives all
// four hydration entry points (Add / Duplicate / Edit / EditShoppingListDraft),
// and exposes the typed commands the screen widget binds to. Every command
// mutates the `_Data` variant via `state = ...`; widgets never call
// repositories directly.
//
// Controller invariants:
//   - `tx.currency = displayCurrency` on save — the transaction currency
//     is user-controlled (not bound to account currency). The account's
//     currency seeds `displayCurrency` on hydration when `currencyTouched`
//     is false; after the user manually picks a currency, account changes
//     no longer re-seed `displayCurrency`.
//   - Edit save preserves `createdAt`; new-row save passes a placeholder
//     timestamp that `TransactionRepository.save` overwrites on insert.
//   - `isSaving` / `isDeleting` serialize async commands so rapid double
//     taps produce one repository write (Wave 2 risk #6).
//   - `submissionAction` tracks in-flight shopping-list commands the same
//     way `isSaving`/`isDeleting` track transaction commands — repeat calls
//     during in-flight are ignored (Task 5 §10).
//   - Commands that can fail in a way the user sees (`save`,
//     `deleteExisting`, `saveDraft`, `convertDraft`,
//     `resolveCategoryChipTap`) never throw: they return a sealed outcome
//     from `transaction_form_state.dart` that the screen switches on.
//   - Hydration commands never throw either: a failed read lands in
//     `.error`, and a hydration still awaiting when the form closes stops
//     at its next `await` without touching `state`.

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderSubscription;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/default_currency_provider.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../domain/models/account.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/currency.dart';
import '../../../../domain/models/shopping_list_item.dart';
import '../../../../domain/models/transaction.dart';
import '../../categories/view_models/categories_controller.dart';
import 'amount_formula.dart';
import 'keypad_state.dart';
import 'transaction_form_state.dart';

part 'transaction_form_controller.g.dart';

@Riverpod(
  dependencies: [
    transactionRepository,
    accountRepository,
    categoryRepository,
    userPreferencesRepository,
    currencyRepository,
    shoppingListRepository,
    defaultCurrency,
    exchangeRateRepository,
    initialDefaultCurrency,
    categoriesByType,
  ],
)
class TransactionFormController extends _$TransactionFormController {
  /// Pure-helper accumulator that backs the keypad commands. It stays as a
  /// private mutation engine on the notifier, but every user-visible snapshot
  /// is mirrored into `TransactionFormState.data.keypad` so widgets never read
  /// public properties from the notifier itself.
  KeypadState _keypad = const KeypadState.initial();
  int _keypadRevision = 0;

  /// The current form mode, mirrored into `state.formMode` on every emit.
  TransactionFormMode _formMode = const AddTransactionMode();

  @override
  TransactionFormState build() {
    // Hydration is explicit (Wave 2 §10): the screen calls `hydrate` with
    // the mode the router built. `build` only sets up the loading
    // placeholder.
    return TransactionFormState.loading(formMode: _formMode);
  }

  // ---------- Hydration ----------

  /// Runs the hydration entry point for [mode].
  Future<void> hydrate(TransactionFormMode mode) => switch (mode) {
    AddTransactionMode(:final initialDate) => hydrateForAdd(
      initialDate: initialDate,
    ),
    DuplicateTransactionMode(:final sourceTransactionId) => hydrateForDuplicate(
      sourceTransactionId,
    ),
    EditTransactionMode(:final transactionId) => hydrateForEdit(transactionId),
    EditShoppingListDraftMode(:final shoppingListItemId) =>
      hydrateForShoppingListDraft(shoppingListItemId),
  };

  /// Hydrate for the Add flow. When [initialDate] is supplied (e.g.,
  /// from Home's FAB carrying the currently selected day) the form's
  /// `date` field starts at that day instead of today; the value is
  /// normalized to local midnight so it round-trips through `setDate`.
  /// Omitting [initialDate] preserves the prior default of today.
  Future<void> hydrateForAdd({DateTime? initialDate}) async {
    _formMode = AddTransactionMode(initialDate: initialDate);
    try {
      state = TransactionFormState.loading(formMode: _formMode);
      final account = await _resolveDefaultAccount();
      if (!ref.mounted) return;
      if (account == null) {
        state = TransactionFormState.empty(
          reason: TransactionFormEmptyReason.noActiveAccount,
          formMode: _formMode,
        );
        return;
      }
      _keypad = const KeypadState.initial();
      _keypadRevision = 0;
      state = TransactionFormState.data(
        formMode: _formMode,
        amountMinorUnits: 0,
        keypad: _keypad,
        selectedAccount: account,
        displayCurrency: account.currency,
        currencyTouched: false,
        selectedCategory: null,
        date: initialDate == null
            ? _today()
            : DateTime(initialDate.year, initialDate.month, initialDate.day),
        memo: '',
        isDirty: false,
        isSaving: false,
        isDeleting: false,
        editingId: null,
        duplicateSourceId: null,
        originalCreatedAt: null,
      );
    } catch (e, st) {
      if (ref.mounted) {
        state = TransactionFormState.error(e, st, formMode: _formMode);
      }
    }
  }

  Future<void> hydrateForDuplicate(int sourceId) async {
    _formMode = DuplicateTransactionMode(sourceTransactionId: sourceId);
    try {
      state = TransactionFormState.loading(formMode: _formMode);
      final txRepo = ref.read(transactionRepositoryProvider);
      final source = await txRepo.getById(sourceId);
      if (!ref.mounted) return;
      if (source == null) {
        state = TransactionFormState.empty(
          reason: TransactionFormEmptyReason.notFound,
          formMode: _formMode,
        );
        return;
      }
      final accountRepo = ref.read(accountRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final sourceAccount = await accountRepo.getById(source.accountId);
      if (!ref.mounted) return;
      // Source account no longer usable — fall back to the standard
      // default-resolution chain, like an Add hydration but with
      // amount/category/memo prefilled.
      final account = sourceAccount == null || sourceAccount.isArchived
          ? await _resolveDefaultAccount()
          : sourceAccount;
      if (!ref.mounted) return;
      if (account == null) {
        state = TransactionFormState.empty(
          reason: TransactionFormEmptyReason.noActiveAccount,
          formMode: _formMode,
        );
        return;
      }
      await _applyDuplicatePrefill(
        source: source,
        account: account,
        categoryRepo: categoryRepo,
        duplicateSourceId: sourceId,
      );
    } catch (e, st) {
      if (ref.mounted) {
        state = TransactionFormState.error(e, st, formMode: _formMode);
      }
    }
  }

  Future<void> hydrateForEdit(int id) async {
    _formMode = EditTransactionMode(transactionId: id);
    try {
      state = TransactionFormState.loading(formMode: _formMode);
      final txRepo = ref.read(transactionRepositoryProvider);
      final existing = await txRepo.getById(id);
      if (!ref.mounted) return;
      if (existing == null) {
        state = TransactionFormState.empty(
          reason: TransactionFormEmptyReason.notFound,
          formMode: _formMode,
        );
        return;
      }
      final accountRepo = ref.read(accountRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final account = await accountRepo.getById(existing.accountId);
      if (!ref.mounted) return;
      if (account == null) {
        state = TransactionFormState.empty(
          reason: TransactionFormEmptyReason.notFound,
          formMode: _formMode,
        );
        return;
      }
      final category = await categoryRepo.getById(existing.categoryId);
      if (!ref.mounted) return;
      _keypad = _keypadForStored(
        existing.amountMinorUnits,
        existing.amountFormula,
        decimals: existing.currency.decimals,
      );
      _keypadRevision = 0;
      state = TransactionFormState.data(
        formMode: _formMode,
        amountMinorUnits: existing.amountMinorUnits,
        keypad: _keypad,
        selectedAccount: account,
        displayCurrency: existing.currency,
        currencyTouched: true,
        selectedCategory: category,
        date: existing.date,
        memo: existing.memo ?? '',
        isDirty: false,
        isSaving: false,
        isDeleting: false,
        editingId: id,
        duplicateSourceId: null,
        originalCreatedAt: existing.createdAt,
      );
    } catch (e, st) {
      if (ref.mounted) {
        state = TransactionFormState.error(e, st, formMode: _formMode);
      }
    }
  }

  /// Hydrate for the EditShoppingListDraft flow.
  ///
  /// Fetches the draft via `ShoppingListRepository.getById(id)`.
  ///   - If null: emits `TransactionFormEmpty.draftNotFound`.
  ///   - Otherwise: hydrates account, category, memo, date, and — when
  ///     the draft has a non-null amount/currency — resolves the currency
  ///     from `CurrencyRepository`. When the draft amount/currency is null,
  ///     seeds `displayCurrency` from the selected account.
  Future<void> hydrateForShoppingListDraft(int shoppingListItemId) async {
    _formMode = EditShoppingListDraftMode(
      shoppingListItemId: shoppingListItemId,
    );
    try {
      state = TransactionFormState.loading(formMode: _formMode);
      final slRepo = ref.read(shoppingListRepositoryProvider);
      final draft = await slRepo.getById(shoppingListItemId);
      if (!ref.mounted) return;
      if (draft == null) {
        state = TransactionFormState.empty(
          reason: TransactionFormEmptyReason.draftNotFound,
          formMode: _formMode,
        );
        return;
      }

      final accountRepo = ref.read(accountRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);

      final account = await accountRepo.getById(draft.accountId);
      if (!ref.mounted) return;
      if (account == null) {
        state = TransactionFormState.empty(
          reason: TransactionFormEmptyReason.noActiveAccount,
          formMode: _formMode,
        );
        return;
      }

      final category = await categoryRepo.getById(draft.categoryId);
      if (!ref.mounted) return;

      // Resolve currency: use draft currency when present, otherwise
      // seed from the selected account.
      Currency displayCurrency = account.currency;
      bool currencyTouched = false;
      if (draft.draftCurrencyCode != null) {
        final currencyRepo = ref.read(currencyRepositoryProvider);
        final resolved = await currencyRepo.getByCode(draft.draftCurrencyCode!);
        if (!ref.mounted) return;
        if (resolved != null) {
          displayCurrency = resolved;
          currencyTouched = true;
        }
      }

      final amountMinorUnits = draft.draftAmountMinorUnits ?? 0;
      _keypad = amountMinorUnits > 0
          ? KeypadState.fromAmount(
              amountMinorUnits,
              decimals: displayCurrency.decimals,
            )
          : const KeypadState.initial();
      _keypadRevision = 0;

      state = TransactionFormState.data(
        formMode: _formMode,
        amountMinorUnits: amountMinorUnits,
        keypad: _keypad,
        selectedAccount: account,
        displayCurrency: displayCurrency,
        currencyTouched: currencyTouched,
        selectedCategory: category,
        date: draft.draftDate,
        memo: draft.memo ?? '',
        isDirty: false,
        isSaving: false,
        isDeleting: false,
        editingId: null,
        duplicateSourceId: null,
        originalCreatedAt: null,
        shoppingListItemId: shoppingListItemId,
        selectedAccountIsArchived: account.isArchived,
        selectedCategoryIsArchived: category?.isArchived ?? false,
      );
    } catch (e, st) {
      if (ref.mounted) {
        state = TransactionFormState.error(e, st, formMode: _formMode);
      }
    }
  }

  // ---------- Keypad commands ----------

  void appendDigit(int digit) {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    final decimals = s.displayCurrency?.decimals ?? 2;
    _keypad = _keypad.push(digit, decimals: decimals);
    state = _copyWithKeypad(s);
  }

  void appendDecimal() {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    final decimals = s.displayCurrency?.decimals ?? 2;
    _keypad = _keypad.pushDecimal(decimals: decimals);
    // amountMinorUnits doesn't change on the decimal press itself, but
    // the visible display string does — bump isDirty and keypadRevision so
    // Riverpod rebuilds and the discard dialog fires if the user abandons.
    state = _copyWithKeypad(s);
  }

  void backspace() {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    final decimals = s.displayCurrency?.decimals ?? 2;
    final next = _keypad.pop(decimals: decimals);
    if (next == _keypad) return;
    _keypad = next;
    state = _copyWithKeypad(s);
  }

  void clearAmount() {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    final next = _keypad.clear();
    if (next == _keypad) return;
    _keypad = next;
    state = _copyWithKeypad(s);
  }

  void applyOperator(CalcOperator op) {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    final decimals = s.displayCurrency?.decimals ?? 2;
    final next = _keypad.pushOperator(op, decimals: decimals);
    if (next == _keypad) return;
    _keypad = next;
    state = _copyWithKeypad(s);
  }

  void equals() {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    final next = _finishPendingExpression(s);
    if (!identical(next, s)) state = next;
  }

  /// Presses `=` on the keypad so the display shows the amount that is
  /// about to be persisted. Returns [s] unchanged when no expression is
  /// pending.
  TransactionFormData _finishPendingExpression(TransactionFormData s) {
    final decimals = s.displayCurrency?.decimals ?? 2;
    final next = _keypad.equals(decimals: decimals);
    if (next == _keypad) return s;
    _keypad = next;
    return _copyWithKeypad(s);
  }

  /// Creates a `copyWith` snapshot that mirrors the current keypad
  /// state into `TransactionFormData`, always incrementing
  /// `keypadRevision` so Riverpod rebuilds even when `amountMinorUnits`
  /// did not change (e.g., operator tap, decimal-start while evaluating).
  ///
  /// `amountMinorUnits` mirrors the value `=` would produce, not the
  /// operand being typed: mid-expression (`1 + 2`) the form already holds
  /// 3, so validation and every submit path see the finished result.
  TransactionFormData _copyWithKeypad(TransactionFormData s) {
    _keypadRevision += 1;
    final decimals = s.displayCurrency?.decimals ?? 2;
    return s.copyWith(
      amountMinorUnits: _keypad.equals(decimals: decimals).amountMinorUnits,
      keypad: _keypad,
      isDirty: true,
      keypadRevision: _keypadRevision,
    );
  }

  // ---------- Field commands ----------

  void selectCategory(Category category) {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    if (s.submissionAction != TransactionFormSubmissionAction.none) return;
    state = s.copyWith(
      selectedCategory: category,
      isDirty: true,
      selectedCategoryIsArchived: category.isArchived,
    );
  }

  /// Picks an account. When `currencyTouched` is false, the account's
  /// currency re-seeds `displayCurrency`. When `currencyTouched` is true,
  /// the user has manually selected a currency and account changes only
  /// update `selectedAccount`.
  ///
  /// When the new account's currency differs from `displayCurrency` and
  /// the user has already entered a non-zero amount (and `currencyTouched`
  /// is false), the widget prompts for confirmation (Wave 2 risk #9) and
  /// re-invokes with `clearAmountOnCurrencyChange: true`.
  void selectAccount(
    Account account, {
    bool clearAmountOnCurrencyChange = false,
  }) {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    if (s.submissionAction != TransactionFormSubmissionAction.none) return;

    // If the user has manually selected a currency, account changes do not
    // re-seed displayCurrency — only selectedAccount changes.
    if (s.currencyTouched) {
      state = s.copyWith(
        selectedAccount: account,
        isDirty: true,
        selectedAccountIsArchived: account.isArchived,
      );
      return;
    }

    final newCurrency = account.currency;
    final currencyChanged = s.displayCurrency?.code != newCurrency.code;
    final hasDestructiveInput =
        s.amountMinorUnits > 0 || _keypad.hasVisibleInput;
    if (currencyChanged &&
        hasDestructiveInput &&
        !clearAmountOnCurrencyChange) {
      // Caller did not opt into clearing — refuse the swap so the
      // widget's confirmation dialog stays the gating step.
      return;
    }
    if (currencyChanged) {
      _keypad = const KeypadState.initial();
      state = _copyWithKeypad(
        s.copyWith(
          selectedAccount: account,
          displayCurrency: newCurrency,
          selectedAccountIsArchived: account.isArchived,
        ),
      );
    } else {
      state = s.copyWith(
        selectedAccount: account,
        displayCurrency: newCurrency,
        isDirty: true,
        selectedAccountIsArchived: account.isArchived,
      );
    }
  }

  /// Picks a currency. When the new currency differs from the current
  /// `displayCurrency` and `amountMinorUnits > 0`, the widget prompts for
  /// confirmation and re-invokes with `clearAmountOnChange: true`.
  ///
  /// On success, `currencyTouched` is set to `true` regardless of whether
  /// the amount was cleared, so subsequent account changes do not re-seed.
  void selectCurrency(Currency currency, {bool clearAmountOnChange = false}) {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    if (s.displayCurrency?.code == currency.code) return;
    final hasDestructiveInput =
        s.amountMinorUnits > 0 || _keypad.hasVisibleInput;
    if (hasDestructiveInput && !clearAmountOnChange) {
      // Refuse until the widget shows the confirm dialog and re-calls with
      // clearAmountOnChange: true.
      return;
    }
    if (clearAmountOnChange) {
      _keypad = const KeypadState.initial();
      state = _copyWithKeypad(
        s.copyWith(displayCurrency: currency, currencyTouched: true),
      );
    } else {
      // Same currency or zero-amount change — no need to clear amount.
      state = s.copyWith(
        displayCurrency: currency,
        currencyTouched: true,
        isDirty: true,
      );
    }
  }

  void setDate(DateTime date) {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized.isAtSameMomentAs(s.date)) return;
    state = s.copyWith(date: normalized, isDirty: true);
  }

  void setMemo(String memo) {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    if (s.memo == memo) return;
    state = s.copyWith(memo: memo, isDirty: true);
  }

  // ---------- Save / delete ----------

  /// Persists the form. Never throws. Returns:
  ///   - `saved(tx)` → the caller pops with `tx`; Home pins the day to
  ///                   `tx.date`.
  ///   - `invalid`   → `canSave` was false (or the state is not `.data`);
  ///                   nothing was written.
  ///   - `failed`    → the repository write failed. `isSaving` is cleared
  ///                   so the AppBar Save button re-enables.
  ///
  /// Only the write can produce `failed`: the exchange-rate dependencies
  /// are read before it and the fetch starts after it, outside the `try`,
  /// so a row that was saved is never reported as failed.
  Future<SaveTransactionOutcome> save() async {
    TransactionFormData? saving;
    final Transaction saved;
    final Future<void> Function()? fetchRate;
    try {
      final current = state;
      if (current is! TransactionFormData || !current.canSave) {
        return const SaveTransactionOutcome.invalid();
      }
      final s = saving = _finishPendingExpression(current);
      state = s.copyWith(isSaving: true);
      final tx = Transaction(
        id: s.editingId ?? 0,
        amountMinorUnits: s.amountMinorUnits,
        currency: s.displayCurrency!,
        categoryId: s.selectedCategory!.id,
        accountId: s.selectedAccount!.id,
        memo: s.memo.isEmpty ? null : s.memo,
        amountFormula: _keypad.formula(decimals: s.displayCurrency!.decimals),
        date: s.date,
        createdAt: s.originalCreatedAt ?? s.date,
        updatedAt: s.date,
      );
      final repo = ref.read(transactionRepositoryProvider);

      // On-demand exchange-rate fetch for non-default-currency transactions.
      // Its dependencies are read now, before the await; it fires right
      // after the save without blocking the navigation path back to the
      // caller.
      final initialDefault = ref.read(initialDefaultCurrencyProvider);
      final currentDefault =
          ref.read(defaultCurrencyProvider).value ?? initialDefault;
      if (tx.currency.code != currentDefault) {
        final rateRepo = ref.read(exchangeRateRepositoryProvider);
        fetchRate = () => rateRepo.fetchRate(tx.currency.code, currentDefault);
      } else {
        fetchRate = null;
      }

      saved = await repo.save(tx);
    } catch (e) {
      // Restore the editable state; the widget shows
      // `txSaveFailedSnackbar`. `.error` stays reserved for hydration
      // failures (Wave 2 §9.5).
      debugPrint('[TransactionFormController] save failed: ${e.runtimeType}');
      final s = saving;
      if (s != null && ref.mounted) state = s.copyWith(isSaving: false);
      return const SaveTransactionOutcome.failed();
    }

    if (fetchRate != null) unawaited(fetchRate());
    // Clear isSaving on the path back to the widget; pop occurs in
    // the screen layer so navigation stays widget-owned.
    if (ref.mounted) state = saving.copyWith(isSaving: false);
    return SaveTransactionOutcome.saved(saved);
  }

  /// Edit-mode delete. Never throws. Returns:
  ///   - `deleted`  → row removed; widget pops with `null`.
  ///   - `notFound` → row was already gone; widget surfaces a recoverable
  ///                  not-found message and pops back to Home.
  ///   - `ignored`  → not in Edit mode, or a save/delete is in flight.
  ///   - `failed`   → the repository delete failed; `isDeleting` is
  ///                  cleared and the widget keeps the form open.
  Future<DeleteTransactionOutcome> deleteExisting() async {
    TransactionFormData? deleting;
    try {
      final s = state;
      if (s is! TransactionFormData || s.isSaving || s.isDeleting) {
        return const DeleteTransactionOutcome.ignored();
      }
      final id = s.editingId;
      if (id == null) return const DeleteTransactionOutcome.ignored();
      final repo = ref.read(transactionRepositoryProvider);
      deleting = s;
      state = s.copyWith(isDeleting: true);
      final removed = await repo.delete(id);
      if (ref.mounted) state = s.copyWith(isDeleting: false);
      return removed
          ? const DeleteTransactionOutcome.deleted()
          : const DeleteTransactionOutcome.notFound();
    } catch (e) {
      debugPrint(
        '[TransactionFormController] deleteExisting failed: ${e.runtimeType}',
      );
      final s = deleting;
      if (s != null && ref.mounted) state = s.copyWith(isDeleting: false);
      return const DeleteTransactionOutcome.failed();
    }
  }

  /// Saves the current form snapshot as a shopping-list draft. Never
  /// throws.
  ///
  /// In [AddTransactionMode]: calls `ShoppingListRepository.insert(...)` and
  /// returns `ok(ShoppingListEditResultAddedToList)`; the screen closes the
  /// form with `null` (no transaction result).
  ///
  /// In [EditShoppingListDraftMode]: calls `ShoppingListRepository.update(...)`
  /// and returns `ok(ShoppingListEditResultSavedDraft)` to the screen for
  /// popping.
  ///
  /// Returns `ignored` when `canSaveDraft` is false or a submission is
  /// already in flight, and `failed` on repository failure after resetting
  /// `submissionAction` to `none`.
  Future<DraftSubmissionOutcome> saveDraft() async {
    TransactionFormData? submitting;
    try {
      final current = state;
      if (current is! TransactionFormData || !current.canSaveDraft) {
        return const DraftSubmissionOutcome.ignored();
      }
      final s = submitting = _finishPendingExpression(current);
      final slRepo = ref.read(shoppingListRepositoryProvider);
      state = s.copyWith(
        submissionAction: TransactionFormSubmissionAction.saveDraft,
      );
      final draftAmount = s.amountMinorUnits > 0 ? s.amountMinorUnits : null;
      final draftCurrency = s.amountMinorUnits > 0
          ? s.displayCurrency?.code
          : null;

      final ShoppingListEditResult result;
      if (s.shoppingListItemId != null) {
        // Edit mode: update the existing draft row.
        final updatedItem = ShoppingListItem(
          id: s.shoppingListItemId!,
          categoryId: s.selectedCategory!.id,
          accountId: s.selectedAccount!.id,
          memo: s.memo.isEmpty ? null : s.memo,
          draftAmountMinorUnits: draftAmount,
          draftCurrencyCode: draftCurrency,
          draftDate: s.date,
          // createdAt / updatedAt are managed by the repository.
          createdAt: DateTime.utc(0),
          updatedAt: DateTime.utc(0),
        );
        await slRepo.update(updatedItem);
        result = const ShoppingListEditResultSavedDraft();
      } else {
        // Add mode: insert a new draft row.
        await slRepo.insert(
          categoryId: s.selectedCategory!.id,
          accountId: s.selectedAccount!.id,
          memo: s.memo.isEmpty ? null : s.memo,
          draftAmountMinorUnits: draftAmount,
          draftCurrencyCode: draftCurrency,
          draftDate: s.date,
        );
        // Add mode: signal that the item was added to the list.
        result = const ShoppingListEditResultAddedToList();
      }
      if (ref.mounted) {
        state = s.copyWith(
          submissionAction: TransactionFormSubmissionAction.none,
        );
      }
      return DraftSubmissionOutcome.ok(result);
    } catch (e) {
      debugPrint(
        '[TransactionFormController] saveDraft failed: ${e.runtimeType}',
      );
      final s = submitting;
      if (s != null && ref.mounted) {
        state = s.copyWith(
          submissionAction: TransactionFormSubmissionAction.none,
        );
      }
      return const DraftSubmissionOutcome.failed();
    }
  }

  /// Converts the current shopping-list draft into a real transaction.
  /// Never throws.
  ///
  /// Only available in [EditShoppingListDraftMode]. Calls
  /// `ShoppingListRepository.convertToTransaction(...)` and returns
  /// `ok(ShoppingListEditResultSavedTransaction)` to the screen for popping.
  ///
  /// Returns `ignored` when `canConvertDraft` is false or a submission is
  /// already in flight, and `failed` on repository failure after resetting
  /// `submissionAction` to `none`.
  Future<DraftSubmissionOutcome> convertDraft() async {
    TransactionFormData? submitting;
    try {
      final current = state;
      if (current is! TransactionFormData || !current.canConvertDraft) {
        return const DraftSubmissionOutcome.ignored();
      }
      final itemId = current.shoppingListItemId;
      if (itemId == null) return const DraftSubmissionOutcome.ignored();
      final s = submitting = _finishPendingExpression(current);
      final slRepo = ref.read(shoppingListRepositoryProvider);
      state = s.copyWith(
        submissionAction: TransactionFormSubmissionAction.convertDraft,
      );
      await slRepo.convertToTransaction(
        shoppingListItemId: itemId,
        categoryId: s.selectedCategory!.id,
        accountId: s.selectedAccount!.id,
        currencyCode: s.displayCurrency!.code,
        amountMinorUnits: s.amountMinorUnits,
        date: s.date,
        memo: s.memo.isEmpty ? null : s.memo,
        amountFormula: _keypad.formula(decimals: s.displayCurrency!.decimals),
      );
      if (ref.mounted) {
        state = s.copyWith(
          submissionAction: TransactionFormSubmissionAction.none,
        );
      }
      return const DraftSubmissionOutcome.ok(
        ShoppingListEditResultSavedTransaction(),
      );
    } catch (e) {
      debugPrint(
        '[TransactionFormController] convertDraft failed: ${e.runtimeType}',
      );
      final s = submitting;
      if (s != null && ref.mounted) {
        state = s.copyWith(
          submissionAction: TransactionFormSubmissionAction.none,
        );
      }
      return const DraftSubmissionOutcome.failed();
    }
  }

  /// Decides, BEFORE the picker opens, whether it is even useful (Wave 2
  /// §7.1). Never throws. The picker lists expense and income categories
  /// together (the category sets the transaction type), so if neither type
  /// has categories the screen routes straight to /settings/categories
  /// (the picker would just show its empty-state CTA and pop with `null`,
  /// which the screen cannot tell apart from a dismiss).
  Future<CategoryChipTapOutcome> resolveCategoryChipTap() async {
    final subs = <ProviderSubscription<Future<List<Category>>>>[];
    try {
      // Hold subscriptions while awaiting: a bare `ref.read(...future)` on
      // this auto-dispose stream provider pauses its stream as soon as the
      // read returns (Riverpod 3), so the future would never complete.
      for (final type in CategoryType.values) {
        subs.add(ref.listen(categoriesByTypeProvider(type).future, (_, _) {}));
      }
      final categories = await Future.wait([
        for (final sub in subs) sub.read(),
      ]);
      return categories.every((c) => c.isEmpty)
          ? const CategoryChipTapOutcome.manageCategories()
          : const CategoryChipTapOutcome.openPicker();
    } catch (e) {
      debugPrint(
        '[TransactionFormController] resolveCategoryChipTap failed: '
        '${e.runtimeType}',
      );
      return const CategoryChipTapOutcome.failed();
    } finally {
      for (final sub in subs) {
        sub.close();
      }
    }
  }

  /// Re-runs the last requested hydration mode after the user returns from
  /// dependency-recovery flows like `/settings/manage-accounts/new`.
  Future<void> retryHydration() => hydrate(_formMode);

  // ---------- Internals ----------

  Future<Account?> _resolveDefaultAccount() async {
    final accountRepo = ref.read(accountRepositoryProvider);
    final prefs = ref.read(userPreferencesRepositoryProvider);
    final preferredId = await prefs.getDefaultAccountId();
    if (preferredId != null) {
      final preferred = await accountRepo.getById(preferredId);
      if (preferred != null && !preferred.isArchived) {
        return preferred;
      }
    }
    final lastUsed = await accountRepo.getLastUsedActiveAccount();
    if (lastUsed != null) return lastUsed;
    final firstActive = await accountRepo.watchAll().first;
    return firstActive.firstOrNull;
  }

  Future<void> _applyDuplicatePrefill({
    required Transaction source,
    required Account account,
    required CategoryRepository categoryRepo,
    required int duplicateSourceId,
  }) async {
    // Resolve category against the live row so an archived source
    // category still renders historically (risk #8).
    final category = await categoryRepo.getById(source.categoryId);
    if (!ref.mounted) return;
    final preservesAmount = source.currency.code == account.currency.code;
    final amountMinorUnits = preservesAmount ? source.amountMinorUnits : 0;
    _keypad = preservesAmount
        ? _keypadForStored(
            source.amountMinorUnits,
            source.amountFormula,
            decimals: account.currency.decimals,
          )
        : const KeypadState.initial();
    _keypadRevision = 0;
    // Wave 2 risk #7 — duplicate prefill must default `date` to today,
    // not carry the source's date.
    // currencyTouched starts false (same as Add): currency seeds from
    // account default; account changes will re-seed currency if the user
    // has not yet manually selected a currency.
    state = TransactionFormState.data(
      formMode: _formMode,
      amountMinorUnits: amountMinorUnits,
      keypad: _keypad,
      selectedAccount: account,
      displayCurrency: account.currency,
      currencyTouched: false,
      selectedCategory: category,
      date: _today(),
      memo: source.memo ?? '',
      isDirty: false,
      isSaving: false,
      isDeleting: false,
      editingId: null,
      duplicateSourceId: duplicateSourceId,
      originalCreatedAt: null,
    );
  }

  /// Rebuilds the keypad for a stored amount. A stored formula is replayed
  /// so the user sees it and can keep editing it. The stored amount stays
  /// authoritative: a formula that no longer parses, or no longer
  /// recalculates to that amount, is ignored.
  static KeypadState _keypadForStored(
    int amountMinorUnits,
    String? formula, {
    required int decimals,
  }) {
    final parsed = formula == null
        ? null
        : parseAmountFormula(formula, decimals: decimals);
    if (parsed != null) {
      final keypad = KeypadState.fromFormula(parsed, decimals: decimals);
      if (keypad.amountMinorUnits == amountMinorUnits) return keypad;
    }
    return KeypadState.fromAmount(amountMinorUnits, decimals: decimals);
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
