// Transaction-form sealed state — Wave 2 §5 / Task 5 shopping-list.
//
// Variants:
//   - `loading`   — initial, before `hydrateFor*` resolves.
//   - `empty`     — recoverable no-account or not-found state. The form
//                   cannot proceed until the user fixes the missing
//                   dependency (create account, or pop back to Home).
//   - `data`      — the live form. Every keypad / picker / save command
//                   maps to a `copyWith` on this variant.
//   - `error`     — irrecoverable hydration / delete failure. Save-action
//                   errors do NOT enter this variant; they keep the form
//                   in `.data` with `isSaving = false` and surface via
//                   `txSaveFailedSnackbar`.
//
// `canSave` / `canSaveDraft` / `canConvertDraft` are getters on the union
// (Freezed `const _();` pattern); they return `false` on every variant
// except `data` so widgets can read them uniformly.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';
import '../../data/models/transaction.dart';

part 'transaction_form_state.freezed.dart';

// ---------------------------------------------------------------------------
// Typed form mode — Task 5 §1
// ---------------------------------------------------------------------------

/// Discriminates which entry point opened the form. The controller reads
/// this to decide which hydration path and which commands to expose; the
/// screen reads it to derive the AppBar title and CTA set.
sealed class TransactionFormMode {
  const TransactionFormMode();
}

/// Standard Add-transaction flow. [initialDate] (optional) seeds the date
/// field from the Home day-nav selection.
class AddTransactionMode extends TransactionFormMode {
  const AddTransactionMode({this.initialDate});

  final DateTime? initialDate;
}

/// Duplicate an existing transaction — prefills amount/category/memo and
/// resets date to today.
class DuplicateTransactionMode extends TransactionFormMode {
  const DuplicateTransactionMode({required this.sourceTransactionId});

  final int sourceTransactionId;
}

/// Edit an existing transaction in place.
class EditTransactionMode extends TransactionFormMode {
  const EditTransactionMode({required this.transactionId});

  final int transactionId;
}

/// Edit a shopping-list draft. Hydrates from the draft row, exposes
/// `saveDraft` and `convertDraft` commands rather than the normal `save`.
class EditShoppingListDraftMode extends TransactionFormMode {
  const EditShoppingListDraftMode({required this.shoppingListItemId});

  final int shoppingListItemId;
}

// ---------------------------------------------------------------------------
// ShoppingListEditResult — Task 5 §2
// ---------------------------------------------------------------------------

/// Result returned when the form is popped from `EditShoppingListDraftMode`.
sealed class ShoppingListEditResult {
  const ShoppingListEditResult();
}

/// The draft was saved (updated) without being converted.
class ShoppingListEditResultSavedDraft extends ShoppingListEditResult {
  const ShoppingListEditResultSavedDraft();
}

/// The draft was converted to a real transaction.
class ShoppingListEditResultSavedTransaction extends ShoppingListEditResult {
  const ShoppingListEditResultSavedTransaction({required this.transaction});

  final Transaction transaction;
}

/// The draft row was not found when the form opened (already deleted).
class ShoppingListEditResultMissingDraft extends ShoppingListEditResult {
  const ShoppingListEditResultMissingDraft();
}

// ---------------------------------------------------------------------------
// Submission-action tracking — Task 5 §3
// ---------------------------------------------------------------------------

/// Tracks which async save command is currently in-flight. `none` means
/// the form is idle; any other value disables all CTAs and shows a progress
/// indicator on the active button.
enum TransactionFormSubmissionAction {
  none,
  saveTransaction,
  saveDraft,
  convertDraft,
}

// ---------------------------------------------------------------------------
// Why the form is in TransactionFormEmpty
// ---------------------------------------------------------------------------

/// Why the form is in [TransactionFormEmpty]. Drives the CTA text and
/// follow-up navigation.
enum TransactionFormEmptyReason {
  /// No active accounts exist. Render the `Create account` CTA per
  /// Wave 2 §6 / PRD → Add/Edit Interaction Rules.
  noActiveAccount,

  /// Edit/duplicate hydration target row was missing — usually deleted
  /// on another screen while the user navigated. Render a recoverable
  /// "transaction not found" message and pop back to Home.
  notFound,

  /// The shopping-list draft id supplied via [EditShoppingListDraftMode]
  /// no longer exists (deleted on another screen). The screen pops with
  /// [ShoppingListEditResultMissingDraft].
  draftNotFound,
}

@freezed
sealed class TransactionFormState with _$TransactionFormState {
  const TransactionFormState._();

  const factory TransactionFormState.loading() = TransactionFormLoading;

  const factory TransactionFormState.empty({
    required TransactionFormEmptyReason reason,
  }) = TransactionFormEmpty;

  const factory TransactionFormState.data({
    /// Keypad-accumulated integer in the active currency's minor units.
    required int amountMinorUnits,

    /// `null` only during `noActiveAccount` recovery flows; in normal
    /// `.data` states an account is always selected.
    required Account? selectedAccount,

    /// The transaction's currency. Seeds from `selectedAccount.currency` on
    /// hydration, but can be independently overridden by the user via the
    /// currency picker. Once the user has made a manual selection,
    /// `currencyTouched` is `true` and account changes no longer re-seed it.
    required Currency? displayCurrency,

    /// `true` once the user has manually selected a currency via the picker.
    /// When `false`, account changes re-seed `displayCurrency` from the
    /// new account's currency. When `true`, `displayCurrency` is user-owned
    /// and account changes only update `selectedAccount`.
    required bool currencyTouched,

    required Category? selectedCategory,

    /// Drives the picker filter before category selection. After a
    /// category is selected, `selectedCategory.type` is the source of
    /// truth; `pendingType` only differs during the confirm-then-clear
    /// flow that swaps types.
    required CategoryType pendingType,

    required DateTime date,

    /// Free-form note. Empty string is valid; nullability is collapsed
    /// to "" so the controller never has to decide between `null` and
    /// `''` on every keystroke.
    required String memo,

    /// Becomes true on the first user-driven mutation after hydration.
    required bool isDirty,

    /// `true` between `save()` await-start and resolution.
    required bool isSaving,

    /// `true` between `deleteExisting()` await-start and resolution.
    required bool isDeleting,

    /// Edit-mode target id. `null` in Add and Duplicate.
    required int? editingId,

    /// Source-id when opened via duplicate. `null` in Add and Edit.
    required int? duplicateSourceId,

    /// Edit-mode original `createdAt`, preserved on update so the
    /// repository contract (`save` keeps stored `createdAt`) is honored
    /// even if the controller round-trips through copyWith.
    required DateTime? originalCreatedAt,

    /// Incremented on every keypad mutation — including expression-only
    /// transitions that leave `amountMinorUnits` unchanged — so Riverpod
    /// rebuilds the form whenever the display state changes.
    @Default(0) int keypadRevision,

    /// Non-null only in [EditShoppingListDraftMode]; stores the id of the
    /// draft being edited so `saveDraft` and `convertDraft` can reference it.
    @Default(null) int? shoppingListItemId,

    /// Tracks which async submission is currently in-flight. Used to
    /// disable all CTAs and show a progress indicator on the active button.
    @Default(TransactionFormSubmissionAction.none)
    TransactionFormSubmissionAction submissionAction,

    /// `true` when the selected account is archived. Only meaningful in
    /// [EditShoppingListDraftMode]; blocks `canConvertDraft`.
    @Default(false) bool selectedAccountIsArchived,

    /// `true` when the selected category is archived. Only meaningful in
    /// [EditShoppingListDraftMode]; blocks `canConvertDraft`.
    @Default(false) bool selectedCategoryIsArchived,
  }) = TransactionFormData;

  const factory TransactionFormState.error(Object error, StackTrace stack) =
      TransactionFormError;

  /// Computed-on-demand validity flag. PRD: amount > 0 AND category AND
  /// account AND displayCurrency, plus no in-flight save/delete.
  bool get canSave => switch (this) {
    TransactionFormData(
      :final amountMinorUnits,
      :final selectedAccount,
      :final selectedCategory,
      :final displayCurrency,
      :final isSaving,
      :final isDeleting,
      :final submissionAction,
    ) =>
      submissionAction == TransactionFormSubmissionAction.none &&
          !isSaving &&
          !isDeleting &&
          amountMinorUnits > 0 &&
          selectedAccount != null &&
          selectedCategory != null &&
          displayCurrency != null,
    _ => false,
  };

  /// True when account + expense category + date are all set.
  /// Amount may be zero — zero-amount drafts are valid.
  ///
  /// Task 5 §8: archived refs do NOT block canSaveDraft.
  bool get canSaveDraft => switch (this) {
    TransactionFormData(
      :final selectedAccount,
      :final selectedCategory,
      :final submissionAction,
    ) =>
      submissionAction == TransactionFormSubmissionAction.none &&
          selectedAccount != null &&
          selectedCategory != null &&
          selectedCategory.type == CategoryType.expense,
    _ => false,
  };

  /// True when canSaveDraft AND amount > 0 AND no archived account/category.
  ///
  /// Task 5 §8: archived refs block canConvertDraft.
  bool get canConvertDraft => switch (this) {
    TransactionFormData(
      :final amountMinorUnits,
      :final selectedAccountIsArchived,
      :final selectedCategoryIsArchived,
    ) =>
      canSaveDraft &&
          amountMinorUnits > 0 &&
          !selectedAccountIsArchived &&
          !selectedCategoryIsArchived,
    _ => false,
  };
}
