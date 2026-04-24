// Accounts slice state (plan §3.1).
//
// Freezed sealed union. The Accounts tab is primarily backed by
// `accountRepository.watchAll(includeArchived: true)` composed with
// per-account `watchBalanceMinorUnits(id)` streams, then layered with
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

part 'accounts_state.freezed.dart';

/// Per-row swipe affordance derived by the controller (plan §7).
///
/// - `isReferenced(id) == true` → archive (delete not allowed).
/// - Only one non-archived account remaining → archive blocked; widget
///   renders a disabled affordance with a tooltip.
/// - Unused custom account (no transactions, `opening_balance_minor_units
///   == 0`) → delete.
/// - Archived rows carry `archive` as a no-op placeholder; the widget
///   suppresses swipe actions on archived tiles.
enum AccountRowAffordance { archive, delete, archiveBlocked }

/// View-model pairing a domain [Account] with its derived balance. The
/// widget reads this shape directly — it never re-subscribes to the
/// balance stream itself.
@freezed
abstract class AccountWithBalance with _$AccountWithBalance {
  const factory AccountWithBalance({
    required Account account,
    required int balanceMinorUnits,
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
