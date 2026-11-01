// Accounts slice state (plan §3.1).
//
// Freezed sealed union. The Accounts tab is primarily backed by
// `accountRepository.watchAll(includeArchived: true)` composed with
// per-account `watchBalanceByCurrency(id)` streams (grouped by currency
// code), then layered with
// `userPreferencesRepository.watchDefaultAccountId()`. The controller
// projects all three into a single `Data` variant so the widget never
// aggregates streams in `build()`.
//
// The first-run seed guarantees the DB contains exactly one `Cash`
// account, so there is no top-level `empty` variant — but the `Data`
// variant renders an empty-state CTA when every row is archived
// (plan §4). Per-section archived fold-out lives on `Data.archived`.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/account.dart';
import '../../data/models/account_type.dart';

part 'accounts_state.freezed.dart';

/// Per-row swipe affordance derived by the controller (plan §7).
///
/// - `isReferenced(id) == true` (transactions or active recurring rules)
///   → archive (delete not allowed).
/// - Only one non-archived account remaining → archive blocked; widget
///   renders a disabled affordance with a tooltip.
/// - Unused custom account (no transactions, `opening_balance_minor_units
///   == 0`) → delete.
/// - Archived rows carry `archive` as a no-op placeholder; the widget
///   suppresses swipe actions on archived tiles.
enum AccountRowAffordance { archive, delete, archiveBlocked }

/// View-model pairing a domain [Account] with its derived grouped
/// balances. Keys are uppercase currency codes; values are the net
/// balance in that currency's minor units. Zero-value groups are
/// suppressed by the repository. The widget reads this shape directly —
/// it never re-subscribes to the balance stream itself.
@freezed
abstract class AccountWithBalance with _$AccountWithBalance {
  const factory AccountWithBalance({
    required Account account,
    required Map<String, int> balancesByCurrency,
    required AccountRowAffordance affordance,
  }) = _AccountWithBalance;
}

@freezed
sealed class AccountsState with _$AccountsState {
  /// Pre-first-emission from the underlying account stream.
  const factory AccountsState.loading() = AccountsLoading;

  /// Fully-resolved account list (active + archived) plus the currently
  /// configured default account id.
  const factory AccountsState.data({
    required List<AccountWithBalance> active,
    required List<AccountWithBalance> archived,
    required int? defaultAccountId,
  }) = AccountsData;

  /// Upstream stream failure.
  const factory AccountsState.error(Object error, StackTrace stack) =
      AccountsError;
}

// ---------- Command outcomes ----------
//
// Each command returns one of these instead of throwing; the widget
// switches on it to choose what to show.

/// Result of [AccountsController.setDefault].
@freezed
sealed class SetDefaultAccountOutcome with _$SetDefaultAccountOutcome {
  /// Default changed. The widget shows `manageAccountsSetDefaultSuccess`.
  const factory SetDefaultAccountOutcome.ok() = SetDefaultAccountOk;

  /// The write failed. The widget shows `manageAccountsSetDefaultFailed`.
  const factory SetDefaultAccountOutcome.failed() = SetDefaultAccountFailed;
}

/// Result of [AccountsController.archive].
@freezed
sealed class ArchiveAccountOutcome with _$ArchiveAccountOutcome {
  /// Archived. The widget shows the Undo snackbar.
  const factory ArchiveAccountOutcome.ok() = ArchiveAccountOk;

  /// The account is the current default. The widget shows the
  /// change-default dialog.
  const factory ArchiveAccountOutcome.isDefault() = ArchiveAccountIsDefault;

  /// The account is the only active one. The widget shows
  /// `accountsArchiveLastActiveBlocked`.
  const factory ArchiveAccountOutcome.lastActive() = ArchiveAccountLastActive;

  /// An active recurring rule uses the account. The widget shows
  /// `accountsArchiveRecurringRuleError`.
  const factory ArchiveAccountOutcome.hasActiveRecurringRule() =
      ArchiveAccountHasActiveRecurringRule;

  /// Anything else went wrong. The widget shows `errorSnackbarGeneric`.
  const factory ArchiveAccountOutcome.failed() = ArchiveAccountFailed;
}

/// Result of [AccountsController.unarchive].
@freezed
sealed class UnarchiveAccountOutcome with _$UnarchiveAccountOutcome {
  /// Restored, or the row was already gone. The widget shows nothing.
  const factory UnarchiveAccountOutcome.ok() = UnarchiveAccountOk;

  /// The restore failed. The widget shows `errorSnackbarGeneric`.
  const factory UnarchiveAccountOutcome.failed() = UnarchiveAccountFailed;
}

/// Result of [AccountsController.delete].
@freezed
sealed class DeleteAccountOutcome with _$DeleteAccountOutcome {
  /// Deleted, or the row was already gone. The widget shows nothing.
  const factory DeleteAccountOutcome.ok() = DeleteAccountOk;

  /// The account is the current default. The widget shows the
  /// change-default dialog.
  const factory DeleteAccountOutcome.isDefault() = DeleteAccountIsDefault;

  /// Transactions, recurring rules or shopping-list drafts still use the
  /// account. The widget shows `accountsDeleteInUseError`.
  const factory DeleteAccountOutcome.inUse() = DeleteAccountInUse;

  /// Anything else went wrong. The widget shows `errorSnackbarGeneric`.
  const factory DeleteAccountOutcome.failed() = DeleteAccountFailed;
}

/// Result of [AccountFormActions.save].
@freezed
sealed class SaveAccountOutcome with _$SaveAccountOutcome {
  /// Saved. The form pops with [accountId].
  const factory SaveAccountOutcome.ok(int accountId) = SaveAccountOk;

  /// The edit changes the currency of an account that is already used.
  /// The form shows `accountFormCurrencyLockedError` inline.
  const factory SaveAccountOutcome.currencyLocked() = SaveAccountCurrencyLocked;

  /// Anything else went wrong. The form shows `errorSnackbarGeneric`
  /// inline.
  const factory SaveAccountOutcome.failed() = SaveAccountFailed;
}

/// Result of [AccountTypeCreationActions.create].
@freezed
sealed class CreateAccountTypeOutcome with _$CreateAccountTypeOutcome {
  /// Created. The sheet pops with [accountType].
  const factory CreateAccountTypeOutcome.ok(AccountType accountType) =
      CreateAccountTypeOk;

  /// The insert failed or the new row could not be read back. The sheet
  /// shows `errorSnackbarGeneric` inline.
  const factory CreateAccountTypeOutcome.failed() = CreateAccountTypeFailed;
}
