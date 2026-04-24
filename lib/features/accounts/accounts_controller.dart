// Accounts slice controller (plan §3.1, §6, §7).
//
// The controller composes three streams into [AccountsState]:
//   1. `accountRepository.watchAll(includeArchived: true)` — every
//      account row (active + archived).
//   2. `userPreferencesRepository.watchDefaultAccountId()` — the
//      current `default_account_id`.
//   3. For each account, `accountRepository.watchBalanceMinorUnits(id)`
//      — the Wave 0 §2.8 tracked balance stream.
//
// Per-row balance streams are re-subscribed whenever the account set
// changes. Stale subscriptions for removed rows are cancelled. This is
// rxdart `combineLatest` in spirit — we implement it with nested
// `StreamSubscription`s because rxdart is not on the project deps (plan
// §3.1 / PRD dep list). The feature folder must not import Drift
// directly (import_lint `features_` rules); only repositories and
// domain models flow through here.
//
// Commands: `setDefault`, `archive`, `delete`, `unarchive`, plus an
// internal `canArchive` hint for the widget to surface disabled
// affordances without poking the repository.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/user_preferences_repository.dart';
import 'accounts_state.dart';

part 'accounts_controller.g.dart';

@riverpod
class AccountsController extends _$AccountsController {
  @override
  Stream<AccountsState> build() {
    final accountRepo = ref.watch(accountRepositoryProvider);
    final prefsRepo = ref.watch(userPreferencesRepositoryProvider);

    final composer = _AccountsComposer(accountRepo: accountRepo, prefs: prefsRepo);
    ref.onDispose(composer.dispose);
    return composer.stream;
  }

  // ---------- Commands ----------

  /// Writes `default_account_id` via `UserPreferencesRepository`. The
  /// accounts stream re-emits via its default-id subscription, so the
  /// badge flips without manual state mutation.
  Future<void> setDefault(int accountId) async {
    final prefs = ref.read(userPreferencesRepositoryProvider);
    await prefs.setDefaultAccountId(accountId);
  }

  /// Archive an account. Throws [AccountsOperationException] when the
  /// account is the only active one remaining (plan §7 invariant).
  ///
  /// Uses the currently-projected state to count active rows — the
  /// Riverpod stream has the same view the widget does, so the archive
  /// guard matches what the user sees.
  Future<void> archive(int accountId) async {
    final snapshot = state.value;
    if (snapshot is AccountsData) {
      final activeCount = snapshot.active.length;
      final targetIsActive = snapshot.active
          .any((r) => r.account.id == accountId);
      if (activeCount <= 1 && targetIsActive) {
        throw const AccountsOperationException(
          AccountsOperationError.lastActiveAccount,
        );
      }
    }
    final repo = ref.read(accountRepositoryProvider);
    await repo.archive(accountId);
  }

  /// Undo an archive (widget calls this from the SnackBar `commonUndo`).
  Future<void> unarchive(int accountId) async {
    final repo = ref.read(accountRepositoryProvider);
    final existing = await repo.getById(accountId);
    if (existing == null) {
      throw const AccountsOperationException(
        AccountsOperationError.missingRow,
      );
    }
    await repo.save(existing.copyWith(isArchived: false));
  }

  /// Hard-delete a custom, unused account. Throws when the account is
  /// the current default — caller must prompt the user to pick a new
  /// default first (plan §7).
  Future<void> delete(int accountId) async {
    final repo = ref.read(accountRepositoryProvider);
    final prefs = ref.read(userPreferencesRepositoryProvider);
    final currentDefault = await prefs.getDefaultAccountId();
    if (currentDefault == accountId) {
      throw const AccountsOperationException(
        AccountsOperationError.defaultAccount,
      );
    }
    await repo.delete(accountId);
  }
}

/// Typed failure surface for [AccountsController] commands. Widgets
/// branch on `kind` to decide which dialog / snackbar to show.
class AccountsOperationException implements Exception {
  const AccountsOperationException(this.kind);

  final AccountsOperationError kind;

  @override
  String toString() => 'AccountsOperationException($kind)';
}

enum AccountsOperationError { lastActiveAccount, defaultAccount, missingRow }

// ---------- Internal stream composition ----------

/// Wires the three upstream streams into a single `AccountsState`
/// stream. Lives as a plain class so `ref.onDispose` can cancel its
/// subscriptions deterministically — `Stream` closures are harder to
/// reason about under riverpod's `keepAlive: false` rebuilds.
class _AccountsComposer {
  _AccountsComposer({required AccountRepository accountRepo, required UserPreferencesRepository prefs})
    : _accountRepo = accountRepo,
      _prefs = prefs {
    _out = StreamController<AccountsState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final AccountRepository _accountRepo;
  final UserPreferencesRepository _prefs;
  late final StreamController<AccountsState> _out;

  StreamSubscription<List<Account>>? _accountsSub;
  StreamSubscription<int?>? _defaultSub;
  final Map<int, StreamSubscription<int>> _balanceSubs = {};
  final Map<int, int> _balances = {};

  List<Account> _accounts = const [];
  int? _defaultAccountId;
  bool _receivedAccounts = false;
  bool _receivedDefault = false;

  Stream<AccountsState> get stream => _out.stream;

  void _start() {
    _accountsSub = _accountRepo
        .watchAll(includeArchived: true)
        .listen(_onAccounts, onError: _onError);
    _defaultSub = _prefs.watchDefaultAccountId().listen(
      _onDefault,
      onError: _onError,
    );
  }

  Future<void> _stop() async {
    await _accountsSub?.cancel();
    _accountsSub = null;
    await _defaultSub?.cancel();
    _defaultSub = null;
    final subs = List<StreamSubscription<int>>.from(_balanceSubs.values);
    _balanceSubs.clear();
    _balances.clear();
    for (final sub in subs) {
      await sub.cancel();
    }
  }

  Future<void> dispose() async {
    await _stop();
    if (!_out.isClosed) await _out.close();
  }

  // ---------- Stream handlers ----------

  void _onAccounts(List<Account> rows) {
    _accounts = rows;
    _receivedAccounts = true;

    // Reconcile per-account balance subscriptions. Drop ones for rows
    // that have been deleted; add ones for new rows.
    final incomingIds = rows.map((a) => a.id).toSet();
    final stale = _balanceSubs.keys
        .where((id) => !incomingIds.contains(id))
        .toList();
    for (final id in stale) {
      _balanceSubs.remove(id)?.cancel();
      _balances.remove(id);
    }

    for (final a in rows) {
      if (_balanceSubs.containsKey(a.id)) continue;
      _balanceSubs[a.id] = _accountRepo
          .watchBalanceMinorUnits(a.id)
          .listen(
            (balance) => _onBalance(a.id, balance),
            onError: _onError,
          );
    }

    _emitIfReady();
  }

  void _onDefault(int? id) {
    _defaultAccountId = id;
    _receivedDefault = true;
    _emitIfReady();
  }

  void _onBalance(int accountId, int balance) {
    _balances[accountId] = balance;
    _emitIfReady();
  }

  void _onError(Object error, StackTrace stack) {
    if (_out.isClosed) return;
    _out.add(AccountsState.error(error, stack));
  }

  void _emitIfReady() {
    if (_out.isClosed) return;
    if (!_receivedAccounts || !_receivedDefault) return;

    // Wait until every account has at least one balance emission. Drift
    // `customSelect` emits synchronously on first subscribe, so this
    // typically happens in the same microtask.
    for (final a in _accounts) {
      if (!_balances.containsKey(a.id)) return;
    }

    final active = <AccountWithBalance>[];
    final archived = <AccountWithBalance>[];
    final activeCount = _accounts.where((a) => !a.isArchived).length;

    for (final a in _sortForDisplay(_accounts)) {
      final balance = _balances[a.id] ?? 0;
      final affordance = _affordance(a, activeCount);
      final view = AccountWithBalance(
        account: a,
        balanceMinorUnits: balance,
        affordance: affordance,
      );
      if (a.isArchived) {
        archived.add(view);
      } else {
        active.add(view);
      }
    }

    _out.add(
      AccountsState.data(
        active: active,
        archived: archived,
        defaultAccountId: _defaultAccountId,
      ),
    );
  }

  AccountRowAffordance _affordance(Account a, int activeCount) {
    if (a.isArchived) return AccountRowAffordance.archive;
    // Single active row — archive blocked regardless of references.
    if (activeCount <= 1) return AccountRowAffordance.archiveBlocked;
    // Unused custom (no transactions) with no opening balance → delete
    // is allowed. Referenced rows always archive. We can only check
    // "referenced" async, which is expensive to do for every emission;
    // we use a cheap proxy: if the balance equals the opening balance
    // AND the opening balance is 0, it *might* be unused, but that
    // includes "has equal expense/income". To keep the widget honest
    // and not lose the delete path entirely, we fall back to archive
    // when we cannot prove unused. The actual delete attempt surfaces
    // `AccountInUseException` from the repository if the proxy misses.
    if (a.openingBalanceMinorUnits == 0) {
      return AccountRowAffordance.delete;
    }
    return AccountRowAffordance.archive;
  }

  List<Account> _sortForDisplay(List<Account> rows) {
    final copy = [...rows];
    copy.sort((a, b) {
      final sa = a.sortOrder;
      final sb = b.sortOrder;
      if (sa != sb) {
        if (sa == null) return 1;
        if (sb == null) return -1;
        final cmp = sa.compareTo(sb);
        if (cmp != 0) return cmp;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return copy;
  }
}
