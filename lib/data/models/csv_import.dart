import 'package:freezed_annotation/freezed_annotation.dart';

part 'csv_import.freezed.dart';

/// Most data rows one CSV import accepts. Matches the 10k pagination cap
/// in `docs/architecture/data-model.md`; larger files are rejected, never
/// truncated.
const kCsvImportMaxRows = 10000;

/// Why a whole CSV file was rejected.
enum CsvFileErrorKind {
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
