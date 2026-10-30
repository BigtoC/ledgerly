import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../../data/models/csv_import.dart';

/// Header names in a Fortune City (記帳城市) CSV export. Matched after
/// trimming, exactly and case-sensitively; column order does not matter
/// and extra columns are ignored. `Account ID` is never read.
const kFortuneCityAccountColumn = 'Account';
const kFortuneCityCategoryColumn = 'Category';
const kFortuneCityAmountColumn = 'Amount';
const kFortuneCityCurrencyColumn = 'Currency';
const kFortuneCityRecordedAtColumn = 'Recorded At';
const kFortuneCityNoteColumn = 'note';

const _requiredColumns = [
  kFortuneCityAccountColumn,
  kFortuneCityCategoryColumn,
  kFortuneCityAmountColumn,
  kFortuneCityCurrencyColumn,
  kFortuneCityRecordedAtColumn,
];

final _recordedAtPattern = RegExp(
  r'^(\d{4})/(\d{1,2})/(\d{1,2}) (\d{1,2}):(\d{2})(?::(\d{2}))?$',
);

/// Parses the bytes of a Fortune City CSV export.
///
/// Covers UTF-8 decoding, line endings, CSV decoding, line numbering, the
/// header and per-row syntax (blank account / category, Recorded At).
/// Amounts and currency codes are trimmed but not validated: rounding and
/// the currency lookup need the database, so the caller does both.
///
/// Throws [CsvFileException] when the whole file is unusable. Pure and
/// synchronous; never logs.
FortuneCityCsvParseResult parseFortuneCityCsv(Uint8List bytes) {
  final String decoded;
  try {
    decoded = utf8.decode(bytes);
  } on FormatException {
    throw const CsvFileException(CsvFileErrorKind.notUtf8);
  }
  final text = decoded.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  // `csv` never throws: an unterminated quoted field, or a stray character
  // after its closing quote (`"a" ,`), silently swallows later rows into
  // one field. A `"` inside an unquoted field (`12" pizza`) is a literal,
  // which `csv` decodes correctly.
  if (!_quotedFieldsAreClosed(text)) {
    throw const CsvFileException(CsvFileErrorKind.parse);
  }

  // The decoder strips a leading BOM itself. Empty lines stay in the
  // output so line numbers can count them.
  final records = Csv(
    fieldDelimiter: ',',
    autoDetect: false,
    skipEmptyLines: false,
    dynamicTyping: false,
  ).decode(text);
  if (records.isEmpty || _isBlank(records.first)) {
    throw const CsvFileException(CsvFileErrorKind.empty);
  }

  final columns = <String, int>{};
  final header = records.first;
  for (var i = 0; i < header.length; i++) {
    columns.putIfAbsent(header[i].toString().trim(), () => i);
  }
  final missing = [
    for (final name in _requiredColumns)
      if (!columns.containsKey(name)) name,
  ];
  if (missing.isNotEmpty) {
    throw CsvFileException(
      CsvFileErrorKind.missingColumns,
      missingColumns: missing,
    );
  }
  final account = columns[kFortuneCityAccountColumn]!;
  final category = columns[kFortuneCityCategoryColumn]!;
  final amount = columns[kFortuneCityAmountColumn]!;
  final currency = columns[kFortuneCityCurrencyColumn]!;
  final recordedAt = columns[kFortuneCityRecordedAtColumn]!;
  final note = columns[kFortuneCityNoteColumn];
  final lastRequired = [
    account,
    category,
    amount,
    currency,
    recordedAt,
  ].reduce((a, b) => a > b ? a : b);

  final rows = <ParsedCsvRow>[];
  final errors = <CsvRowError>[];
  var dataRows = 0;
  var line = 1 + _newlines(header);
  for (final record in records.skip(1)) {
    final lineNumber = ++line;
    line += _newlines(record);
    if (_isBlank(record)) continue;
    if (++dataRows > kCsvImportMaxRows) {
      throw const CsvFileException(CsvFileErrorKind.tooManyRows);
    }

    final fields = [for (final f in record) f.toString()];
    if (fields.length <= lastRequired) {
      errors.add(
        CsvRowError(
          lineNumber: lineNumber,
          reason: CsvRowErrorReason.columnCount,
        ),
      );
      continue;
    }
    final date = _parseRecordedAt(fields[recordedAt].trim());
    final reason = fields[account].trim().isEmpty
        ? CsvRowErrorReason.emptyAccount
        : fields[category].trim().isEmpty
        ? CsvRowErrorReason.emptyCategory
        : date == null
        ? CsvRowErrorReason.invalidDate
        : null;
    if (reason != null) {
      errors.add(CsvRowError(lineNumber: lineNumber, reason: reason));
      continue;
    }

    final memo = note != null && note < fields.length ? fields[note] : null;
    rows.add(
      ParsedCsvRow(
        line: lineNumber,
        account: fields[account].trim(),
        category: fields[category].trim(),
        amountText: fields[amount].trim(),
        currencyCode: fields[currency].trim().toUpperCase(),
        recordedAt: date!,
        memo: memo == null || memo.trim().isEmpty ? null : memo,
      ),
    );
  }
  if (dataRows == 0) {
    throw const CsvFileException(CsvFileErrorKind.empty);
  }
  return FortuneCityCsvParseResult(rows: rows, errors: errors);
}

/// Whether every quoted field in [text] is closed, and its closing quote is
/// followed by `,`, `\n` or the end of the text. A `"` opens a quoted field
/// only at the start of a field; inside one, `""` is an escaped quote.
bool _quotedFieldsAreClosed(String text) {
  const quote = 0x22, comma = 0x2C, newline = 0x0A;
  var fieldStart = true;
  // The decoder strips a leading BOM, so the first field starts after it.
  for (var i = text.startsWith('\uFEFF') ? 1 : 0; i < text.length; i++) {
    final c = text.codeUnitAt(i);
    if (fieldStart && c == quote) {
      // Find the closing quote, stepping over `""` escapes.
      var close = text.indexOf('"', i + 1);
      while (close != -1 &&
          close + 1 < text.length &&
          text.codeUnitAt(close + 1) == quote) {
        close = text.indexOf('"', close + 2);
      }
      if (close == -1) return false;
      // Step onto the delimiter after the field; the next field follows it.
      i = close + 1;
      if (i < text.length &&
          text.codeUnitAt(i) != comma &&
          text.codeUnitAt(i) != newline) {
        return false;
      }
      fieldStart = true;
      continue;
    }
    fieldStart = c == comma || c == newline;
  }
  return true;
}

bool _isBlank(List<dynamic> record) =>
    record.every((f) => f.toString().trim().isEmpty);

/// Line breaks inside quoted fields, which push later rows down.
int _newlines(List<dynamic> record) =>
    record.fold(0, (n, f) => n + '\n'.allMatches(f.toString()).length);

/// Parses `yyyy/M/d H:mm[:ss]` as device-local time, or returns null when
/// the text does not match or names no real time (e.g. `2026/02/30`).
DateTime? _parseRecordedAt(String text) {
  final match = _recordedAtPattern.firstMatch(text);
  if (match == null) return null;
  final parts = [for (var i = 1; i <= 6; i++) int.parse(match[i] ?? '0')];
  // UTC has no DST gaps, so a field round-trip only rejects values that
  // are out of range, never a valid wall-clock time.
  final utc = DateTime.utc(
    parts[0],
    parts[1],
    parts[2],
    parts[3],
    parts[4],
    parts[5],
  );
  if (utc.year != parts[0] ||
      utc.month != parts[1] ||
      utc.day != parts[2] ||
      utc.hour != parts[3] ||
      utc.minute != parts[4] ||
      utc.second != parts[5]) {
    return null;
  }
  return DateTime(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
}
