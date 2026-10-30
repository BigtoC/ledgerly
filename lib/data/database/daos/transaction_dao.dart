import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/transactions_table.dart';

part 'transaction_dao.g.dart';

/// Thin SQL wrapper for `transactions`.
///
/// Business rules (category type-lock checks, archive-vs-delete,
/// created_at/updated_at population) live in `TransactionRepository`
/// (M3). This DAO returns Drift rows only.
@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// Watch transactions whose `date` falls in the half-open range
  /// `[start, end)`, ordered by `date DESC, id DESC`. Backs
  /// `TransactionRepository.watchByDay` — see
  /// `docs/plans/m3-repositories-seed/stream-a-transaction-category.md` §4.
  Stream<List<TransactionRow>> watchInDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(transactions)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Newest-first distinct local-midnight `DateTime`s for days that have
  /// at least one transaction, bounded by `limit`. Backs
  /// `TransactionRepository.watchDaysWithActivity` — see
  /// `docs/plans/m3-repositories-seed/stream-a-transaction-category.md` §4.
  ///
  /// SQL groups by `date(date, 'localtime')` so days are segmented in
  /// the device's local timezone, matching the home screen UX.
  Stream<List<DateTime>> watchDistinctActivityDays({int limit = 365}) {
    final dayExpr = transactions.date
        .modify(const DateTimeModifier.localTime())
        .date;
    final query = selectOnly(transactions, distinct: true)
      ..addColumns([dayExpr])
      ..orderBy([OrderingTerm(expression: dayExpr, mode: OrderingMode.desc)])
      ..limit(limit);
    return query.watch().map(
      (rows) => rows
          .map((r) => r.read(dayExpr)!)
          .map(
            (d) => DateTime(
              int.parse(d.substring(0, 4)),
              int.parse(d.substring(5, 7)),
              int.parse(d.substring(8, 10)),
            ),
          )
          .toList(growable: false),
    );
  }

  /// Watch every transaction for a given account, reverse-chronological,
  /// bounded by `limit`. Backs
  /// `TransactionRepository.watchForAccount` — see
  /// `docs/plans/m3-repositories-seed/stream-a-transaction-category.md` §4.
  Stream<List<TransactionRow>> watchByAccount(
    int accountId, {
    int limit = 200,
  }) {
    return (select(transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  /// Watch every transaction for a given category, reverse-chronological,
  /// bounded by `limit`. Backs
  /// `TransactionRepository.watchForCategory` — see
  /// `docs/plans/m3-repositories-seed/stream-a-transaction-category.md` §4.
  Stream<List<TransactionRow>> watchByCategory(
    int categoryId, {
    int limit = 200,
  }) {
    return (select(transactions)
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  /// Watch transactions whose memo contains [query] (case-insensitive
  /// substring), ordered `date DESC, id DESC`. Memos that are NULL are
  /// excluded (LIKE on NULL never matches).
  /// Empty/whitespace queries short-circuit to `[]` — without this,
  /// `LIKE '%%'` matches every memoed row and would silently dump the
  /// table on a broken deep link.
  Stream<List<TransactionRow>> watchByMemo(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Stream<List<TransactionRow>>.value(const []);
    }
    final like = '%${trimmed.toLowerCase()}%';
    return (select(transactions)
          ..where((t) => t.memo.lower().like(like))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Up to [limit] distinct trimmed memos used in [categoryId], ordered by
  /// when each was last saved (`updated_at DESC`, then `id DESC`), not by
  /// the transaction's `date`: a backfilled entry typed just now ranks
  /// first and a future-dated one does not stay pinned. NULL and blank
  /// memos are excluded. Backs the memo suggestions under the
  /// transaction form's Memo field.
  ///
  /// The window function ranks each memo by its own latest row; a plain
  /// `MAX(updated_at), MAX(id)` would take the id tiebreak from a
  /// different row. Uses `transactions_category_idx`; every memoed row in the
  /// category is ranked before the LIMIT applies.
  ///
  /// One-argument `TRIM` strips only U+0020, so the memo is trimmed with
  /// the same whitespace set as Dart's `String.trim` (tabs, NBSP, the
  /// CJK ideographic space U+3000, ...).
  Stream<List<String>> watchRecentMemosByCategory(
    int categoryId, {
    int? limit,
  }) {
    final query = attachedDatabase.customSelect(
      'SELECT m FROM ('
      'SELECT m, updated_at, id, ROW_NUMBER() OVER ('
      'PARTITION BY m ORDER BY updated_at DESC, id DESC) AS rn '
      'FROM ('
      'SELECT TRIM(memo, char(9, 10, 11, 12, 13, 32, 133, 160, 5760, '
      '8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, '
      '8232, 8233, 8239, 8287, 12288, 65279)) AS m, updated_at, id '
      'FROM transactions '
      'WHERE category_id = ? AND memo IS NOT NULL'
      ") WHERE m <> ''"
      ') WHERE rn = 1 '
      'ORDER BY updated_at DESC, id DESC '
      'LIMIT ?',
      // SQLite treats a negative LIMIT as unbounded.
      variables: [Variable<int>(categoryId), Variable<int>(limit ?? -1)],
      readsFrom: {transactions},
    );
    return query.watch().map(
      (rows) => rows.map((r) => r.read<String>('m')).toList(growable: false),
    );
  }

  /// One-shot read by id (e.g. duplicate flow).
  Future<TransactionRow?> findById(int id) {
    return (select(
      transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new row. Returns the new `id`.
  Future<int> insert(TransactionsCompanion row) {
    return into(transactions).insert(row);
  }

  /// Insert [rows] in list order with one batch, so ids ascend with the
  /// list. Backs `TransactionRepository.insertImported`.
  Future<void> insertBatch(List<TransactionsCompanion> rows) {
    return batch((b) => b.insertAll(transactions, rows));
  }

  /// `(id, created_at, amount_minor_units, currency, memo)` of up to
  /// [limit] rows with `id > afterId` whose `created_at` lies in
  /// `[start, endInclusive]`, in `id` order. Selects only those columns:
  /// CSV import duplicate detection compares nothing else, and the range
  /// can span years of history. Callers page by passing the last `id` as
  /// [afterId]; the rowid keyset keeps each page one primary-key range scan.
  Future<
    List<
      ({
        int id,
        DateTime createdAt,
        int amountMinorUnits,
        String currency,
        String? memo,
      })
    >
  >
  getImportSignatureRows({
    required DateTime start,
    required DateTime endInclusive,
    required int afterId,
    required int limit,
  }) async {
    final query = selectOnly(transactions)
      ..addColumns([
        transactions.id,
        transactions.createdAt,
        transactions.amountMinorUnits,
        transactions.currency,
        transactions.memo,
      ])
      ..where(
        transactions.id.isBiggerThanValue(afterId) &
            transactions.createdAt.isBetweenValues(start, endInclusive),
      )
      ..orderBy([OrderingTerm(expression: transactions.id)])
      ..limit(limit);
    final rows = await query.get();
    return rows
        .map(
          (r) => (
            id: r.read(transactions.id)!,
            createdAt: r.read(transactions.createdAt)!,
            amountMinorUnits: r.read(transactions.amountMinorUnits)!,
            currency: r.read(transactions.currency)!,
            memo: r.read(transactions.memo),
          ),
        )
        .toList(growable: false);
  }

  /// Replace row by PK.
  Future<bool> updateRow(TransactionsCompanion row) {
    return update(transactions).replace(row);
  }

  /// Delete by id. Returns the number of affected rows.
  Future<int> deleteById(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Count transactions referencing the given category. Fuels the M3
  /// category type-lock check.
  Future<int> countByCategory(int categoryId) async {
    final countExp = transactions.id.count();
    final row =
        await (selectOnly(transactions)
              ..addColumns([countExp])
              ..where(transactions.categoryId.equals(categoryId)))
            .getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Count transactions referencing the given account. Fuels the M3
  /// account archive-vs-delete check.
  Future<int> countByAccount(int accountId) async {
    final countExp = transactions.id.count();
    final row =
        await (selectOnly(transactions)
              ..addColumns([countExp])
              ..where(transactions.accountId.equals(accountId)))
            .getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Per `(category_id, currency)` subtotal in `[start, end)`, filtered by
  /// `categories.type`. Emits ONE row per pair so the repository can run
  /// currency conversion before regrouping into final chart slices.
  Stream<List<({int categoryId, String currency, int total})>>
  watchCategoryTotalsInRange({
    required DateTime start,
    required DateTime end,
    required String type,
  }) {
    final query = attachedDatabase.customSelect(
      'SELECT t.category_id AS cat_id, t.currency AS code, '
      'SUM(t.amount_minor_units) AS total '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.date >= ? AND t.date < ? AND c.type = ? '
      'GROUP BY t.category_id, t.currency',
      variables: [
        Variable<DateTime>(start),
        Variable<DateTime>(end),
        Variable<String>(type),
      ],
      readsFrom: {transactions, attachedDatabase.categories},
    );
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => (
              categoryId: r.read<int>('cat_id'),
              currency: r.read<String>('code'),
              total: r.read<int>('total'),
            ),
          )
          .toList(growable: false),
    );
  }

  /// Per `(account_id, currency)` subtotal in `[start, end)`, filtered by
  /// `categories.type`.
  Stream<List<({int accountId, String currency, int total})>>
  watchAccountTotalsInRange({
    required DateTime start,
    required DateTime end,
    required String type,
  }) {
    final query = attachedDatabase.customSelect(
      'SELECT t.account_id AS acct_id, t.currency AS code, '
      'SUM(t.amount_minor_units) AS total '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.date >= ? AND t.date < ? AND c.type = ? '
      'GROUP BY t.account_id, t.currency',
      variables: [
        Variable<DateTime>(start),
        Variable<DateTime>(end),
        Variable<String>(type),
      ],
      readsFrom: {transactions, attachedDatabase.categories},
    );
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => (
              accountId: r.read<int>('acct_id'),
              currency: r.read<String>('code'),
              total: r.read<int>('total'),
            ),
          )
          .toList(growable: false),
    );
  }

  /// Per `currency` total in `[start, end)`, filtered by `categories.type`.
  Stream<List<({String currency, int total})>> watchCurrencyTotalsInRange({
    required DateTime start,
    required DateTime end,
    required String type,
  }) {
    final query = attachedDatabase.customSelect(
      'SELECT t.currency AS code, SUM(t.amount_minor_units) AS total '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.date >= ? AND t.date < ? AND c.type = ? '
      'GROUP BY t.currency',
      variables: [
        Variable<DateTime>(start),
        Variable<DateTime>(end),
        Variable<String>(type),
      ],
      readsFrom: {transactions, attachedDatabase.categories},
    );
    return query.watch().map(
      (rows) => rows
          .map(
            (r) =>
                (currency: r.read<String>('code'), total: r.read<int>('total')),
          )
          .toList(growable: false),
    );
  }

  /// Raw `(date, currency, amount_minor_units)` rows in `[start, end)`
  /// filtered by `categories.type`, ordered by date ascending. Optional
  /// `categoryId` / `accountId` / `currencyCode` parameters apply
  /// additional `AND` predicates — used by the drill-down bar-chart
  /// refilter. All three default to `null` (no extra filter), which keeps
  /// the original behavior bit-for-bit.
  Stream<List<({DateTime date, String currency, int amountMinorUnits})>>
  watchChartRowsInRange({
    required DateTime start,
    required DateTime end,
    required String type,
    int? categoryId,
    int? accountId,
    String? currencyCode,
  }) {
    final buf = StringBuffer(
      'SELECT t.date AS d, t.currency AS code, '
      't.amount_minor_units AS amt '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.date >= ? AND t.date < ? AND c.type = ?',
    );
    final variables = <Variable<Object>>[
      Variable<DateTime>(start),
      Variable<DateTime>(end),
      Variable<String>(type),
    ];
    if (categoryId != null) {
      buf.write(' AND t.category_id = ?');
      variables.add(Variable<int>(categoryId));
    }
    if (accountId != null) {
      buf.write(' AND t.account_id = ?');
      variables.add(Variable<int>(accountId));
    }
    if (currencyCode != null) {
      buf.write(' AND t.currency = ?');
      variables.add(Variable<String>(currencyCode));
    }
    buf.write(' ORDER BY t.date ASC');

    final query = attachedDatabase.customSelect(
      buf.toString(),
      variables: variables,
      readsFrom: {transactions, attachedDatabase.categories},
    );
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => (
              date: r.read<DateTime>('d'),
              currency: r.read<String>('code'),
              amountMinorUnits: r.read<int>('amt'),
            ),
          )
          .toList(growable: false),
    );
  }

  /// Full `TransactionRow` objects in `[start, end)` filtered by
  /// `categories.type` and optional slice predicates. Ordered
  /// `date DESC, id DESC`. Backs the chart drill-down items list — the
  /// repository wraps the rows into `Transaction` domain models. No hard
  /// cap is applied in MVP because the drill-down count must reflect the
  /// full selected slice rather than a silent truncation.
  Stream<List<TransactionRow>> watchTransactionRowsForSliceInRange({
    required DateTime start,
    required DateTime end,
    required String type,
    int? categoryId,
    int? accountId,
    String? currencyCode,
  }) {
    final stmt =
        select(transactions).join([
          innerJoin(
            attachedDatabase.categories,
            attachedDatabase.categories.id.equalsExp(transactions.categoryId),
          ),
        ])..where(
          transactions.date.isBiggerOrEqualValue(start) &
              transactions.date.isSmallerThanValue(end) &
              attachedDatabase.categories.type.equals(type),
        );
    if (categoryId != null) {
      stmt.where(transactions.categoryId.equals(categoryId));
    }
    if (accountId != null) {
      stmt.where(transactions.accountId.equals(accountId));
    }
    if (currencyCode != null) {
      stmt.where(transactions.currency.equals(currencyCode));
    }
    stmt.orderBy([
      OrderingTerm(expression: transactions.date, mode: OrderingMode.desc),
      OrderingTerm(expression: transactions.id, mode: OrderingMode.desc),
    ]);
    return stmt.watch().map(
      (rows) => rows.map((r) => r.readTable(transactions)).toList(),
    );
  }
}
