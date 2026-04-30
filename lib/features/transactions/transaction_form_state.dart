// Transaction-form sealed state — Wave 2 §5.
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
// `canSave` is a getter on the union (Freezed `const _();` pattern); it
// returns `false` on every variant except `data` so widgets can read it
// uniformly.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';

part 'transaction_form_state.freezed.dart';

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
    ) =>
      !isSaving &&
          !isDeleting &&
          amountMinorUnits > 0 &&
          selectedAccount != null &&
          selectedCategory != null &&
          displayCurrency != null,
    _ => false,
  };
}
