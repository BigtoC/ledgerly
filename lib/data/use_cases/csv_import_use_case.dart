// `CsvImportUseCase` — loads a Fortune City CSV export and commits it in
// one Drift transaction.
//
// Lives in `data/use_cases/` because the commit coordinates four
// repositories inside one `db.transaction`, the role
// `RecurringGenerationUseCase` already plays. It also owns the file
// service call, so controllers never import `data/services/`. Never
// logs: rows carry memos and amounts.

import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/utils/color_palette.dart';
import '../../core/utils/csv_import_keys.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/decimal_rounding.dart';
import '../../core/utils/fortune_city_csv_parser.dart';
import '../database/app_database.dart' show AppDatabase;
import '../models/account.dart';
import '../models/account_type.dart';
import '../models/category.dart';
import '../models/csv_import.dart';
import '../models/currency.dart';
import '../models/transaction.dart';
import '../repositories/account_repository.dart';
import '../repositories/account_type_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/currency_repository.dart';
import '../repositories/repository_exceptions.dart';
import '../repositories/transaction_repository.dart';
import '../services/csv_file_service.dart';

/// Duplicate key: `(createdAt unix seconds, amount, currency, memo ?? '')`.
/// Only CSV-derived values, so preview choices never change the result.
typedef _ImportKey = (int, int, String, String);

_ImportKey _keyOf(
  DateTime createdAt,
  int amountMinorUnits,
  String currencyCode,
  String? memo,
) => (
  createdAt.millisecondsSinceEpoch ~/ 1000,
  amountMinorUnits,
  currencyCode,
  memo ?? '',
);

/// Runs [_parseAndValidate] on a worker isolate. Top-level so the closure
/// captures only [bytes] and [currencies], never the database or
/// repositories, which cannot be sent.
Future<({List<CsvImportRow> valid, List<CsvRowError> errors})>
_loadInBackground(Uint8List bytes, Map<String, Currency> currencies) =>
    Isolate.run(() => _parseAndValidate(bytes, currencies));

/// Parses [bytes] and turns rows with an unknown currency or an unusable
/// amount into row errors. Pure, so it can run off the UI isolate.
({List<CsvImportRow> valid, List<CsvRowError> errors}) _parseAndValidate(
  Uint8List bytes,
  Map<String, Currency> currencies,
) {
  final parsed = parseFortuneCityCsv(bytes);
  final errors = [...parsed.errors];
  final valid = <CsvImportRow>[];
  for (final row in parsed.rows) {
    final currency = currencies[row.currencyCode];
    if (currency == null) {
      errors.add(
        CsvRowError(
          lineNumber: row.line,
          reason: CsvRowErrorReason.unknownCurrency,
          currencyCode: row.currencyCode,
        ),
      );
      continue;
    }
    final int amount;
    try {
      amount = decimalStringToMinorUnits(
        row.amountText,
        scale: math.min(2, currency.decimals),
        decimals: currency.decimals,
      );
    } on FormatException {
      errors.add(
        CsvRowError(
          lineNumber: row.line,
          reason: CsvRowErrorReason.invalidAmount,
        ),
      );
      continue;
    }
    if (amount == 0) {
      errors.add(
        CsvRowError(lineNumber: row.line, reason: CsvRowErrorReason.zeroAmount),
      );
      continue;
    }
    valid.add(
      CsvImportRow(
        line: row.line,
        account: row.account,
        category: row.category,
        amountMinorUnits: amount,
        currency: currency,
        recordedAt: row.recordedAt,
        memo: row.memo,
      ),
    );
  }

  return (valid: valid, errors: errors);
}

/// Rows per `insertImported` call in [CsvImportUseCase.commit].
const _kInsertChunk = 1000;

/// Rows per synchronous slice of the duplicate check; it yields to the
/// event loop between slices so a large file doesn't freeze the UI.
const _kDedupChunk = 5000;

class CsvImportUseCase {
  CsvImportUseCase({
    required this.fileService,
    required this.transactionRepo,
    required this.categoryRepo,
    required this.accountRepo,
    required this.accountTypeRepo,
    required this.currencyRepo,
    required this.db,
  });

  final CsvFileService fileService;
  final TransactionRepository transactionRepo;
  final CategoryRepository categoryRepo;
  final AccountRepository accountRepo;
  final AccountTypeRepository accountTypeRepo;
  final CurrencyRepository currencyRepo;
  final AppDatabase db;

  /// Picks a file, parses it, resolves currencies, rounds amounts and drops
  /// rows that already exist. Returns null when the user cancels.
  ///
  /// Throws [CsvFileException] when the file is unusable.
  Future<CsvLoadResult?> pickAndLoad() async {
    final picked = await fileService.pick();
    if (picked == null) return null;

    final currencies = {
      for (final c in await currencyRepo.watchAll(includeTokens: true).first)
        c.code: c,
    };
    final (:valid, :errors) = await _loadInBackground(picked.bytes, currencies);

    final deduped = await _withoutDuplicates(valid);
    errors.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
    return CsvLoadResult(
      fileName: picked.name,
      validRows: valid,
      rowsToImport: deduped.rows,
      duplicateCount: deduped.duplicateCount,
      errors: errors,
    );
  }

  /// Writes [plan] in one transaction: recounts duplicates, creates the
  /// account types, accounts and categories that still have rows, then
  /// inserts the rows sorted by `(createdAt ASC, line DESC)` so ids follow
  /// time. Rows are inserted in chunks inside the one transaction, so the
  /// UI isolate yields between chunks and any failure still rolls
  /// everything back and rethrows.
  ///
  /// [CsvImportPlan.accounts] and [CsvImportPlan.categories] must cover
  /// the value of every row the recount leaves.
  Future<CsvImportResult> commit(CsvImportPlan plan) async {
    // Starting sortOrders for created rows. Read before the transaction;
    // sortOrder only orders lists, so a concurrent write is harmless.
    final types = await accountTypeRepo.watchAll(includeArchived: true).first;
    final accounts = await accountRepo.watchAll(includeArchived: true).first;
    final categories = await categoryRepo.watchAll(includeArchived: true).first;
    var nextTypeSort = types.fold(-1, (m, t) => math.max(m, t.sortOrder)) + 1;
    var nextAccountSort =
        accounts.fold(-1, (m, a) => math.max(m, a.sortOrder ?? -1)) + 1;
    var nextCategorySort =
        categories.fold(-1, (m, c) => math.max(m, c.sortOrder ?? -1)) + 1;

    return db.transaction(() async {
      final deduped = await _withoutDuplicates(plan.rows);
      final rows = deduped.rows;

      // Created rows are shared by every CSV value that normalizes the
      // same way; categories only when the chosen type matches too.
      final createdTypes = <String, int>{};
      final createdAccounts = <(String, int), int>{};
      final createdCategories = <(String, CategoryType), int>{};

      Future<int> createAccount(
        String name,
        int accountTypeId,
        String currencyCode,
      ) async {
        final key = (normalizeImportKey(name), accountTypeId);
        final existing = createdAccounts[key];
        if (existing != null) return existing;
        final currency = await currencyRepo.getByCode(currencyCode);
        if (currency == null) throw CurrencyNotFoundException(currencyCode);
        return createdAccounts[key] = await accountRepo.save(
          Account(
            id: 0,
            name: name,
            accountTypeId: accountTypeId,
            currency: currency,
            sortOrder: nextAccountSort++,
          ),
        );
      }

      final accountIds = <String, int>{};
      for (final value in rows.map((r) => r.account).toSet()) {
        accountIds[value] = switch (_accountResolution(plan, value)) {
          ExistingAccountResolution(:final accountId) => accountId,
          CreateAccountResolution(
            :final name,
            :final accountTypeId,
            :final currencyCode,
          ) =>
            await createAccount(name, accountTypeId, currencyCode),
          CreateTypeAndAccountResolution(:final name, :final currencyCode) =>
            await createAccount(
              name,
              createdTypes[normalizeImportKey(name)] ??= await accountTypeRepo
                  .save(
                    AccountType(
                      id: 0,
                      customName: name,
                      icon: 'wallet',
                      color: CategoryPaletteIndex.neutralVariant70,
                      sortOrder: nextTypeSort++,
                    ),
                  ),
              currencyCode,
            ),
        };
      }

      final categoryIds = <String, int>{};
      final incomeByNote = <String, IncomeByNoteCategoryResolution>{};
      for (final value in rows.map((r) => r.category).toSet()) {
        switch (_categoryResolution(plan, value)) {
          case ExistingCategoryResolution(:final categoryId):
            categoryIds[value] = categoryId;
          case CreateCategoryResolution(:final name, :final type):
            categoryIds[value] =
                createdCategories[(
                  normalizeImportKey(name),
                  type,
                )] ??= (await categoryRepo.save(
                  Category(
                    id: 0,
                    icon: 'category',
                    color: CategoryPaletteIndex.neutralVariant50,
                    type: type,
                    customName: name,
                    sortOrder: nextCategorySort++,
                  ),
                )).id;
          case final IncomeByNoteCategoryResolution resolution:
            incomeByNote[value] = resolution;
        }
      }

      final salaryNotes = plan.salaryNotes.map(normalizeImportKey).toSet();
      int categoryIdFor(CsvImportRow row) {
        final income = incomeByNote[row.category];
        if (income == null) return categoryIds[row.category]!;
        return isSalaryNote(row.memo, salaryNotes)
            ? income.salaryCategoryId
            : income.otherCategoryId;
      }

      final sorted = [...rows]
        ..sort((a, b) {
          final byTime = a.recordedAt.compareTo(b.recordedAt);
          return byTime != 0 ? byTime : b.line.compareTo(a.line);
        });
      var imported = 0;
      for (var i = 0; i < sorted.length; i += _kInsertChunk) {
        imported += await transactionRepo.insertImported([
          for (final row in sorted.sublist(
            i,
            math.min(i + _kInsertChunk, sorted.length),
          ))
            Transaction(
              id: 0,
              amountMinorUnits: row.amountMinorUnits,
              currency: row.currency,
              categoryId: categoryIdFor(row),
              accountId: accountIds[row.account]!,
              date: DateHelpers.startOfDay(row.recordedAt),
              memo: row.memo,
              createdAt: row.recordedAt,
              // Replaced by the repository's clock.
              updatedAt: row.recordedAt,
            ),
        ]);
      }

      return CsvImportResult(
        importedCount: imported,
        duplicateCount: deduped.duplicateCount,
        createdAccountCount: createdAccounts.length,
        createdCategoryCount: createdCategories.length,
        currencyCodes: rows.map((r) => r.currency.code).toSet(),
      );
    });
  }

  /// Multiset dedup: per key, keeps `max(0, countInFile - countInDb)`
  /// rows, dropping the first occurrences in file order.
  Future<({List<CsvImportRow> rows, int duplicateCount})> _withoutDuplicates(
    List<CsvImportRow> rows,
  ) async {
    if (rows.isEmpty) return (rows: rows, duplicateCount: 0);
    var start = rows.first.recordedAt;
    var end = start;
    for (final row in rows) {
      if (row.recordedAt.isBefore(start)) start = row.recordedAt;
      if (row.recordedAt.isAfter(end)) end = row.recordedAt;
    }

    final inDb = <_ImportKey, int>{};
    var i = 0;
    for (final s in await transactionRepo.getImportSignatures(start, end)) {
      if (++i % _kDedupChunk == 0) await Future<void>.delayed(Duration.zero);
      final key = _keyOf(
        s.createdAt,
        s.amountMinorUnits,
        s.currencyCode,
        s.memo,
      );
      inDb[key] = (inDb[key] ?? 0) + 1;
    }

    final kept = <CsvImportRow>[];
    i = 0;
    for (final row in rows) {
      if (++i % _kDedupChunk == 0) await Future<void>.delayed(Duration.zero);
      final key = _keyOf(
        row.recordedAt,
        row.amountMinorUnits,
        row.currency.code,
        row.memo,
      );
      final remaining = inDb[key] ?? 0;
      if (remaining > 0) {
        inDb[key] = remaining - 1;
      } else {
        kept.add(row);
      }
    }
    return (rows: kept, duplicateCount: rows.length - kept.length);
  }

  static AccountResolution _accountResolution(
    CsvImportPlan plan,
    String value,
  ) =>
      plan.accounts[value] ??
      (throw ArgumentError('plan.accounts does not cover every row'));

  static CategoryResolution _categoryResolution(
    CsvImportPlan plan,
    String value,
  ) =>
      plan.categories[value] ??
      (throw ArgumentError('plan.categories does not cover every row'));
}
