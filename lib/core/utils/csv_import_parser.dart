import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/category.dart';
import '../../domain/models/csv_import.dart';

/// Header names in a Fortune City (記帳城市) CSV export. Matched after
/// trimming, exactly and case-sensitively; column order does not matter
/// and extra columns are ignored. `Account ID` is never read.
const kFortuneCityAccountColumn = 'Account';
const kFortuneCityCategoryColumn = 'Category';
const kFortuneCityAmountColumn = 'Amount';
const kFortuneCityCurrencyColumn = 'Currency';
const kFortuneCityRecordedAtColumn = 'Recorded At';
const kFortuneCityNoteColumn = 'note';

const _fortuneCity = (
  account: kFortuneCityAccountColumn,
  category: kFortuneCityCategoryColumn,
  amount: kFortuneCityAmountColumn,
  currency: kFortuneCityCurrencyColumn,
  memo: kFortuneCityNoteColumn,
  required: [
    kFortuneCityAccountColumn,
    kFortuneCityCategoryColumn,
    kFortuneCityAmountColumn,
    kFortuneCityCurrencyColumn,
    kFortuneCityRecordedAtColumn,
  ],
);

/// Header names in Ledgerly's own export (`encodeTransactionsCsv`), matched
/// the same way. `id` is optional and read only when it holds a UUID;
/// `updated_at` is never read.
const _ledgerly = (
  account: 'account',
  category: 'category',
  amount: 'amount',
  currency: 'currency',
  memo: 'memo',
  required: [
    'date',
    'type',
    'amount',
    'currency',
    'category',
    'account',
    'created_at',
  ],
);

final _recordedAtPattern = RegExp(
  r'^(\d{4})/(\d{1,2})/(\d{1,2}) (\d{1,2}):(\d{2})(?::(\d{2}))?$',
);

/// `formatLocalIso8601` output: `YYYY-MM-DDTHH:mm:ss±HH:MM`.
final _iso8601Pattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})([+-])(\d{2}):(\d{2})$',
);

/// The `'` the export puts before text a spreadsheet would run.
final _escapedFormula = RegExp("^'[=+\\-@\t\r]");

/// Parses the bytes of a Fortune City or Ledgerly CSV export. The format
/// is the one whose required columns the header has more of; a tie is
/// Fortune City.
///
/// Covers UTF-8 decoding, line endings, CSV decoding, line numbering, the
/// header and per-row syntax (blank account / category, dates, Ledgerly's
/// `type`). Ledgerly text loses the export's formula-escape `'`. Amounts
/// and currency codes are trimmed but not validated: rounding and the
/// currency lookup need the database, so the caller does both.
///
/// Throws [CsvFileException] when the whole file is unusable. Pure and
/// synchronous; never logs.
CsvParseResult parseImportCsv(Uint8List bytes) {
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
  final ledgerly =
      _ledgerly.required.where(columns.containsKey).length >
      _fortuneCity.required.where(columns.containsKey).length;
  final format = ledgerly ? _ledgerly : _fortuneCity;
  final missing = [
    for (final name in format.required)
      if (!columns.containsKey(name)) name,
  ];
  if (missing.isNotEmpty) {
    throw CsvFileException(
      CsvFileErrorKind.missingColumns,
      missingColumns: missing,
    );
  }
  final note = columns[format.memo];
  final id = ledgerly ? columns['id'] : null;
  final lastRequired = [for (final name in format.required) columns[name]!]
      .reduce((a, b) => a > b ? a : b);

  final rows = <ParsedCsvRow>[];
  final errors = <CsvRowError>[];
  var dataRows = 0;
  var line = 1 + _newlines(header);
  for (final record in records.skip(1)) {
    final lineNumber = ++line;
    line += _newlines(record);
    if (_isBlank(record)) continue;
    dataRows++;

    // Only text fields can start with the escape, so every field is
    // checked.
    final fields = [
      for (final f in record.map((f) => '$f'))
        ledgerly && _escapedFormula.hasMatch(f) ? f.substring(1) : f,
    ];
    if (fields.length <= lastRequired) {
      errors.add(
        CsvRowError(
          lineNumber: lineNumber,
          reason: CsvRowErrorReason.columnCount,
        ),
      );
      continue;
    }
    String field(String name) => fields[columns[name]!].trim();
    final type = ledgerly
        ? CategoryType.values.asNameMap()[field('type')]
        : null;
    final date = ledgerly ? _parseIso8601(field('date')) : null;
    final recordedAt = ledgerly
        ? _parseIso8601(field('created_at'))?.instant
        : _parseRecordedAt(field(kFortuneCityRecordedAtColumn));
    final account = field(format.account);
    final category = field(format.category);
    final reason = account.isEmpty
        ? CsvRowErrorReason.emptyAccount
        : category.isEmpty
        ? CsvRowErrorReason.emptyCategory
        : ledgerly && type == null
        ? CsvRowErrorReason.invalidType
        : recordedAt == null || (ledgerly && date == null)
        ? CsvRowErrorReason.invalidDate
        : null;
    if (reason != null) {
      errors.add(CsvRowError(lineNumber: lineNumber, reason: reason));
      continue;
    }

    final memo = note != null && note < fields.length ? fields[note] : null;
    final uuid = id != null && id < fields.length ? fields[id].trim() : '';
    rows.add(
      ParsedCsvRow(
        line: lineNumber,
        account: account,
        category: category,
        amountText: field(format.amount),
        currencyCode: field(format.currency).toUpperCase(),
        recordedAt: recordedAt!,
        memo: memo == null || memo.trim().isEmpty ? null : memo,
        type: type,
        date: date?.day,
        uuid: Uuid.isValidUUIDFormat(fromString: uuid)
            ? uuid.toLowerCase()
            : null,
      ),
    );
  }
  if (dataRows == 0) {
    throw const CsvFileException(CsvFileErrorKind.empty);
  }
  return CsvParseResult(rows: rows, errors: errors);
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
  final t = _wallTime([
    for (var i = 1; i <= 6; i++) int.parse(match[i] ?? '0'),
  ]);
  return t == null
      ? null
      : DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
}

/// Parses `YYYY-MM-DDTHH:mm:ss±HH:MM` into the written day at local
/// midnight and the instant in local time, or returns null when the text
/// does not match or names no real time.
({DateTime day, DateTime instant})? _parseIso8601(String text) {
  final match = _iso8601Pattern.firstMatch(text);
  if (match == null) return null;
  final t = _wallTime([for (var i = 1; i <= 6; i++) int.parse(match[i]!)]);
  if (t == null) return null;
  final offset = Duration(
    hours: int.parse(match[8]!),
    minutes: int.parse(match[9]!),
  );
  return (
    day: DateTime(t.year, t.month, t.day),
    instant: (match[7] == '-' ? t.add(offset) : t.subtract(offset)).toLocal(),
  );
}

/// [parts] (year, month, day, hour, minute, second) as a UTC value with
/// those fields, or null when they name no real time. UTC has no DST
/// gaps, so the round-trip only rejects values that are out of range.
DateTime? _wallTime(List<int> parts) {
  final utc = DateTime.utc(
    parts[0],
    parts[1],
    parts[2],
    parts[3],
    parts[4],
    parts[5],
  );
  final fields = [
    utc.year,
    utc.month,
    utc.day,
    utc.hour,
    utc.minute,
    utc.second,
  ];
  for (var i = 0; i < parts.length; i++) {
    if (fields[i] != parts[i]) return null;
  }
  return utc;
}
