import 'package:freezed_annotation/freezed_annotation.dart';

import 'category.dart';
import 'currency.dart';

part 'csv_import.freezed.dart';

/// Most data rows one CSV import accepts. Matches the 10k pagination cap
/// in `docs/architecture/data-model.md`; larger files are rejected, never
/// truncated.
const kCsvImportMaxRows = 10000;

/// Why a whole CSV file was rejected.
enum CsvFileErrorKind {
  /// The file is over the 5 MB size cap.
  tooLarge,

  /// The bytes are not valid UTF-8.
  notUtf8,

  /// No header, or no data rows after skipping blank lines.
  empty,

  /// A required header is missing; see [CsvFileException.missingColumns].
  missingColumns,

  /// More than [kCsvImportMaxRows] data rows.
  tooManyRows,

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

  /// Recorded At is not `yyyy/M/d H:mm[:ss]` or names no real time.
  invalidDate,
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

/// One syntactically valid Fortune City row, before currency lookup and
/// rounding (both need the database).
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

    /// Recorded At as device-local time.
    required DateTime recordedAt,

    /// The note verbatim, or null when it is missing or blank.
    String? memo,
  }) = _ParsedCsvRow;
}

/// Output of `parseFortuneCityCsv`: the valid rows in file order plus one
/// error per skipped row.
@freezed
abstract class FortuneCityCsvParseResult with _$FortuneCityCsvParseResult {
  const factory FortuneCityCsvParseResult({
    required List<ParsedCsvRow> rows,
    required List<CsvRowError> errors,
  }) = _FortuneCityCsvParseResult;
}

/// A valid row ready to import: currency resolved and amount rounded.
@freezed
abstract class CsvImportRow with _$CsvImportRow {
  const factory CsvImportRow({
    /// 1-based physical line where the row starts.
    required int line,

    /// Trimmed CSV Account value; keys [CsvImportPlan.accounts].
    required String account,

    /// Trimmed CSV Category value; keys [CsvImportPlan.categories].
    required String category,

    /// Rounded half-up, always > 0.
    required int amountMinorUnits,
    required Currency currency,

    /// Recorded At as device-local time. Becomes `createdAt`; its day
    /// becomes `date`.
    required DateTime recordedAt,
    String? memo,
  }) = _CsvImportRow;
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

    /// `validRows.length - rowsToImport.length`.
    required int duplicateCount,

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
/// [CsvImportRow.account] and [CsvImportRow.category] and must cover every
/// row the commit's duplicate recount leaves.
@freezed
abstract class CsvImportPlan with _$CsvImportPlan {
  const factory CsvImportPlan({
    /// [CsvLoadResult.validRows], duplicates included: the commit recounts
    /// them against the database.
    required List<CsvImportRow> rows,
    required Map<String, AccountResolution> accounts,
    required Map<String, CategoryResolution> categories,

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
