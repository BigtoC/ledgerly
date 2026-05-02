// `ShoppingListRepository` — SSOT for `shopping_list_items` rows.
//
// Invariants enforced here (and only here):
//   - Zero-amount pair: `draftAmountMinorUnits` and `draftCurrencyCode` are
//     all-or-nothing. Both must be null or both must be non-null (G-draft-1).
//   - Expense-only: every draft must reference an expense category (G-draft-2).
//   - `createdAt` / `updatedAt` populated by the repository, never by
//     SQL defaults (mirrors TransactionRepository pattern).
//   - `convertToTransaction` is fully atomic inside `_db.transaction(...)`.
//
// **Repository composition exception:**
// `DriftShoppingListRepository` depends on `TransactionRepository` for
// `convertToTransaction`. Both live in the data layer and share the same
// `AppDatabase`. This narrow, documented exception exists only to preserve
// transaction-write invariants in one place (the existing
// `TransactionRepository.save` path). It does NOT permit arbitrary
// cross-repository access beyond this one call.

import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart' as drift;
import '../database/daos/account_dao.dart';
import '../database/daos/category_dao.dart';
import '../database/daos/currency_dao.dart';
import '../database/daos/shopping_list_dao.dart';
import '../models/currency.dart';
import '../models/shopping_list_item.dart';
import '../models/transaction.dart';
import 'transaction_repository.dart';

/// Typed exception for shopping-list repository failures.
///
/// Follows the same `implements Exception` pattern as
/// `CategoryRepositoryException` / `TransactionRepositoryException`.
class ShoppingListRepositoryException implements Exception {
  const ShoppingListRepositoryException(this.message);

  /// Human-readable description.
  final String message;

  @override
  String toString() => 'ShoppingListRepositoryException: $message';
}

/// SSOT for `shopping_list_items`.
abstract class ShoppingListRepository {
  /// Watch all items, newest `created_at` first.
  Stream<List<ShoppingListItem>> watchAll();

  /// One-shot read by id. Returns null when no row matches.
  Future<ShoppingListItem?> getById(int id);

  /// Insert a new shopping-list draft.
  ///
  /// Throws:
  /// - [ShoppingListRepositoryException] when the amount/currency pair is
  ///   inconsistent (one non-null, one null).
  /// - [ShoppingListRepositoryException] when the referenced category is of
  ///   type `'income'` (only expense categories allowed).
  Future<ShoppingListItem> insert({
    required int categoryId,
    required int accountId,
    String? memo,
    int? draftAmountMinorUnits,
    String? draftCurrencyCode,
    required DateTime draftDate,
  });

  /// Update an existing shopping-list draft.
  ///
  /// Throws:
  /// - [ShoppingListRepositoryException] when the amount/currency pair is
  ///   inconsistent.
  /// - [ShoppingListRepositoryException] when the referenced category is of
  ///   type `'income'`.
  Future<ShoppingListItem> update(ShoppingListItem item);

  /// Delete by id. Returns `true` when a row was removed, `false` when
  /// no row matched.
  Future<bool> delete(int id);

  /// Atomically convert a shopping-list draft into a real transaction.
  ///
  /// Contract (all inside a DB transaction):
  ///   1. Confirm the draft row still exists — throws
  ///      [ShoppingListRepositoryException] if missing.
  ///   2. Verify `accountId` exists and is not archived — throws
  ///      [ShoppingListRepositoryException] otherwise.
  ///   3. Verify `categoryId` exists and is not archived — throws
  ///      [ShoppingListRepositoryException] otherwise.
  ///   4. Resolve `currencyCode` via `CurrencyDao` — required for the
  ///      `Transaction` value object.
  ///   5. Call [TransactionRepository.save] to create the real transaction row
  ///      (keeps transaction-write invariants centralized).
  ///   6. Delete the draft; throws [ShoppingListRepositoryException] if 0 rows
  ///      deleted (which aborts the DB transaction).
  ///   7. Return the saved [Transaction].
  Future<Transaction> convertToTransaction({
    required int shoppingListItemId,
    required int categoryId,
    required int accountId,
    required String currencyCode,
    required int amountMinorUnits,
    required DateTime date,
    String? memo,
  });
}

/// Concrete Drift-backed implementation of [ShoppingListRepository].
final class DriftShoppingListRepository implements ShoppingListRepository {
  /// [transactionRepository] is a narrow, documented exception — see file
  /// header for rationale.
  DriftShoppingListRepository(
    this._db,
    this._transactionRepository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final drift.AppDatabase _db;
  final TransactionRepository _transactionRepository;
  final DateTime Function() _clock;

  ShoppingListDao get _shoppingListDao => _db.shoppingListDao;
  CategoryDao get _categoryDao => _db.categoryDao;
  AccountDao get _accountDao => _db.accountDao;
  CurrencyDao get _currencyDao => _db.currencyDao;

  // ---------- Reads ----------

  @override
  Stream<List<ShoppingListItem>> watchAll() {
    return _shoppingListDao.watchAll().map(
      (rows) => rows.map(_toDomain).toList(growable: false),
    );
  }

  @override
  Future<ShoppingListItem?> getById(int id) async {
    final row = await _shoppingListDao.findById(id);
    return row == null ? null : _toDomain(row);
  }

  // ---------- Writes ----------

  @override
  Future<ShoppingListItem> insert({
    required int categoryId,
    required int accountId,
    String? memo,
    int? draftAmountMinorUnits,
    String? draftCurrencyCode,
    required DateTime draftDate,
  }) async {
    _validateAmountCurrencyPair(draftAmountMinorUnits, draftCurrencyCode);
    await _validateExpenseCategory(categoryId);

    final now = _clock();
    final id = await _shoppingListDao.insert(
      drift.ShoppingListItemsCompanion(
        categoryId: Value(categoryId),
        accountId: Value(accountId),
        memo: memo != null ? Value(memo) : const Value.absent(),
        draftAmountMinorUnits: draftAmountMinorUnits != null
            ? Value(draftAmountMinorUnits)
            : const Value.absent(),
        draftCurrencyCode: draftCurrencyCode != null
            ? Value(draftCurrencyCode)
            : const Value.absent(),
        draftDate: Value(draftDate),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    final inserted = await _shoppingListDao.findById(id);
    if (inserted == null) {
      throw const ShoppingListRepositoryException(
        'Inserted shopping-list item disappeared before read-back',
      );
    }
    return _toDomain(inserted);
  }

  @override
  Future<ShoppingListItem> update(ShoppingListItem item) async {
    _validateAmountCurrencyPair(
      item.draftAmountMinorUnits,
      item.draftCurrencyCode,
    );
    await _validateExpenseCategory(item.categoryId);

    // Preserve stored createdAt.
    final stored = await _shoppingListDao.findById(item.id);
    if (stored == null) {
      throw ShoppingListRepositoryException(
        'Shopping-list item ${item.id} not found',
      );
    }

    final now = _clock();
    await _shoppingListDao.updateRow(
      drift.ShoppingListItemsCompanion(
        id: Value(item.id),
        categoryId: Value(item.categoryId),
        accountId: Value(item.accountId),
        memo: Value(item.memo),
        draftAmountMinorUnits: Value(item.draftAmountMinorUnits),
        draftCurrencyCode: Value(item.draftCurrencyCode),
        draftDate: Value(item.draftDate),
        createdAt: Value(stored.createdAt), // Preserve stored createdAt
        updatedAt: Value(now),
      ),
    );

    final updated = await _shoppingListDao.findById(item.id);
    if (updated == null) {
      throw ShoppingListRepositoryException(
        'Shopping-list item ${item.id} disappeared after update',
      );
    }
    return _toDomain(updated);
  }

  @override
  Future<bool> delete(int id) async {
    final removed = await _shoppingListDao.deleteById(id);
    return removed > 0;
  }

  @override
  Future<Transaction> convertToTransaction({
    required int shoppingListItemId,
    required int categoryId,
    required int accountId,
    required String currencyCode,
    required int amountMinorUnits,
    required DateTime date,
    String? memo,
  }) async {
    return _db.transaction<Transaction>(() async {
      // Step 1: Confirm draft exists.
      final draft = await _shoppingListDao.findById(shoppingListItemId);
      if (draft == null) {
        throw ShoppingListRepositoryException(
          'Shopping-list item $shoppingListItemId not found',
        );
      }

      // Step 2: Verify account exists and is not archived.
      final accountRow = await _accountDao.findById(accountId);
      if (accountRow == null || accountRow.isArchived) {
        throw ShoppingListRepositoryException(
          'Account $accountId is missing or archived',
        );
      }

      // Step 3: Verify category exists and is not archived.
      final categoryRow = await _categoryDao.findById(categoryId);
      if (categoryRow == null || categoryRow.isArchived) {
        throw ShoppingListRepositoryException(
          'Category $categoryId is missing or archived',
        );
      }

      // Step 4: Resolve currency for the Transaction value object.
      final currencyRow = await _currencyDao.findByCode(currencyCode);
      if (currencyRow == null) {
        throw ShoppingListRepositoryException(
          'Currency $currencyCode not registered',
        );
      }
      final currency = _currencyFromRow(currencyRow);

      // Step 5: Build the Transaction domain model and save via
      // TransactionRepository (keeps write invariants centralized).
      final tx = Transaction(
        id: 0,
        amountMinorUnits: amountMinorUnits,
        currency: currency,
        categoryId: categoryId,
        accountId: accountId,
        memo: memo,
        date: date,
        createdAt: DateTime.utc(0),
        updatedAt: DateTime.utc(0),
      );
      final savedTx = await _transactionRepository.save(tx);

      // Step 6: Delete the draft.
      final deleted = await _shoppingListDao.deleteById(shoppingListItemId);
      if (deleted == 0) {
        throw const ShoppingListRepositoryException(
          'Draft delete returned 0 rows',
        );
      }

      // Step 7: Return the saved transaction.
      return savedTx;
    });
  }

  // ---------- Validation helpers ----------

  void _validateAmountCurrencyPair(
    int? draftAmountMinorUnits,
    String? draftCurrencyCode,
  ) {
    final hasAmount = draftAmountMinorUnits != null;
    final hasCurrency = draftCurrencyCode != null;
    if (hasAmount != hasCurrency) {
      throw const ShoppingListRepositoryException(
        'draftAmountMinorUnits and draftCurrencyCode must be both null or '
        'both non-null',
      );
    }
  }

  Future<void> _validateExpenseCategory(int categoryId) async {
    final categoryRow = await _categoryDao.findById(categoryId);
    if (categoryRow == null) {
      throw ShoppingListRepositoryException('Category $categoryId not found');
    }
    if (categoryRow.type == 'income') {
      throw ShoppingListRepositoryException(
        'Category $categoryId is an income category; only expense categories '
        'are allowed for shopping-list drafts',
      );
    }
  }

  // ---------- Private mapping ----------

  ShoppingListItem _toDomain(drift.ShoppingListItemRow row) => ShoppingListItem(
    id: row.id,
    categoryId: row.categoryId,
    accountId: row.accountId,
    memo: row.memo,
    draftAmountMinorUnits: row.draftAmountMinorUnits,
    draftCurrencyCode: row.draftCurrencyCode,
    draftDate: row.draftDate,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  Currency _currencyFromRow(drift.Currency row) => Currency(
    code: row.code,
    decimals: row.decimals,
    symbol: row.symbol,
    nameL10nKey: row.nameL10nKey,
    customName: row.customName,
    isToken: row.isToken,
    sortOrder: row.sortOrder,
  );
}
