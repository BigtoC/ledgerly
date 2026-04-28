// Transaction-form controller — Wave 2 §4.1 / §5 / §6 / §9.
//
// Owns the form's mutable state plus the keypad accumulator, drives all
// three hydration entry points (Add / Duplicate / Edit), and exposes the
// typed commands the screen widget binds to. Every command mutates the
// `_Data` variant via `state = ...`; widgets never call repositories
// directly.
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

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/category_repository.dart';
import 'keypad_state.dart';
import 'transaction_form_state.dart';

part 'transaction_form_controller.g.dart';

enum _HydrationMode { add, duplicate, edit }

@Riverpod(
  dependencies: [
    transactionRepository,
    accountRepository,
    categoryRepository,
    userPreferencesRepository,
  ],
)
class TransactionFormController extends _$TransactionFormController {
  /// Pure-helper accumulator that backs the keypad commands. Kept outside
  /// `TransactionFormState` because every keystroke would otherwise
  /// require a `copyWith` of the helper for no observable widget effect —
  /// the form only renders `amountMinorUnits`, which is mirrored into the
  /// state on each mutation.
  KeypadState _keypad = const KeypadState.initial();
  _HydrationMode _resumeMode = _HydrationMode.add;
  int? _resumeTargetId;
  DateTime? _resumeAddInitialDate;

  @override
  TransactionFormState build() {
    // Hydration is explicit (Wave 2 §10): the screen calls one of the
    // three `hydrateFor*` entry points after reading route extras / path
    // params. `build` only sets up the loading placeholder.
    return const TransactionFormState.loading();
  }

  // ---------- Hydration ----------

  /// Hydrate for the Add flow. When [initialDate] is supplied (e.g.,
  /// from Home's FAB carrying the currently selected day) the form's
  /// `date` field starts at that day instead of today; the value is
  /// normalized to local midnight so it round-trips through `setDate`.
  /// Omitting [initialDate] preserves the prior default of today.
  Future<void> hydrateForAdd({DateTime? initialDate}) async {
    _resumeMode = _HydrationMode.add;
    _resumeTargetId = null;
    _resumeAddInitialDate = initialDate;
    state = const TransactionFormState.loading();
    try {
      final account = await _resolveDefaultAccount();
      if (account == null) {
        state = const TransactionFormState.empty(
          reason: TransactionFormEmptyReason.noActiveAccount,
        );
        return;
      }
      _keypad = const KeypadState.initial();
      state = TransactionFormState.data(
        amountMinorUnits: 0,
        selectedAccount: account,
        displayCurrency: account.currency,
        currencyTouched: false,
        selectedCategory: null,
        pendingType: CategoryType.expense,
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
      state = TransactionFormState.error(e, st);
    }
  }

  Future<void> hydrateForDuplicate(int sourceId) async {
    _resumeMode = _HydrationMode.duplicate;
    _resumeTargetId = sourceId;
    state = const TransactionFormState.loading();
    try {
      final txRepo = ref.read(transactionRepositoryProvider);
      final source = await txRepo.getById(sourceId);
      if (source == null) {
        state = const TransactionFormState.empty(
          reason: TransactionFormEmptyReason.notFound,
        );
        return;
      }
      final accountRepo = ref.read(accountRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final account = await accountRepo.getById(source.accountId);
      if (account == null || account.isArchived) {
        // Source account no longer usable — fall back to the standard
        // default-resolution chain, like an Add hydration but with
        // amount/category/memo prefilled.
        final fallback = await _resolveDefaultAccount();
        if (fallback == null) {
          state = const TransactionFormState.empty(
            reason: TransactionFormEmptyReason.noActiveAccount,
          );
          return;
        }
        await _applyDuplicatePrefill(
          source: source,
          account: fallback,
          categoryRepo: categoryRepo,
          duplicateSourceId: sourceId,
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
      state = TransactionFormState.error(e, st);
    }
  }

  Future<void> hydrateForEdit(int id) async {
    _resumeMode = _HydrationMode.edit;
    _resumeTargetId = id;
    state = const TransactionFormState.loading();
    try {
      final txRepo = ref.read(transactionRepositoryProvider);
      final existing = await txRepo.getById(id);
      if (existing == null) {
        state = const TransactionFormState.empty(
          reason: TransactionFormEmptyReason.notFound,
        );
        return;
      }
      final accountRepo = ref.read(accountRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final account = await accountRepo.getById(existing.accountId);
      if (account == null) {
        state = const TransactionFormState.empty(
          reason: TransactionFormEmptyReason.notFound,
        );
        return;
      }
      final category = await categoryRepo.getById(existing.categoryId);
      _keypad = _keypadFromAmount(
        existing.amountMinorUnits,
        decimals: existing.currency.decimals,
      );
      state = TransactionFormState.data(
        amountMinorUnits: existing.amountMinorUnits,
        selectedAccount: account,
        displayCurrency: existing.currency,
        currencyTouched: true,
        selectedCategory: category,
        pendingType: category?.type ?? CategoryType.expense,
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
      state = TransactionFormState.error(e, st);
    }
  }

  // ---------- Keypad commands ----------

  void appendDigit(int digit) {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    final decimals = s.displayCurrency?.decimals ?? 2;
    _keypad = _keypad.push(digit, decimals: decimals);
    state = s.copyWith(
      amountMinorUnits: _keypad.amountMinorUnits,
      isDirty: true,
    );
  }

  void appendDecimal() {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    final decimals = s.displayCurrency?.decimals ?? 2;
    _keypad = _keypad.pushDecimal(decimals: decimals);
    // amountMinorUnits doesn't change on the decimal press itself, but
    // the visible display string does — bump isDirty so the discard
    // dialog fires if the user decided to abandon the form.
    state = s.copyWith(isDirty: true);
  }

  void backspace() {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    final decimals = s.displayCurrency?.decimals ?? 2;
    _keypad = _keypad.pop(decimals: decimals);
    state = s.copyWith(
      amountMinorUnits: _keypad.amountMinorUnits,
      isDirty: true,
    );
  }

  void clearAmount() {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    _keypad = _keypad.clear();
    state = s.copyWith(amountMinorUnits: 0, isDirty: true);
  }

  /// Read-only accessor for widgets / tests that need to know whether
  /// the decimal-point key should be enabled, or whether the keypad is
  /// currently showing a fractional partial like "1." (no digits after
  /// dot yet).
  KeypadState get keypadSnapshot => _keypad;

  // ---------- Field commands ----------

  void selectCategory(Category category) {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    state = s.copyWith(
      selectedCategory: category,
      pendingType: category.type,
      isDirty: true,
    );
  }

  /// Switches the segmented type control. Allowed only before a category
  /// is selected, or as the second leg of the confirm-then-clear flow
  /// (the widget calls [clearCategoryForTypeChange] first).
  void setPendingType(CategoryType type) {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    if (s.selectedCategory != null && s.selectedCategory!.type != type) {
      // Caller must clear the incompatible category first (Wave 2 §7).
      return;
    }
    if (s.pendingType == type) return;
    state = s.copyWith(pendingType: type, isDirty: true);
  }

  /// Confirm-then-clear leg of the type-swap flow (Wave 2 §7). Drops the
  /// incompatible category and switches `pendingType` to the new value
  /// in a single transition so the chip renders empty immediately.
  void clearCategoryForTypeChange(CategoryType newType) {
    final s = state;
    if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
    state = s.copyWith(
      selectedCategory: null,
      pendingType: newType,
      isDirty: true,
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

    // If the user has manually selected a currency, account changes do not
    // re-seed displayCurrency — only selectedAccount changes.
    if (s.currencyTouched) {
      state = s.copyWith(selectedAccount: account, isDirty: true);
      return;
    }

    final newCurrency = account.currency;
    final currencyChanged = s.displayCurrency?.code != newCurrency.code;
    if (currencyChanged &&
        s.amountMinorUnits > 0 &&
        !clearAmountOnCurrencyChange) {
      // Caller did not opt into clearing — refuse the swap so the
      // widget's confirmation dialog stays the gating step.
      return;
    }
    if (currencyChanged) {
      _keypad = const KeypadState.initial();
      state = s.copyWith(
        selectedAccount: account,
        displayCurrency: newCurrency,
        amountMinorUnits: 0,
        isDirty: true,
      );
    } else {
      state = s.copyWith(
        selectedAccount: account,
        displayCurrency: newCurrency,
        isDirty: true,
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
    final currencyChanged = s.displayCurrency?.code != currency.code;
    if (currencyChanged && s.amountMinorUnits > 0 && !clearAmountOnChange) {
      // Refuse until the widget shows the confirm dialog and re-calls with
      // clearAmountOnChange: true.
      return;
    }
    if (currencyChanged && clearAmountOnChange) {
      _keypad = const KeypadState.initial();
      state = s.copyWith(
        displayCurrency: currency,
        currencyTouched: true,
        amountMinorUnits: 0,
        isDirty: true,
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

  /// Persists the form. Returns the persisted [Transaction] on success
  /// (caller pops with this; Home pins the day to `tx.date`). Returns
  /// `null` and surfaces a re-thrown failure on the caller's await
  /// chain when the repository call fails — `isSaving` is always
  /// cleared before the throw so the AppBar Save button re-enables.
  Future<Transaction?> save() async {
    final s = state;
    if (s is! TransactionFormData) return null;
    if (s.isSaving || s.isDeleting) return null;
    if (!s.canSave) return null;
    state = s.copyWith(isSaving: true);
    try {
      final tx = Transaction(
        id: s.editingId ?? 0,
        amountMinorUnits: s.amountMinorUnits,
        currency: s.displayCurrency!,
        categoryId: s.selectedCategory!.id,
        accountId: s.selectedAccount!.id,
        memo: s.memo.isEmpty ? null : s.memo,
        date: s.date,
        createdAt: s.originalCreatedAt ?? s.date,
        updatedAt: s.date,
      );
      final repo = ref.read(transactionRepositoryProvider);
      final saved = await repo.save(tx);
      // Clear isSaving on the path back to the widget; pop occurs in
      // the screen layer so navigation stays widget-owned.
      state = s.copyWith(isSaving: false);
      return saved;
    } catch (e) {
      // Restore the editable state and let the caller surface the error
      // via `txSaveFailedSnackbar`. Reserving `.error` for hydration
      // failures (Wave 2 §9.5).
      state = s.copyWith(isSaving: false);
      rethrow;
    }
  }

  /// Edit-mode delete. Returns:
  ///   - `true`  → row removed; widget pops with `null`.
  ///   - `false` → row was already gone; widget surfaces a recoverable
  ///               not-found message and pops back to Home.
  Future<bool> deleteExisting() async {
    final s = state;
    if (s is! TransactionFormData) return false;
    if (s.isSaving || s.isDeleting) return false;
    final id = s.editingId;
    if (id == null) return false;
    state = s.copyWith(isDeleting: true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final removed = await repo.delete(id);
      state = s.copyWith(isDeleting: false);
      return removed;
    } catch (e) {
      state = s.copyWith(isDeleting: false);
      rethrow;
    }
  }

  /// Re-runs the last requested hydration mode after the user returns from
  /// dependency-recovery flows like `/accounts/new`.
  Future<void> retryHydration() {
    return switch (_resumeMode) {
      _HydrationMode.add => hydrateForAdd(initialDate: _resumeAddInitialDate),
      _HydrationMode.duplicate => hydrateForDuplicate(_resumeTargetId!),
      _HydrationMode.edit => hydrateForEdit(_resumeTargetId!),
    };
  }

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
    if (firstActive.isEmpty) return null;
    return firstActive.first;
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
    final preservesAmount = source.currency.code == account.currency.code;
    final amountMinorUnits = preservesAmount ? source.amountMinorUnits : 0;
    _keypad = preservesAmount
        ? _keypadFromAmount(
            source.amountMinorUnits,
            decimals: account.currency.decimals,
          )
        : const KeypadState.initial();
    // Wave 2 risk #7 — duplicate prefill must default `date` to today,
    // not carry the source's date.
    // currencyTouched starts false (same as Add): currency seeds from
    // account default; account changes will re-seed currency if the user
    // has not yet manually selected a currency.
    state = TransactionFormState.data(
      amountMinorUnits: amountMinorUnits,
      selectedAccount: account,
      displayCurrency: account.currency,
      currencyTouched: false,
      selectedCategory: category,
      pendingType: category?.type ?? CategoryType.expense,
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

  /// Reconstructs a [KeypadState] from a stored amount so backspace on a
  /// hydrated edit/duplicate value walks back through the visible digits
  /// rather than dropping the whole amount in one press.
  KeypadState _keypadFromAmount(int amountMinorUnits, {required int decimals}) {
    if (amountMinorUnits == 0 || decimals == 0) {
      return KeypadState(
        amountMinorUnits: amountMinorUnits,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
      );
    }
    // If the amount has no fractional part, treat it as integer-mode
    // entry. Otherwise enter fractional mode and assume the user has
    // typed all `decimals` digits — backspace will walk them back.
    final unit = _pow10(decimals);
    final fractionalRemainder = amountMinorUnits % unit;
    if (fractionalRemainder == 0) {
      return KeypadState(
        amountMinorUnits: amountMinorUnits,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
      );
    }
    return KeypadState(
      amountMinorUnits: amountMinorUnits,
      fractionalDigitsEntered: decimals,
      isFractionalMode: true,
    );
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
