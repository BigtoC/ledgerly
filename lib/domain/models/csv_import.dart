import 'package:freezed_annotation/freezed_annotation.dart';

import 'category.dart';
import 'currency.dart';

part 'csv_import.freezed.dart';

/// Why a whole CSV file was rejected.
enum CsvFileErrorKind {
  /// The bytes are not valid UTF-8.
  notUtf8,

  /// No header, or no data rows after skipping blank lines.
  empty,

  /// A required header is missing; see [CsvFileException.missingColumns].
  missingColumns,

  /// The text cannot be CSV (an unpaired `"`).
  parse,

  /// Reading the file or the data to match it against failed.
  readFailed,

  /// The commit failed and rolled back; nothing was imported.
  commitFailed,
}

/// A file-level CSV import failure. Nothing is imported.
///
/// Carries no file contents, so it is safe to log by `runtimeType`.
class CsvFileException implements Exception {
  const CsvFileException(this.kind, {this.missingColumns = const []});

  final CsvFileErrorKind kind;

  /// Required header names that were not found, for
  /// [CsvFileErrorKind.missingColumns]; empty otherwise.
  final List<String> missingColumns;

  @override
  String toString() => 'CsvFileException: ${kind.name}';
}

/// Why a single CSV row is skipped.
enum CsvRowErrorReason {
  /// Fewer fields than the last required column needs.
  columnCount,
  emptyAccount,
  emptyCategory,

  /// Amount is not a plain decimal, or overflows the minor-units range.
  invalidAmount,

  /// Amount rounds to zero.
  zeroAmount,

  /// Currency is not in `currencies`; see [CsvRowError.currencyCode].
  unknownCurrency,

  /// Recorded At is not `yyyy/M/d H:mm[:ss]`, or a Ledgerly `date` or
  /// `created_at` is not ISO 8601, or the value names no real time.
  invalidDate,

  /// A Ledgerly `type` is neither `expense` nor `income`.
  invalidType,
}

/// A skipped row. Holds the line number and reason only, never field
/// values, so the preview and logs stay free of memos and amounts.
@freezed
abstract class CsvRowError with _$CsvRowError {
  const factory CsvRowError({
    /// 1-based physical line in the file; the header is line 1.
    required int lineNumber,
    required CsvRowErrorReason reason,

    /// The unknown code, for [CsvRowErrorReason.unknownCurrency]; null
    /// otherwise.
    String? currencyCode,
  }) = _CsvRowError;
}

/// One syntactically valid Fortune City or Ledgerly row, before currency
/// lookup and rounding (both need the database).
@freezed
abstract class ParsedCsvRow with _$ParsedCsvRow {
  const factory ParsedCsvRow({
    /// 1-based physical line where the row starts.
    required int line,

    /// Trimmed, non-empty.
    required String account,

    /// Trimmed, non-empty.
    required String category,

    /// Trimmed, unvalidated amount text.
    required String amountText,

    /// Trimmed and upper-cased, unvalidated currency code.
    required String currencyCode,

    /// Recorded At (Ledgerly: `created_at`) as device-local time.
    required DateTime recordedAt,

    /// The note verbatim, or null when it is missing or blank.
    String? memo,

    /// Ledgerly only: the category type. Null for Fortune City.
    CategoryType? type,

    /// Ledgerly only: the `date` column's calendar day, at local midnight.
    /// Null for Fortune City, whose date is Recorded At's day.
    DateTime? date,
  }) = _ParsedCsvRow;
}

/// Output of `parseImportCsv`: the valid rows in file order plus one
/// error per skipped row.
@freezed
abstract class CsvParseResult with _$CsvParseResult {
  const factory CsvParseResult({
    required List<ParsedCsvRow> rows,
    required List<CsvRowError> errors,
  }) = _CsvParseResult;
}

/// A CSV Category value plus, for Ledgerly rows, the type the file gives
/// it. Keys [CsvImportPlan.categories]: one Ledgerly value can name both
/// an expense and an income category (English "Investment").
typedef CsvCategoryKey = ({String value, CategoryType? type});

/// A valid row ready to import: currency resolved and amount rounded.
@freezed
abstract class CsvImportRow with _$CsvImportRow {
  const CsvImportRow._();

  const factory CsvImportRow({
    /// 1-based physical line where the row starts.
    required int line,

    /// Trimmed CSV Account value; keys [CsvImportPlan.accounts].
    required String account,

    /// Trimmed CSV Category value; see [categoryKey].
    required String category,

    /// Rounded half-up (Fortune City to at most 2 decimals, Ledgerly to
    /// the currency's), always > 0.
    required int amountMinorUnits,
    required Currency currency,

    /// Recorded At (Ledgerly: `created_at`) as device-local time.
    /// Becomes `createdAt`, and its day becomes `date` unless [date] is set.
    required DateTime recordedAt,
    String? memo,

    /// See [ParsedCsvRow.type]; null for Fortune City.
    CategoryType? type,

    /// See [ParsedCsvRow.date]; null for Fortune City.
    DateTime? date,
  }) = _CsvImportRow;

  CsvCategoryKey get categoryKey => (value: category, type: type);
}

/// Output of loading a file.
@freezed
abstract class CsvLoadResult with _$CsvLoadResult {
  const factory CsvLoadResult({
    required String fileName,

    /// Every valid row in file order, duplicates included. Becomes
    /// [CsvImportPlan.rows], so the commit can recount duplicates.
    required List<CsvImportRow> validRows,

    /// The valid rows not already in the database. Matching and the
    /// preview use these.
    required List<CsvImportRow> rowsToImport,

    /// Skipped rows, sorted by line.
    required List<CsvRowError> errors,
  }) = _CsvLoadResult;
}

/// Where the rows of one CSV Account value go.
@freezed
sealed class AccountResolution with _$AccountResolution {
  /// An account that already exists (active or archived).
  const factory AccountResolution.existing(int accountId) =
      ExistingAccountResolution;

  /// A new account [name] of the existing type [accountTypeId].
  const factory AccountResolution.createAccount({
    required String name,
    required int accountTypeId,
    required String currencyCode,
  }) = CreateAccountResolution;

  /// A new account type named [name] plus an account [name] of that type.
  const factory AccountResolution.createTypeAndAccount({
    required String name,
    required String currencyCode,
  }) = CreateTypeAndAccountResolution;
}

/// Where the rows of one CSV Category value go.
@freezed
sealed class CategoryResolution with _$CategoryResolution {
  /// A category that already exists (active or archived).
  const factory CategoryResolution.existing(int categoryId) =
      ExistingCategoryResolution;

  /// A new custom category.
  const factory CategoryResolution.create({
    required String name,
    required CategoryType type,
  }) = CreateCategoryResolution;

  /// Fortune City's income marker (收入): each row goes to
  /// [salaryCategoryId] when its note is a Salary label (see
  /// [CsvImportPlan.salaryNotes]), otherwise to [otherCategoryId].
  const factory CategoryResolution.incomeByNote({
    required int salaryCategoryId,
    required int otherCategoryId,
  }) = IncomeByNoteCategoryResolution;
}

/// Everything the commit needs. [accounts] and [categories] are keyed by
/// [CsvImportRow.account] and [CsvImportRow.categoryKey] and must cover
/// every row the commit's duplicate recount leaves.
@freezed
abstract class CsvImportPlan with _$CsvImportPlan {
  const factory CsvImportPlan({
    /// [CsvLoadResult.validRows], duplicates included: the commit recounts
    /// them against the database.
    required List<CsvImportRow> rows,
    required Map<String, AccountResolution> accounts,
    required Map<CsvCategoryKey, CategoryResolution> categories,

    /// The Salary category's label in every locale. Compared with each
    /// income row's note after trimming and lower-casing both.
    required Set<String> salaryNotes,
  }) = _CsvImportPlan;
}

/// What a commit wrote. Counts come from the commit-time duplicate
/// recount, so they can differ from the preview's.
@freezed
abstract class CsvImportResult with _$CsvImportResult {
  const factory CsvImportResult({
    required int importedCount,
    required int duplicateCount,
    required int createdAccountCount,
    required int createdCategoryCount,

    /// Currency codes of the inserted rows, for the exchange-rate refresh.
    required Set<String> currencyCodes,
  }) = _CsvImportResult;
}
