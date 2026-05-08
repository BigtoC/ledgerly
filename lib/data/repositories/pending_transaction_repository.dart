// `PendingTransactionRepository` — SSOT for `pending_transactions` rows.
//
// MVP exposed `existsForRuleAndDate`, `insert`, `countByRecurringRule` for the
// recurring generation engine. The Pending Approval on Home feature (spec
// 2026-05-08) extends this to a full UI-facing surface: `watchAll`, `approve`,
// `reject`. Drift data classes never leave this file.

import 'dart:developer' as developer;

import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart' as drift;
import '../database/daos/pending_transaction_dao.dart';
import '../models/currency.dart';
import '../models/pending_transaction.dart';
import '../models/transaction.dart';
import 'transaction_repository.dart';

class PendingTransactionRepositoryException implements Exception {
  const PendingTransactionRepositoryException(this.message);
  final String message;
  @override
  String toString() => 'PendingTransactionRepositoryException: $message';
}

abstract class PendingTransactionRepository {
  /// Check if a pending row exists for the given recurring rule + date.
  Future<bool> existsForRuleAndDate(int ruleId, DateTime date);

  /// Insert a new pending row. Returns the new id.
  Future<int> insert({
    required String source,
    required int amountMinorUnits,
    required String currencyCode,
    int? categoryId,
    required int accountId,
    String? memo,
    required DateTime date,
    required DateTime fetchedAt,
    int? recurringRuleId,
  });

  /// Count pending rows for a specific recurring rule.
  Future<int> countByRecurringRule(int ruleId);

  /// Stream all pending rows, ordered by date DESC, id DESC. Rows whose
  /// referenced account or category is archived/missing are filtered out
  /// (the user's recovery path is to un-archive in Settings, after which
  /// the row reappears in the next emission).
  Stream<List<PendingTransaction>> watchAll();

  /// Approve: insert into `transactions` and delete the pending row,
  /// atomically. Throws [PendingTransactionRepositoryException] when:
  ///   - The pending row id does not exist.
  ///   - The pending row has no categoryId (Transaction requires it).
  ///   - The referenced account is archived or missing.
  ///   - The referenced category is archived or missing.
  ///   - The referenced currency code is unregistered.
  Future<Transaction> approve(int pendingId);

  /// Reject: delete the pending row. Idempotent — calling on a missing id
  /// returns without throwing.
  Future<void> reject(int pendingId);
}

final class DriftPendingTransactionRepository
    implements PendingTransactionRepository {
  DriftPendingTransactionRepository(
    this._db, {
    required TransactionRepository txRepo,
  }) : _txRepo = txRepo;

  final drift.AppDatabase _db;
  final TransactionRepository _txRepo;

  PendingTransactionDao get _dao => _db.pendingTransactionDao;

  @override
  Future<bool> existsForRuleAndDate(int ruleId, DateTime date) {
    return _dao.existsForRuleAndDate(ruleId, date);
  }

  @override
  Future<int> insert({
    required String source,
    required int amountMinorUnits,
    required String currencyCode,
    int? categoryId,
    required int accountId,
    String? memo,
    required DateTime date,
    required DateTime fetchedAt,
    int? recurringRuleId,
  }) {
    return _dao.insert(
      drift.PendingTransactionsCompanion(
        source: Value(source),
        amountMinorUnits: Value(amountMinorUnits),
        currency: Value(currencyCode),
        categoryId: categoryId != null
            ? Value(categoryId)
            : const Value.absent(),
        accountId: Value(accountId),
        memo: memo != null ? Value(memo) : const Value.absent(),
        date: Value(date),
        fetchedAt: Value(fetchedAt),
        recurringRuleId: recurringRuleId != null
            ? Value(recurringRuleId)
            : const Value.absent(),
      ),
    );
  }

  @override
  Future<int> countByRecurringRule(int ruleId) {
    return _dao.countByRecurringRule(ruleId);
  }

  @override
  Stream<List<PendingTransaction>> watchAll() {
    return _dao.watchAll().asyncMap(_rowsToDomain);
  }

  @override
  Future<Transaction> approve(int pendingId) async {
    final pending = await _dao.findById(pendingId);
    if (pending == null) {
      throw PendingTransactionRepositoryException(
        'Pending row not found: $pendingId',
      );
    }

    if (pending.categoryId == null) {
      throw PendingTransactionRepositoryException(
        'Pending row $pendingId has no category',
      );
    }

    final account = await _db.accountDao.findById(pending.accountId);
    if (account == null || account.isArchived) {
      throw PendingTransactionRepositoryException(
        'Account archived or missing: ${pending.accountId}',
      );
    }

    final category = await _db.categoryDao.findById(pending.categoryId!);
    if (category == null || category.isArchived) {
      throw PendingTransactionRepositoryException(
        'Category archived or missing: ${pending.categoryId}',
      );
    }

    final byCode = await _resolveCurrencies({pending.currency});
    final currency = byCode[pending.currency];
    if (currency == null) {
      throw PendingTransactionRepositoryException(
        'Currency not registered: ${pending.currency}',
      );
    }

    final tx = Transaction(
      id: 0,
      amountMinorUnits: pending.amountMinorUnits,
      currency: currency,
      categoryId: pending.categoryId!,
      accountId: pending.accountId,
      date: pending.date,
      memo: pending.memo,
      createdAt: DateTime(0),
      updatedAt: DateTime(0),
    );

    return _db.transaction<Transaction>(() async {
      final saved = await _txRepo.save(tx);
      await _dao.rejectRow(pendingId);
      return saved;
    });
  }

  @override
  Future<void> reject(int pendingId) async {
    await _dao.rejectRow(pendingId);
  }

  // ---------- Private mapping ----------

  Future<List<PendingTransaction>> _rowsToDomain(
    List<drift.PendingTransactionRow> rows,
  ) async {
    if (rows.isEmpty) return const [];

    final distinctCodes = {for (final r in rows) r.currency};
    final byCode = await _resolveCurrencies(distinctCodes);

    final distinctAccountIds = {for (final r in rows) r.accountId};
    final distinctCategoryIds = {
      for (final r in rows)
        if (r.categoryId != null) r.categoryId!,
    };
    final accountById = await _accountsByIds(distinctAccountIds);
    final categoryById = await _categoriesByIds(distinctCategoryIds);

    final out = <PendingTransaction>[];
    for (final row in rows) {
      final currency = byCode[row.currency];
      if (currency == null) {
        developer.log(
          'PendingTransactionRepository: dropping row ${row.id} — '
          'currency "${row.currency}" not registered',
          name: 'pending_transaction_repository',
        );
        continue;
      }
      final account = accountById[row.accountId];
      if (account == null || account.isArchived) {
        developer.log(
          'PendingTransactionRepository: hiding row ${row.id} — '
          'account ${row.accountId} is archived or missing',
          name: 'pending_transaction_repository',
        );
        continue;
      }
      if (row.categoryId != null) {
        final category = categoryById[row.categoryId!];
        if (category == null || category.isArchived) {
          developer.log(
            'PendingTransactionRepository: hiding row ${row.id} — '
            'category ${row.categoryId} is archived or missing',
            name: 'pending_transaction_repository',
          );
          continue;
        }
      }
      out.add(
        PendingTransaction(
          id: row.id,
          source: row.source,
          amountMinorUnits: row.amountMinorUnits,
          currency: currency,
          categoryId: row.categoryId,
          accountId: row.accountId,
          memo: row.memo,
          date: row.date,
          fetchedAt: row.fetchedAt,
          recurringRuleId: row.recurringRuleId,
        ),
      );
    }
    return List.unmodifiable(out);
  }

  Future<Map<int, drift.AccountRow>> _accountsByIds(Set<int> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await (_db.select(
      _db.accounts,
    )..where((t) => t.id.isIn(ids.toList()))).get();
    return {for (final r in rows) r.id: r};
  }

  Future<Map<int, drift.CategoryRow>> _categoriesByIds(Set<int> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await (_db.select(
      _db.categories,
    )..where((t) => t.id.isIn(ids.toList()))).get();
    return {for (final r in rows) r.id: r};
  }

  Future<Map<String, Currency>> _resolveCurrencies(Set<String> codes) async {
    if (codes.isEmpty) return const {};
    final rows = await _db.currencyDao.findByCodes(codes.toList());
    return {
      for (final row in rows)
        row.code: Currency(
          code: row.code,
          decimals: row.decimals,
          symbol: row.symbol,
          nameL10nKey: row.nameL10nKey,
          customName: row.customName,
          isToken: row.isToken,
          sortOrder: row.sortOrder,
        ),
    };
  }
}
