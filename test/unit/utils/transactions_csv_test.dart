import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/transactions_csv.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';

const _hkd = Currency(code: 'HKD', decimals: 2);
const _jpy = Currency(code: 'JPY', decimals: 0);

Transaction _tx({
  int id = 1,
  int amount = 1234,
  Currency currency = _hkd,
  int categoryId = 1,
  int accountId = 1,
  String? memo,
  String? amountFormula,
}) => Transaction(
  id: id,
  amountMinorUnits: amount,
  currency: currency,
  categoryId: categoryId,
  accountId: accountId,
  memo: memo,
  amountFormula: amountFormula,
  date: DateTime(2026, 10, 30, 14, 30, 15),
  createdAt: DateTime(2026, 10, 30, 14, 31),
  updatedAt: DateTime(2026, 10, 31, 9, 0, 5),
);

const _categories = {
  1: (name: '食物', type: CategoryType.expense),
  2: (name: 'Salary', type: CategoryType.income),
};
const _accounts = {1: 'Cash', 2: 'Bank, HK'};

/// Checks and strips the BOM, decodes [bytes] and splits on CRLF.
List<String> _lines(List<int> bytes) {
  expect(bytes.take(3), [0xEF, 0xBB, 0xBF], reason: 'UTF-8 BOM for Excel');
  return utf8.decode(bytes.sublist(3)).split('\r\n');
}

void main() {
  group('formatUtcOffset', () {
    test('formats positive, negative, zero and half-hour offsets', () {
      expect(formatUtcOffset(const Duration(hours: 8)), '+08:00');
      expect(formatUtcOffset(Duration.zero), '+00:00');
      expect(
        formatUtcOffset(const Duration(hours: -3, minutes: -30)),
        '-03:30',
      );
      expect(formatUtcOffset(const Duration(hours: 5, minutes: 45)), '+05:45');
    });
  });

  group('formatLocalIso8601', () {
    // The offset depends on the test machine's zone, so it is built from
    // the value's own `timeZoneOffset`.
    test('local wall time to the second, then the offset', () {
      final d = DateTime(2026, 10, 30, 14, 30, 15, 999);
      expect(
        formatLocalIso8601(d),
        '2026-10-30T14:30:15${formatUtcOffset(d.timeZoneOffset)}',
      );
    });

    test('converts UTC values to local time first', () {
      final utc = DateTime.utc(2026, 1, 2, 3, 4, 5);
      expect(formatLocalIso8601(utc), formatLocalIso8601(utc.toLocal()));
    });

    test('pads every field', () {
      final d = DateTime(987, 1, 2, 3, 4, 5);
      expect(formatLocalIso8601(d), startsWith('0987-01-02T03:04:05'));
    });
  });

  group('encodeTransactionsCsv', () {
    test('header row only when there are no transactions', () {
      final lines = _lines(
        encodeTransactionsCsv(
          const [],
          categories: _categories,
          accountNames: _accounts,
        ),
      );
      expect(lines, [
        'id,date,type,amount,currency,category,account,memo,'
            'created_at,updated_at',
      ]);
    });

    test('one row per transaction with names, type and decimal amount', () {
      final tx = _tx(id: 7, memo: 'lunch', amountFormula: '10+2.34');
      final lines = _lines(
        encodeTransactionsCsv(
          [tx, _tx(id: 8, amount: 300000, currency: _jpy, categoryId: 2)],
          categories: _categories,
          accountNames: _accounts,
        ),
      );
      expect(lines, hasLength(3));
      expect(
        lines[1],
        '7,${formatLocalIso8601(tx.date)},expense,12.34,HKD,食物,Cash,lunch,'
        '${formatLocalIso8601(tx.createdAt)},'
        '${formatLocalIso8601(tx.updatedAt)}',
      );
      expect(lines[2].split(',').sublist(0, 8), [
        '8',
        formatLocalIso8601(tx.date),
        'income',
        '300000',
        'JPY',
        'Salary',
        'Cash',
        '',
      ]);
      expect(lines[1], isNot(contains('10+2.34')));
    });

    test('quotes fields with commas, quotes and line breaks', () {
      final text = utf8.decode(
        encodeTransactionsCsv(
          [_tx(accountId: 2, memo: 'say "hi"\nthen, leave')],
          categories: _categories,
          accountNames: _accounts,
        ),
      );
      expect(text, contains(',"Bank, HK","say ""hi""\nthen, leave",'));
    });

    test('escapes text that a spreadsheet would run as a formula', () {
      for (final memo in ['=1+1', '+1', '-1', '@SUM(A1)', '\tx', '\rx']) {
        final lines = _lines(
          encodeTransactionsCsv(
            [_tx(memo: memo)],
            categories: const {1: (name: '=cat', type: CategoryType.expense)},
            accountNames: const {1: '@acct'},
          ),
        );
        expect(
          lines[1],
          contains(",'=cat,'@acct,"),
          reason: 'category and account',
        );
        expect(lines[1], contains("'$memo"), reason: 'memo');
      }
    });

    test('leaves ordinary text and negative amounts alone', () {
      final lines = _lines(
        encodeTransactionsCsv(
          [_tx(amount: -1234, memo: 'a=b')],
          categories: _categories,
          accountNames: _accounts,
        ),
      );
      expect(lines[1], contains(',-12.34,HKD,食物,Cash,a=b,'));
    });
  });
}
