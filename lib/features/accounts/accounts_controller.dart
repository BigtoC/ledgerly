// Accounts slice controller (plan §3.1, §6, §7).
//
// The controller composes three streams into [AccountsState]:
//   1. `accountRepository.watchAll(includeArchived: true)` — every
//      account row (active + archived).
//   2. `userPreferencesRepository.watchDefaultAccountId()` — the
//      current `default_account_id`.
//   3. For each account, `accountRepository.watchBalanceByCurrency(id)`
//      — per-currency grouped balances (Map<String, int>).
//
// Per-row balance streams are re-subscribed whenever the account set
// changes. Stale subscriptions for removed rows are cancelled. This is
// rxdart `combineLatest` in spirit — we implement it with nested
// `StreamSubscription`s because rxdart is not on the project deps (plan
// §3.1 / PRD dep list). The feature folder must not import Drift
// directly (layer-boundary rules in import_analysis_options.yaml); only
// repositories and domain models flow through here.
//
// Commands: `setDefault`, `archive`, `delete`, `unarchive`. Each returns
// a sealed outcome from `accounts_state.dart` and never throws; the
// widget switches on the outcome to choose a message.

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../domain/models/account.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/repository_exceptions.dart';
import '../../data/repositories/user_preferences_repository.dart';
import 'accounts_state.dart';

part 'accounts_controller.g.dart';

@Riverpod(dependencies: [accountRepository, userPreferencesRepository])
class AccountsController extends _$AccountsController {
  @override
  Stream<AccountsState> build() {
    final accountRepo = ref.watch(accountRepositoryProvider);
    final prefsRepo = ref.watch(userPreferencesRepositoryProvider);

    final composer = _AccountsComposer(
      accountRepo: accountRepo,
      prefs: prefsRepo,
    );
    ref.onDispose(composer.dispose);
    return composer.stream;
  }

  // ---------- Commands ----------

  /// Writes `default_account_id` via `UserPreferencesRepository`. The
  /// accounts stream re-emits via its default-id subscription, so the
  /// badge flips without manual state mutation.
  Future<SetDefaultAccountOutcome> setDefault(int accountId) async {
    try {
      final prefs = ref.read(userPreferencesRepositoryProvider);
      await prefs.setDefaultAccountId(accountId);
      return const SetDefaultAccountOutcome.ok();
    } catch (e) {
      debugPrint('[AccountsController] setDefault failed: ${e.runtimeType}');
      return const SetDefaultAccountOutcome.failed();
    }
  }

  /// Archive an account. Returns `isDefault` for the current default
  /// account, `lastActive` when it is the only active one remaining
  /// (plan §7 invariant), and `hasActiveRecurringRule` when an active
  /// recurring rule still uses it.
  ///
  /// Uses the currently-projected state to count active rows — the
  /// Riverpod stream has the same view the widget does, so the archive
  /// guard matches what the user sees.
  Future<ArchiveAccountOutcome> archive(int accountId) async {
    try {
      final prefs = ref.read(userPreferencesRepositoryProvider);
      final repo = ref.read(accountRepositoryProvider);
      final snapshot = state.value;
      final currentDefault = snapshot is AccountsData
          ? snapshot.defaultAccountId
          : await prefs.getDefaultAccountId();
      if (currentDefault == accountId) {
        return const ArchiveAccountOutcome.isDefault();
      }

      if (snapshot is AccountsData) {
        final activeCount = snapshot.active.length;
        final targetIsActive = snapshot.active.any(
          (r) => r.account.id == accountId,
        );
        if (activeCount <= 1 && targetIsActive) {
          return const ArchiveAccountOutcome.lastActive();
        }
      }
      await repo.archive(accountId);
      return const ArchiveAccountOutcome.ok();
    } on AccountHasRecurringRuleException {
      return const ArchiveAccountOutcome.hasActiveRecurringRule();
    } catch (e) {
      debugPrint('[AccountsController] archive failed: ${e.runtimeType}');
      return const ArchiveAccountOutcome.failed();
    }
  }

  /// Undo an archive (widget calls this from the SnackBar `commonUndo`).
  /// A row that no longer exists has nothing to restore, so that is `ok`
  /// too. The repository is read before the first await, so this works
  /// even when the auto-dispose provider was rebuilt just for this call.
  Future<UnarchiveAccountOutcome> unarchive(int accountId) async {
    try {
      final repo = ref.read(accountRepositoryProvider);
      final existing = await repo.getById(accountId);
      if (existing == null) return const UnarchiveAccountOutcome.ok();
      await repo.save(existing.copyWith(isArchived: false));
      return const UnarchiveAccountOutcome.ok();
    } catch (e) {
      debugPrint('[AccountsController] unarchive failed: ${e.runtimeType}');
      return const UnarchiveAccountOutcome.failed();
    }
  }

  /// Hard-delete a custom, unused account. Returns `isDefault` when the
  /// account is the current default — the widget prompts the user to
  /// pick a new default first (plan §7) — and `inUse` when something
  /// still references it.
  Future<DeleteAccountOutcome> delete(int accountId) async {
    try {
      final repo = ref.read(accountRepositoryProvider);
      final prefs = ref.read(userPreferencesRepositoryProvider);
      final currentDefault = await prefs.getDefaultAccountId();
      if (currentDefault == accountId) {
        return const DeleteAccountOutcome.isDefault();
      }
      await repo.delete(accountId);
      return const DeleteAccountOutcome.ok();
    } on AccountInUseException {
      return const DeleteAccountOutcome.inUse();
    } catch (e) {
      debugPrint('[AccountsController] delete failed: ${e.runtimeType}');
      return const DeleteAccountOutcome.failed();
    }
  }
}

// ---------- Internal stream composition ----------

/// Wires the three upstream streams into a single `AccountsState`
/// stream. Lives as a plain class so `ref.onDispose` can cancel its
/// subscriptions deterministically — `Stream` closures are harder to
/// reason about under riverpod's `keepAlive: false` rebuilds.
class _AccountsComposer {
  _AccountsComposer({required this._accountRepo, required this._prefs}) {
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
  final Map<int, StreamSubscription<Map<String, int>>> _balanceSubs = {};
  final Map<int, StreamSubscription<bool>> _referenceSubs = {};
  final Map<int, Map<String, int>> _balances = {};
  final Map<int, bool> _references = {};

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
    final subs = List<StreamSubscription<Map<String, int>>>.from(
      _balanceSubs.values,
    );
    final referenceSubs = List<StreamSubscription<bool>>.from(
      _referenceSubs.values,
    );
    _balanceSubs.clear();
    _referenceSubs.clear();
    _balances.clear();
    _references.clear();
    for (final sub in subs) {
      await sub.cancel();
    }
    for (final sub in referenceSubs) {
      await sub.cancel();
    }
  }

  Future<void> dispose() async {
    await _stop();
    await _out.close();
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
      _referenceSubs.remove(id)?.cancel();
      _balances.remove(id);
      _references.remove(id);
    }

    for (final a in rows) {
      if (_balanceSubs.containsKey(a.id)) continue;
      _balanceSubs[a.id] = _accountRepo
          .watchBalanceByCurrency(a.id)
          .listen((balance) => _onBalance(a.id, balance), onError: _onError);
      _referenceSubs[a.id] = _accountRepo
          .watchIsReferenced(a.id)
          .listen(
            (isReferenced) => _onReference(a.id, isReferenced),
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

  void _onBalance(int accountId, Map<String, int> balance) {
    _balances[accountId] = balance;
    _emitIfReady();
  }

  void _onReference(int accountId, bool isReferenced) {
    _references[accountId] = isReferenced;
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
      if (!_references.containsKey(a.id)) return;
    }

    final active = <AccountWithBalance>[];
    final archived = <AccountWithBalance>[];
    final activeCount = _accounts.where((a) => !a.isArchived).length;

    for (final a in _sortForDisplay(_accounts)) {
      final balance = _balances[a.id]!;
      final affordance = _affordance(a, activeCount, _references[a.id]!);
      final view = AccountWithBalance(
        account: a,
        balancesByCurrency: balance,
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

  AccountRowAffordance _affordance(
    Account a,
    int activeCount,
    bool isReferenced,
  ) {
    if (a.isArchived) return AccountRowAffordance.archive;
    // Single active row — archive blocked regardless of references.
    if (activeCount <= 1) return AccountRowAffordance.archiveBlocked;
    // Truthful affordance: only unreferenced zero-opening accounts may
    // hard-delete; referenced rows always archive.
    if (!isReferenced && a.openingBalanceMinorUnits == 0) {
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
        return sa.compareTo(sb);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return copy;
  }
}
