import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import 'decimal_rounding.dart';

/// A category as the export writes it. The caller resolves [name], because
/// seeded names are localized.
typedef CsvExportCategory = ({String name, CategoryType type});

/// Encodes [transactions] as a UTF-8 CSV with a BOM (so Excel reads CJK
/// names correctly) and CRLF line endings.
///
/// Columns: `id, date, type, amount, currency, category, account, memo,
/// created_at, updated_at`. `amount` is a plain decimal at the currency's
/// scale; `type` comes from the category; the three timestamps use
/// [formatLocalIso8601]. Category, account and memo text starting with
/// `= + - @`, a tab or a carriage return gets a leading `'` so spreadsheets
/// show it instead of running it. `amount_formula` is not exported. Every
/// `categoryId` and `accountId` must be in the maps (foreign keys make
/// that so). Pure, so it can run off the UI isolate.
Uint8List encodeTransactionsCsv(
  List<Transaction> transactions, {
  required Map<int, CsvExportCategory> categories,
  required Map<int, String> accountNames,
}) {
  final text = Csv(addBom: true).encode([
    const [
      'id',
      'date',
      'type',
      'amount',
      'currency',
      'category',
      'account',
      'memo',
      'created_at',
      'updated_at',
    ],
    for (final tx in transactions)
      [
        tx.id.toString(),
        formatLocalIso8601(tx.date),
        categories[tx.categoryId]!.type.name,
        minorUnitsToDecimalString(
          tx.amountMinorUnits,
          decimals: tx.currency.decimals,
        ),
        tx.currency.code,
        _escapeFormula(categories[tx.categoryId]!.name),
        _escapeFormula(accountNames[tx.accountId]!),
        _escapeFormula(tx.memo ?? ''),
        formatLocalIso8601(tx.createdAt),
        formatLocalIso8601(tx.updatedAt),
      ],
  ]);
  return utf8.encode(text);
}

final _formulaStart = RegExp('^[=+\\-@\t\r]');

/// Prefixes user text that a spreadsheet would run as a formula with `'`
/// (OWASP CSV injection guidance; PRD → Security & Privacy).
String _escapeFormula(String text) =>
    _formulaStart.hasMatch(text) ? "'$text" : text;

/// [value] in local time as `YYYY-MM-DDTHH:mm:ss±HH:MM`, e.g.
/// `2026-10-30T14:30:15+08:00`. Sub-second digits are dropped.
String formatLocalIso8601(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}'
      'T${two(d.hour)}:${two(d.minute)}:${two(d.second)}'
      '${formatUtcOffset(d.timeZoneOffset)}';
}

/// [offset] as `±HH:MM`; zero is `+00:00`.
String formatUtcOffset(Duration offset) {
  final minutes = offset.inMinutes.abs();
  final sign = offset.isNegative ? '-' : '+';
  final hh = (minutes ~/ 60).toString().padLeft(2, '0');
  final mm = (minutes % 60).toString().padLeft(2, '0');
  return '$sign$hh:$mm';
}
